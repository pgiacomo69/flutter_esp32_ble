import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';



class BLESender with ChangeNotifier  {
  late FlutterReactiveBle _ble;
  late String _curMessage;
  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;



  BLESender(FlutterReactiveBle ble) {
    _ble = ble;
    _curMessage="Idle";
  }

  void messageNotify(String _msg)
  {
    _curMessage=_msg;
    notifyListeners();
  }

  bleSendOld(String serviceUUID, String characteristicUUID, String dataToSend) async  {

    messageNotify("Loading");
    if (_subscription!=null) {
      _subscription!.cancel();
    }
    _subscription = _ble.scanForDevices(
        withServices: [Uuid.parse(serviceUUID)]).listen((device) async {
        _subscription!.cancel();
        messageNotify("${device.name} found");
        if (_connection != null) {
          try {
            await _connection!.cancel();
          } on Exception catch (e, _) {
            print("Error disconnecting from a device: $e");
            messageNotify(e.toString());
          }
        }
        _connection = _ble
            .connectToDevice(
          id: device.id,
        )
            .listen((connectionState) async {
          // Handle connection state updates
          messageNotify("Connection State: ${connectionState.connectionState}");
          if (connectionState.connectionState ==
              DeviceConnectionState.connected) {
            final characteristic = QualifiedCharacteristic(
                serviceId: Uuid.parse(serviceUUID),
                characteristicId: Uuid.parse(characteristicUUID),
                deviceId: device.id);
            messageNotify("Send: $dataToSend");
            List<int> bytes = utf8.encode(dataToSend);
            await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
            messageNotify("Disconnect");
            disconnect();
            messageNotify("Disconnected");

            // print('disconnected');
          }
        }, onError: (dynamic error) {
          // Handle a possible error
          print('error connecting!');
          print(error.toString());
          messageNotify(error.toString());

        });

    }, onError: (error) {
      print('error scanning!');
      print(error.toString());
      messageNotify(error.toString());
      notifyListeners();

    });

  }

  bleSend(String serviceUUID, String characteristicUUID, String dataToSend) async  {

    messageNotify("Loading");
    if (_subscription!=null) {
      _subscription!.cancel();
    }
    _subscription = _ble.scanForDevices(
        withServices: [Uuid.parse(serviceUUID)]).listen((device) async {
      await _subscription!.cancel();
      messageNotify("${device.name} found");
     bleSendToDevice(device.id, serviceUUID, characteristicUUID, dataToSend);

    }, onError: (error) {
      print('error scanning!');
      print(error.toString());
      messageNotify(error.toString());
      notifyListeners();

    });

  }

  Future bleSendToDevice(String deviceId, String serviceUUID, String characteristicUUID, String dataToSend) async {
    {
           if (_connection != null) {
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
           )
               .listen((connectionState) async {
             // Handle connection state updates
             messageNotify("Connection State: ${connectionState.connectionState}");
             if (connectionState.connectionState ==
                 DeviceConnectionState.connected) {
               final characteristic = QualifiedCharacteristic(
                   serviceId: Uuid.parse(serviceUUID),
                   characteristicId: Uuid.parse(characteristicUUID),
                   deviceId: deviceId);
               messageNotify("Send: $dataToSend");
               List<int> bytes = utf8.encode(dataToSend);
               await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
               messageNotify("Disconnect");
               disconnect();
               messageNotify("Disconnected");

               // print('disconnected');
             }
           }, onError: (dynamic error) {
             // Handle a possible error
             print('error connecting!');
             print(error.toString());
             messageNotify(error.toString());

           });

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
  StreamSubscription? get bleSubscription => _subscription;
}