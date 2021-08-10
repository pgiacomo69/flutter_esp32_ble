import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


part 'ble_sender_event.dart';
part 'ble_sender_state.dart';


class BleSenderBloc extends Bloc<BleEvent, BleState> {
  late final FlutterReactiveBle _ble;
  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  final Stopwatch _stopWatch = new Stopwatch();
  final String _servicePrefix="0312";
  final String _characteristicPrefix="1969";
  QualifiedCharacteristic? _characteristic;
  Stream<List<int>>? _receivedDataStream;

  String _serviceUUID="";
  String _deviceId="";
  String _characteristicUUID='';
  String _dataToSend='';

  bool skipConnection=false;

  BleSenderBloc(/* FlutterReactiveBle ble*/) : super(BleStateInit())  {
    _ble = FlutterReactiveBle();
    _ble.logLevel = LogLevel.none;
  }

  @override
  void add(BleEvent event) {
    super.add(event);
  }

  @override
  Stream<BleState> mapEventToState(BleEvent event,) async* {
     print('***** State:'+state.message+' - Event To Map:'+event.message);
    if (event is BleEventInit) {
      yield* _bleMapStateInit(event);
    }
    if (event is BleEventIdle) {
      yield* _bleMapStateIdle(event);
    }
    if (event is BleEventError) {
      yield* _bleMapStateError(event);
    }
    if (event is BleEventSend) {
      yield* _bleMapStateSend(event);
    }
    if (event is BleEventSearchDevice) {
      yield* _bleMapStateSearchDevice(event);
    }
    if (event is BleEventConnectDevice) {
      yield* _bleMapStateConnectDevice(event);
    }
    if (event is BleEventWaitAnswer) {
      yield* _bleMapStateWaitAnswer(event);
    }
    if (event is BleEventReceivedData) {
      yield* _bleMapStateReceivedData(event);
    }

  }



  Stream<BleState> _bleMapStateInit(BleEventInit event) async* {
    yield BleStateInit();
    _ble.statusStream.listen((status) async {
      print('******* FlutterBLE Status:'+status.toString()+' ********');
      if (status==BleStatus.ready)
        {
          add(BleEventIdle());
        }
    });
  }
  Stream<BleState> _bleMapStateIdle(BleEventIdle event) async* {
    if (state is BleStateInit) {
      yield BleStateIdle();
    }
  }

