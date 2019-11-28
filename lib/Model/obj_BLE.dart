import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BleObj {
  //var
  static int scanDuration = 2;
  static bool _isScanning = false,
      isEnable = false,
      isAvailable = false,
      _isConnected = false,
      isConnecting = false,
      _isWritingChar = false;
  static FlutterBlue flutterBlue = FlutterBlue.instance;
  static StreamSubscription<List<ScanResult>> scanSub;
  static StreamSubscription<BluetoothDeviceState> bleSub;
  static List<BluetoothDevice> devices = [];
  static BluetoothDevice bleDeviceSelected;
  static List<BluetoothService> bleService;
  static BluetoothService selectedBleService;
  static List<BluetoothCharacteristic> bleCharacteristic;
  static BluetoothCharacteristic selectedbleChar;
  static int currentState = -1;
  static final BleObj _bleObj = new BleObj.internal();
  String _actUnlock = "Unlock Gate" , actLock = "Lock Gate" ,actSiren = "Siren On" , actSirenOff = "Siren Off";
  
  factory BleObj() {
    return _bleObj;
  }

  String _serviceUUID =
      "ad11cf40-063f-11e5-be3e-0002a5d5c51b"; //ble 5 service UUID
  String _characteristicUUID =
      "bf3fbd80-063f-11e5-9e69-0002a5d5c503"; //ble 5 service UUID
  String _notificationUUID =
      "bf3fbd80-063f-11e5-9e69-0002a5d5c501"; //ble 5 service UUID

//getter
  get selectedDevice {
    return bleDeviceSelected;
  }

  get isConnected {
    return _isConnected;
  }

  get isWritingChar {
    return _isWritingChar;
  }

  get isScanning{
    return _isScanning;
  }

  List<BluetoothDevice> getDeviceList() {
    return devices;
  }

  get actionsList{
    return [_actUnlock , actLock , actSiren , actSirenOff];
  }

  get actUnlock{
    return _actUnlock;
  }
//setter
  void setSelectedDevice(BluetoothDevice device) {
    bleDeviceSelected = device;
  }

//Constructor
  BleObj.internal() {
    isBLEAvailable();
    isBLEEnable();
  }

//start Scan
  Future<dynamic> startScan() {
    Completer completer = new Completer();

    if (!_isScanning) {
      flutterBlue.startScan(timeout: Duration(seconds: scanDuration));
      _isScanning = true;
      scanSub = flutterBlue.scanResults.listen((scanResult) {
        // do something with scan result
        devices = scanResult
            .where((item) => item.device.name.trim().isNotEmpty)
            .toSet()
            .toList()
            .map((item) {
          return item.device;
        }).toList();
      });
    }
    Timer(Duration(seconds: scanDuration), () {
      completer.complete(devices);
      scanSub.cancel();
      _isScanning = false;
    });
    return completer.future;
  }

//Connect to Device
  Future connectToDevice(BluetoothDevice device) {
    Completer completer = new Completer();
    if (isConnecting) {
      Fluttertoast.showToast(
          msg: "Please wait , Bluetooh is connecting to " +
              bleDeviceSelected.name);
      completer.complete();
    } else if (!_isConnected) {
      Fluttertoast.showToast(msg: "Connecting to " + device.name);
      bleDeviceSelected = device;
      startListening();
      connectDevice().then((val) {
        Fluttertoast.showToast(msg: "Connected to " + device.name);
        completer.complete(val);
        getDeviceService();
      });
    } else if (device.name == bleDeviceSelected.name && _isConnected) {
      Fluttertoast.showToast(
          msg: "Already connected to " + bleDeviceSelected.name);
      completer.complete();
    } else {
      disconnect();
      connectToDevice(device).then((val) {
        completer.complete(val);
      });
    }
    return completer.future;
  }

  Future connectDevice() async {
    return selectedDevice.connect();
  }

  void getDeviceService() {
    if (bleDeviceSelected != null && _isConnected) {
      getBleService().then((services) {
        selectedBleService =
            services.firstWhere((s) => (s.uuid.toString() == _serviceUUID));
        if (selectedBleService != null) {
          selectedbleChar = selectedBleService.characteristics
              .firstWhere((c) => (c.uuid.toString() == _characteristicUUID));
        }
      });
    } else {
      Fluttertoast.showToast(msg: "Device is not connected");
    }
  }

  Future sendAction() {
    Completer c = new Completer();

    if (_isWritingChar) {
      Fluttertoast.showToast(msg: "Still sending Action ...");
    } else {
      Fluttertoast.showToast(msg: "Sending Action to Device...");
      _isWritingChar = true;
      writeCharacteristic(getCmd()).then((result) {
        _isWritingChar = false;
        c.complete(result);
        Fluttertoast.showToast(msg: "Done Sending Action");
      });
    }

    return c.future;
  }

  Future writeCharacteristic(List<int> cmd) {
    Completer c = new Completer();
    selectedbleChar.write(cmd).then((sucess) {
      c.complete(sucess);
    });
    return c.future;
  }

  Future getBleService() async {
    var comp = new Completer();
    bleDeviceSelected.discoverServices().then((services) {
      bleService = services;
      comp.complete(bleService);
    });
    return comp.future;
  }



  void startListening() {
    bleSub = bleDeviceSelected.state.listen((onData) {
      if (onData.index != currentState) {
        currentState = onData.index;
        switch (onData.index) {
          case 0:
            {
              //disconnected
              if (isConnected) {
                disconnect();
              }
            }
            break;
          case 1:
            {
              //connecting
              isConnecting = true;
              _isConnected = false;
            }
            break;
          case 2:
            {
              //connected
              isConnecting = false;
              _isConnected = true;
            }
            break;
          case 3:
            {
              //disconnecting

            }
            break;
        }
      }
    });
  }

  void stopScan() {
    flutterBlue.stopScan();
  }

  void disconnect() {
    if (_isConnected) {
      bleDeviceSelected.disconnect();
      bleSub.cancel();
      Fluttertoast.showToast(
          msg: "Disconnected from " + bleDeviceSelected.name);
      _isConnected = false;
      isConnecting = false;
      _isWritingChar = false;
    }
  }

  void isBLEAvailable() async {
    flutterBlue.isAvailable.then((val) {
      isAvailable = val;
      if (!val){
        Fluttertoast.showToast(msg: "BLE unsupported on your device , too bad ^^ " );
      }
    });
  }

  void isBLEEnable() async {
    flutterBlue.isOn.then((val) {
      isEnable = val;
      if(!val){
        Fluttertoast.showToast(msg: "BlueTooth is disabled , please enable Bluetooth ");
      }
    });
  }

  List<int> getCmd() {
    List<int> cmd = [-95, 21, 44, -27, -27, -58, -80, 92, -97];
    return cmd;
  }
}
