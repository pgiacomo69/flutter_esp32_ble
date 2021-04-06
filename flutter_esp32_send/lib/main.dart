import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_esp32_send/ble_sender.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  FlutterReactiveBle ble = FlutterReactiveBle();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BLESender(ble)),
      ],
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
// ...
  String _serviceId="E5A1C9A8-AB93-11E8-98D0-529269FB1459";
  String _characteristicId="E5A1CDA4-AB93-11E8-98D0-529269FB1459";

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
