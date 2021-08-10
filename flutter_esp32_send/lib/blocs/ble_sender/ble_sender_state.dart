part of "ble_sender_bloc.dart";

abstract class BleState {
  String message;
  BleState(
  {required this.message}) {
    print('********BleSender State $message *********');
  }

}

class BleStateInit extends BleState {
  BleStateInit(): super (message:'Init');

}

class BleStateIdle extends BleState {
  BleStateIdle(): super (message:'Idle');
}

class BleStateSend extends BleState {
  BleStateSend(): super (message:'Send');
}


class BleStateSearchDevice extends BleState {
  BleStateSearchDevice(): super (message:'Search Device');
}

class BleStateReceivedData extends BleState {
  String dataReceived;
  BleStateReceivedData({required this.dataReceived}): super (message:'Received Data:'+dataReceived);
}

class BleStateWaitAnswer extends BleState {
  BleStateWaitAnswer(): super (message:'Wait Answer');
}

class BleStateConnectDevice extends BleState {
  BleStateConnectDevice(): super(message:'Connect Device');
}
class BleStateError extends BleState {
  String errorState;
  String error;
  BleStateError({required this.error,required this.errorState}): super(message:'Error');
}





