part of "ble_sender_bloc.dart";

abstract class BleEvent {
  String message;
  BleEvent(
      {required this.message}) {
    print('********BleSender Event $message *********');
  }
}

class BleEventInit extends BleEvent {
  BleEventInit():super(message: 'Init');
}

class BleEventIdle extends BleEvent {
  BleEventIdle():super(message: 'Idle');
}

class BleEventSend extends BleEvent {
  final String qrCode;
  final String dataToSend;
  BleEventSend ({required this.qrCode,required this.dataToSend}) :super(message: 'Send');
}

class BleEventSearchDevice extends BleEvent {

  BleEventSearchDevice():super(message: 'Search Device');
}

class BleEventConnectDevice extends BleEvent {

  BleEventConnectDevice():super(message: 'Connect Device');
}


class BleEventWaitAnswer extends BleEvent {

  BleEventWaitAnswer():super(message: 'Wait Answer');
}


class BleEventReceivedData extends BleEvent {
  final String dataReceived;
  BleEventReceivedData({required this.dataReceived}):super(message: 'Data Received:'+dataReceived);
}

class BleEventError extends BleEvent {
  BleState state;
  String error;

  BleEventError({required this.state,required this.error}):super(message: 'Error');

}