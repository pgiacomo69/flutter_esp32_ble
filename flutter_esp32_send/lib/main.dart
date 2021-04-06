import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
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

class _MyHomePageState extends State<MyHomePage> {



// ...

  ColorCommand? _character = ColorCommand.cmdBlue;

  final FlutterReactiveBle _ble = FlutterReactiveBle();
   StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  int temperature=0;
  String temperatureStr = "Hello";

  void _disconnect() async {
    _subscription?.cancel();
    if (_connection != null) {
      await _connection!.cancel();
      _connection=null;
    }
  }

  void _connectBLE() {
    setState(() {
      temperatureStr = 'Loading';
    });
    _disconnect();
    _subscription = _ble.scanForDevices(
        withServices:[], // [Uuid.parse("181A")], // [Uuid.parse("e5a1c9a8-ab93-11e8-98d0-529269fb1459")],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true).listen((device) {
      if (device.name == 'M5Stack-Color') {
        print('************* ${device.name} Found! ***************');

        _connection = _ble
            .connectToDevice(
          id: device.id,
        )
            .listen((connectionState) async {
          // Handle connection state updates
          print('************* CONNECTION STATE ***************');
          print(connectionState.connectionState);
          if (connectionState.connectionState ==
              DeviceConnectionState.connected) {
            final characteristic = QualifiedCharacteristic(
                serviceId:   Uuid.parse("e5a1c9a8-ab93-11e8-98d0-529269fb1459"),
                characteristicId: Uuid.parse("e5a1cda4-ab93-11e8-98d0-529269fb1459"),
                deviceId: device.id);
            List<int> bytes = _character==ColorCommand.cmdBlue ?  utf8.encode("BLUE") : utf8.encode("YELLOW") ;
            await   _ble.writeCharacteristicWithoutResponse(characteristic, value: bytes);
            /* final response = await _ble.readCharacteristic(characteristic);
            print(response);
            setState(() {
              temperature = response[0];
              temperatureStr = temperature.toString() + '°';
            }); */
            _disconnect();
            print('disconnected');
            _subscription!.cancel();
          }
        }, onError: (dynamic error) {
          // Handle a possible error
          print(error.toString());
        });

      }
    }, onError: (error) {
      print('error!');
      print(error.toString());
    });
  }

  void _connettiBLE() {
    setState(() {
      temperatureStr = 'Cercando..';
    });
    _ble.logLevel=LogLevel.verbose;
    _subscription = _ble.scanForDevices(
        withServices: [], // [Uuid.parse("E5A1C9A8-AB93-11E8-98D0-529269FB1459")],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true).listen((device) {

      if (device.name == 'M5Stack-Color') {
        _subscription!.cancel();
        if (_connection == null) {
        print('************* ${device.name} Found! ***************');
          _connection = _ble.connectToDevice(id: device.id,).listen((
              connectionState) async {
            // Handle connection state updates
            print('************* CONNECTION STATE ${connectionState.connectionState} ***************');
            if (connectionState.connectionState==DeviceConnectionState.connected) {

              print('************* SCRIVO ***************');

              final characteristic = QualifiedCharacteristic(
                  serviceId:   Uuid.parse("E5A1C9A8-AB93-11E8-98D0-529269FB1459"),
                  characteristicId: Uuid.parse("E5A1CDA4-AB93-11E8-98D0-529269FB1459"),
                  deviceId: device.id,

              );
              List<int> bytes = _character==ColorCommand.cmdBlue ?  utf8.encode("BLUE") : utf8.encode("YELLOW") ;
              await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);

              print('************* DISCONNETTO ***************');
              _disconnect();
              print('************* DISCONNESSO ***************');


            }
          });

        }
      }
    });
  }




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
          child: Column(
          children: <Widget>[
            Text(
              temperatureStr,
              style: GoogleFonts.anton(
                  textStyle: Theme.of(context)
                      .textTheme
                      .headline1!
                      .copyWith(color: Colors.white)),
            ),
            ListTile(
              title: const Text('Blue'),
              leading: Radio(
                value: ColorCommand.cmdBlue,
                groupValue: _character,
                onChanged: (ColorCommand? value) {
                  setState(() { _character = value; });
                },
              ),
            ),
            ListTile(
              title: const Text('Thomas Jefferson'),
              leading: Radio(
                value: ColorCommand.cmdYellow,
                groupValue: _character,
                onChanged: (ColorCommand? value) {
                  setState(() { _character = value; });
                },
              ),
            ),
          ],
        ),
       ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _connettiBLE,
        tooltip: 'Increment',
        backgroundColor: Color(0xFF74A4BC),
        child: Icon(Icons.loop),
      ), // This trailing comma makes auto-formatting nicer for build methods.// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
