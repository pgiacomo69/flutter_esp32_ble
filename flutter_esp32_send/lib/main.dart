import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_esp32_send/ble_sender.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/ble_sender/ble_sender_bloc.dart';
bool _useBloc=true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late  FlutterReactiveBle ble;
  if (!_useBloc) {
     ble = FlutterReactiveBle();
     ble.logLevel = LogLevel.none;
  }

  runApp(
    !_useBloc ? MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BLESender(ble)),
      ], child: MyApp(),)
        :
      MultiBlocProvider(providers: 
      [BlocProvider<BleSenderBloc>(
        lazy: false,
        create: (context) {
          return BleSenderBloc()
          ..add(BleEventInit());
        },
      ),],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Arduino Temperature'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum ColorCommand { cmdRed, cmdBlue, cmdYellow }

extension ParseToString on ColorCommand {
  String toShortString() {
    switch (this) {
      case ColorCommand.cmdRed:
        return "RED";
      case ColorCommand.cmdBlue:
        return "BLUE";
      case ColorCommand.cmdYellow:
        return "YELLOW";
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  else
                    Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      !_useBloc ?
                       Consumer<BLESender>(builder: (context, bleSender, child) {
                        return Text(
                          bleSender.message,
                          style: GoogleFonts.anton(
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .headline4!
                                  .copyWith(color: Colors.black)),
                        );
                      })
                          :
                      BlocBuilder<BleSenderBloc, BleState>(
                      builder: (context, state) {
                        return Text(
                          state.message,
                          style: GoogleFonts.anton(
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .headline4!
                                  .copyWith(color: Colors.black)),
                        );
    }),
                        Container(
                        margin: EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                          },
                          child: Text('pause', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                          },
                          child: Text('resume', style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
          setState(() {
          result = scanData;
          });
          controller.pauseCamera();
          if (!_useBloc)
            {
           var bleSender=Provider.of<BLESender>(context, listen: false);
          if (!bleSender.isBusy) {
            bleSender.bleSendQr(scanData.code);
          } }
          else {

            var bleSenderBloc = BlocProvider.of<BleSenderBloc>(context);
            if (bleSenderBloc.state is BleStateIdle) {
              bleSenderBloc.add(
                  BleEventSend(
                      qrCode: scanData.code, dataToSend: 'Ciao, belli'));
            }
          }

    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

/* class _MyHomePageState extends State<MyHomePage> {
// ...
//   String _serviceId="E5A1C9A8-AB93-11E8-98D0-529269FB1459";
//   String _characteristicId="E5A1CDA4-AB93-11E8-98D0-529269FB1459";
  String _serviceId="f830075f-cc1e-4bbf-98d0-529269fb1459";
  String _characteristicId="843e9a63-f917-4978-98d0-529269fb1459";



  ColorCommand _selectedColor = ColorCommand.cmdBlue;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xffffdf6f), Color(0xffeb2d95)])),
        child: Center(
          child: Consumer<BLESender>(builder: (context, bleSender, child) {
            return Column(
              children: <Widget>[
                Text(
                  bleSender.message,
                  style: GoogleFonts.anton(
                      textStyle: Theme.of(context)
                          .textTheme
                          .headline4!
                          .copyWith(color: Colors.white)),
                ),
                ListTile(
                  title: const Text('Blue'),
                  leading: Radio(
                    value: ColorCommand.cmdBlue,
                    groupValue: _selectedColor,
                    onChanged: (ColorCommand? value) {
                      setState(() {
                        _selectedColor = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Yellow'),
                  leading: Radio(
                    value: ColorCommand.cmdYellow,
                    groupValue: _selectedColor,
                    onChanged: (ColorCommand? value) {
                      setState(() {
                        _selectedColor = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Red'),
                  leading: Radio(
                    value: ColorCommand.cmdRed,
                    groupValue: _selectedColor,
                    onChanged: (ColorCommand? value) {
                      setState(() {
                        _selectedColor = value!;
                      });
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),

      floatingActionButton: Consumer<BLESender>(builder: (context, bleSender, child) {
    return FloatingActionButton(
        onPressed: () async {
          // await bleSender.bleSendToDevice("F0:08:D1:C7:3B:4E",_serviceId, _characteristicId, _selectedColor.toShortString());
          await bleSender.bleSend(_serviceId, _characteristicId, _selectedColor.toShortString());
        },
        tooltip: 'Send',
        backgroundColor: Color(0xFF74A4BC),
        child: Icon(Icons.send),
      );
    } // This trailing comma makes auto-formatting nicer for build methods.// This trailing comma makes auto-formatting nicer for build methods.
    ),
    );
  }
}
*/
