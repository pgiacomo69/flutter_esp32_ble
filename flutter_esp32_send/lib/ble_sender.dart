import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/foundation.dart';

enum BLESenderStatuses {
  BLEStatusIdle,
  BLEStatus
}
class BLESender with ChangeNotifier  {
  late FlutterReactiveBle _ble;
  late String _curMessage;
  bool _isBusy=false;
  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  Stopwatch stopwatch = new Stopwatch();
  final  String servicePrefix="0312";
  final  String characteristicPrefix="1969";


  BLESender(FlutterReactiveBle ble) {
    _ble = ble;
    _curMessage="Idle";
  }

  void messageNotify(String _msg,{ bool? busy })
  {
    _curMessage=_msg;
    if (busy!=null)
      {
        if (isBusy!=busy) {
          print('****************************');
          print('****************************');
          print('******* BUSY: $busy ********');
          print('****************************');
          print('****************************');
          _isBusy = busy;
        }
      }

    notifyListeners();
  }
  bleSendQr(String qrCode) async {
    messageNotify("Avvio",busy:true);
    // 'f008d1c7-3b4e-98d0-529269fb1459';
    var mac="${qrCode.substring(0,8)}${qrCode.substring(9,13)}";
    mac = StringUtils.addCharAtPosition(mac, ":", 2, repeat: true);
    mac=mac.toUpperCase();
    var serviceUUID= "${qrCode.substring(0,14)}${servicePrefix}-${qrCode.substring(14)}";
    var characteristicUUID= "${qrCode.substring(0,14)}${characteristicPrefix}-${qrCode.substring(14)}";
    await bleSend(mac, serviceUUID, characteristicUUID, "Test Invio");
  }

  bleSend(String deviceId,String serviceUUID, String characteristicUUID, String dataToSend) async  {
    stopwatch.reset();
    stopwatch.start();
    if (Platform.isIOS) {
       deviceId = '';
    }
     if (deviceId=='') {
       messageNotify("Loading");
       if (_subscription != null) {
         _subscription!.cancel();
       }
       _subscription = _ble.scanForDevices(
           withServices: [Uuid.parse(serviceUUID)]
       )
           .listen((device) async {
         await _subscription!.cancel();
         messageNotify("${device.name} found");
         bleSendToDevice(
             device.id, serviceUUID, characteristicUUID, dataToSend);
       }, onError: (error) {
         print('error scanning!');
         print(error.toString());
         messageNotify(error.toString(),busy:false);

       });
     }
     else {
       messageNotify("Sending");
       bleSendToDevice(deviceId, serviceUUID, characteristicUUID, dataToSend);
       messageNotify("Sent");
     }
  }

  Future bleSendToDevice(String deviceId, String serviceUUID, String characteristicUUID, String dataToSend) async {
    {

      /*  if (_connection != null) {
             try {
               await _connection!.cancel();
             } on Exception catch (e, _) {
               print("Error disconnecting from a device: $e");
               messageNotify(e.toString());
             }
           }
           _connection = _ble
               .connectToDevice(
             id: deviceId,
             connectionTimeout: const Duration(seconds:  5),
           )
               .listen((connectionState) async {
             // Handle connection state updates
             if (connectionState.connectionState ==
                 DeviceConnectionState.connected) {
               print("Connected");
               messageNotify("Connected"); */
               final characteristic = QualifiedCharacteristic(
                   serviceId: Uuid.parse(serviceUUID),
                   characteristicId: Uuid.parse(characteristicUUID),
                   deviceId: deviceId);
               messageNotify("Send: $dataToSend");
               print("Send: $dataToSend");
               List<int> bytes = utf8.encode(dataToSend);
               _ble.subscribeToCharacteristic(characteristic).listen((data) {
                 print("Received "+utf8.decode(data));
                 print('Transaction executed in ${stopwatch.elapsed}');
                 disconnect();
                 messageNotify("Received "+utf8.decode(data),busy:false);
               }, onError: (dynamic error) {
                 print("Error on Listen");
                 disconnect();
                 messageNotify("Error on Listen",busy:false);
               });
               print ("writeCharacteristicWithResponse");
               await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
               print('** Wrote **');

               // print('disconnected');
           /*  }
             else
               {
                 print("Not Connected");
                 messageNotify("Not Connected");
               }
           }, onError: (dynamic error) {
             // Handle a possible error
             print('error connecting!');
             print(error.toString());
             messageNotify(error.toString(),busy:false);

           }); */

       }
  }



  void disconnect() async {
    if (_subscription != null) {
     await _subscription!.cancel();
    }
    if (_connection != null) {
      await _connection!.cancel();
    }
  }

  String get message => _curMessage;
  bool get isBusy => _isBusy;
  StreamSubscription? get bleSubscription => _subscription;

  @override
  void dispose() {
    if (_subscription!=null){
      _subscription!.cancel();
    }

    super.dispose();
  }
}