  Stream<BleState> _bleMapStateError(BleEventError event) async* {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription=null;
    }
    yield BleStateError(error: event.error,errorState: event.state.message);
    yield BleStateIdle();
  }



  String _qrCodeCheck(String qr){
    // f830075f-cc1e-98d0-529269fb1459
    String msg='Invalid QR Code';
    if (qr.length!=31)
      return msg;
    if (qr[8]!='-' || qr[13]!='-' || qr[18]!='-')
      return msg;
    qr=StringUtils.removeCharAtPosition(qr, 18);
    qr=StringUtils.removeCharAtPosition(qr, 13);
    qr=StringUtils.removeCharAtPosition(qr, 8);
    qr=qr.toLowerCase();
    int i=0;
    do {
      i++;
    } while (i<qr.length);
    return '';
  }



  Stream<BleState> _bleMapStateSend(BleEventSend event) async* {
    if (state is BleStateIdle) {
      String err=_qrCodeCheck(event.qrCode);
      if (err=='') {
      var macAddress="${event.qrCode.substring(0,8)}${event.qrCode.substring(9,13)}";

        macAddress =
            StringUtils.addCharAtPosition(macAddress, ":", 2, repeat: true);
        macAddress = macAddress.toUpperCase();
        _serviceUUID = "${event.qrCode.substring(0, 14)}${_servicePrefix}-${event.qrCode
            .substring(14)}";
        _characteristicUUID = "${event.qrCode.substring(
            0, 14)}${_characteristicPrefix}-${event.qrCode.substring(14)}";
        _dataToSend=event.dataToSend;
        yield BleStateSend();
        _stopWatch.start();
        _stopWatch.reset();
        if (Platform.isIOS) {
          add(BleEventSearchDevice());
        }
      if (Platform.isAndroid) {
        _deviceId=macAddress;
        add(BleEventConnectDevice());
      }
      }
      else add(BleEventError(state: state, error: err));
    }

  }

  Stream<BleState> _bleMapStateSearchDevice(BleEventSearchDevice event) async* {
    if (state is BleStateSend)
      {
        yield (BleStateSearchDevice());
         if (_subscription != null) {
           _subscription!.cancel();
         }
         _subscription = _ble.scanForDevices(
             withServices: [Uuid.parse(_serviceUUID)]
          )
           .listen((device) async {
            await _subscription!.cancel();
            _deviceId=device.id;
            add(BleEventConnectDevice());
          }, onError:((error) async {
            add(BleEventError(state: state, error: 'Errore Connessione:'+error.toString()));
           }));
        }
  }

  Stream<BleState> _bleMapStateConnectDevice(BleEventConnectDevice event) async* {
    if (state is BleStateSearchDevice || state is BleStateSend)
    if (skipConnection)
    {
      yield (BleStateConnectDevice());
    //  add(BleEventSendData());
    }
    else
    {
      if (_connection != null) {
        try {
          await _connection!.cancel();
        } on Exception catch (e, _) {
          print("Error disconnecting from a device: $e");
        }
      }
      _connection =  _ble
          .connectToDevice(
        id: _deviceId,
        // prescanDuration: const Duration(seconds: 5),
        // withServices: [Uuid.parse(_serviceUUID)],
        // connectionTimeout: const Duration(seconds: 5),
      ).listen((csUpdate)  async {
        // Handle connection state updates
        switch (csUpdate.connectionState){
          case DeviceConnectionState.connecting:
            print("*****Connecting******");
            break;
          case DeviceConnectionState.connected:
            print("*****Connected******");
            _characteristic = QualifiedCharacteristic(
                serviceId: Uuid.parse(_serviceUUID),
                characteristicId: Uuid.parse(_characteristicUUID),
                deviceId: _deviceId);
            _receivedDataStream = _ble.subscribeToCharacteristic(_characteristic!);
            _receivedDataStream!.listen((data) {
              add(BleEventReceivedData(dataReceived: utf8.decode(data)));
              _connection!.cancel();
              _disconnect();
            }, onError: (dynamic error) {
              print("Error:$error");
            });
            List<int> bytes = utf8.encode(_dataToSend);
            _ble.writeCharacteristicWithResponse(_characteristic!, value: bytes);
            add(BleEventWaitAnswer());
            break;
            // await _sendData();
            // _connection!.cancel();
            break;
          case DeviceConnectionState.disconnecting:
            print("*****Disconnecting******");
            break;
          case DeviceConnectionState.disconnected:
            print("*****Disconnected******");
            break;
        }
      }, onError: (dynamic error) {
        print("Error on Listen");
        add(BleEventError(state: state, error: error.toString()));
        _connection!.cancel();
      });
      yield (BleStateConnectDevice());
    }
  }






  Stream<BleState> _bleMapStateWaitAnswer(BleEventWaitAnswer event) async* {
    if (state is BleStateConnectDevice)
    {
      yield(BleStateWaitAnswer());
    }
  }



  Stream<BleState> _bleMapStateReceivedData(BleEventReceivedData event) async* {
    if (state is BleStateWaitAnswer)
      {
        yield(BleStateReceivedData(dataReceived:event.dataReceived));
        add(BleEventInit());
      }
  }



    void _disconnect() async {
        if (_subscription != null) {
          await _subscription!.cancel();
        }
        if (_connection != null) {
          await _connection!.cancel();
        }
        _dataToSend='';
      }


}
