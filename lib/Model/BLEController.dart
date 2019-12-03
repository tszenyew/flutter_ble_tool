import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:encrypt/encrypt.dart';

class BleObj {
  //var
  static int scanDuration = 2;
  static bool _isScanning = false,
      isEnable = false,
      isAvailable = false,
      _isConnected = false,
      _isConnecting = false,
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
  var encryptor =
      Encrypter(AES(Key(_createUint8ListFromHexString(_encryptionKey))));
  var iv = IV(_createUint8ListFromHexString(_encryptionIV));
  static final String _encryptionKey =
      "15135A26471B59561B3B213D5B0C600215212141411F013B100637053D172403";
  static final String _encryptionIV = "da2b282b6331ae40cb927a51411c5b14";

  String _actUnlock = "Unlock Gate",
      actLock = "Lock Gate",
      actSiren = "Siren On",
      actSirenOff = "Siren Off";

  List<int> bLE2cmd = [-95, 21, 44, -27, -27, -58, -80, 92, -97];
  String _serviceUUID =
      "ad11cf40-063f-11e5-be3e-0002a5d5c51b"; //ble 5 service UUID
  String _characteristicUUID =
      "bf3fbd80-063f-11e5-9e69-0002a5d5c503"; //ble 5 service UUID
  String _notificationUUID =
      "bf3fbd80-063f-11e5-9e69-0002a5d5c501"; //ble 5 service UUID

  String unlockDoor = "[B5,01,00,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]";
  String lockDoor = "[B5,01,01,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]";
  String sirenOn = "[B5,02,01,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]";
  String sirenOff = "[B5,02,00,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]";
  String setDoorConfig = "[B5,03,01,03,20,03,20,03,20,00,00,00,00,00,00,00]";
  String clearSiren = "[B5,03,00,00,00,00,00,00,00,00,00,00,00,00,00,00]";
  String setSiren = "[B5,03,01,00,C8,04,B0,09,C4,00,00,00,00,00,00,00]";
  String clearSchedule = "[B5,04,00,01,01,15,20,15,30,00,00,00,00,00,00,00]";
  String setSchedule = "[B5,04,01,01,01,15,16,15,17,00,00,00,00,00,00,00]";
  String clearHoliday = "[B5,05,00,00,00,00,00,00,00,00,00,00,00,00,00,00]";
  String setHoliday = "[B5,05,01,01,19,08,31,00,00,00,00,00,00,00,00,00]";
  String clearWifiSSID = "[B5,06,00,00,00,00,00,00,00,00,00,00,00,00,00,00]";
  String setWifiSSID =
      "[B5,06,01,11,01,T,i,m,e,T,e,c,C,l,o,u,B5,06,01,11,02,d,-,A,s,u,s,00,00,00,00,00]";
  String clearWifiPassword =
      "[B5,07,00,00,00,00,00,00,00,00,00,00,00,00,00,00]";
  String setWifiPassword =
      "[B5,07,01,0C,01,e,p,i,c,a,m,e,r,a,@,9,B5,07,01,0C,02,9,00,00,00,00,00,00,00,00,00,00]";
  String clearDateTime = "[B5,08,00,00,00,00,00,00,00,00,00,00,00,00,00,00]";
  String setDateTime = "[B5,08,01,yy,MM,dd,DD,hh,mm,ss,00,08,00,00,00,00]";
  String enableFCU = "[B5,09,01,12,00,00,00,00,00,00,00,00,00,00,00,00]";
  String disableFCU = "[B5,09,00,00,00,00,00,00,00,00,00,00,00,00,00,00]";

//getter
  BluetoothDevice get selectedDevice {
    return bleDeviceSelected;
  }

  get isConnected {
    return _isConnected;
  }

  get isConnecting {
    return _isConnecting;
  }

  get isWritingChar {
    return _isWritingChar;
  }

  get isScanning {
    return _isScanning;
  }

  List<BluetoothDevice> getDeviceList() {
    return devices;
  }

  get actionsList {
    return [_actUnlock, actLock, actSiren, actSirenOff];
  }

  get actUnlock {
    return _actUnlock;
  }

//setter
  void setSelectedDevice(BluetoothDevice device) {
    bleDeviceSelected = device;
  }

//Constructor

  factory BleObj() {
    return _bleObj;
  }

  BleObj.internal() {
    isBLEAvailable();
    isBLEEnable();
  }

//start Scan
  Future startScan() {
    Completer completer = new Completer();
    if (!isAvailable) {
      isBLEAvailable().then((isAvai) {
        completer.complete(isAvai);
      });
      return completer.future;
    }
    if (!isEnable) {
      isBLEEnable().then((isOn) {
        completer.complete(isOn);
      });
      return completer.future;
    }
    if (!_isScanning) {
      _isScanning = true;
      flutterBlue.startScan(timeout: Duration(seconds: scanDuration));
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
    if (_isConnecting) {
      Fluttertoast.showToast(
          msg: "Please wait , Bluetooh is connecting to " +
              bleDeviceSelected.name);
      completer.complete();
    } else if (!_isConnected) {
      Fluttertoast.showToast(msg: "Connecting to " + device.name);
      bleDeviceSelected = device;
      _isConnecting = true;
      startListening();
      connectDevice().then((val) {
        Fluttertoast.showToast(msg: "Connected to " + device.name);
        completer.complete(true);
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

  Future sendAction(String action) {
    Completer c = new Completer();

    if (_isWritingChar) {
      Fluttertoast.showToast(msg: "Still sending Action ...");
    } else {
      Fluttertoast.showToast(msg: "Sending Action to Device...");
      _isWritingChar = true;
      writeCharacteristic(getCmd(action)).then((result) {
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
              _isConnecting = true;
              _isConnected = false;
            }
            break;
          case 2:
            {
              //connected
              _isConnecting = false;
              _isConnected = true;
            }
            break;
          case 3:
            {
              //d_isconnecting

            }
            break;
        }
      }
    });
  }

  void stopScan() {
    flutterBlue.stopScan();
  }

  bool disconnect() {
    if (_isConnected || _isConnecting) {
      bleDeviceSelected.disconnect();
      bleSub.cancel();
      Fluttertoast.showToast(
          msg: "Disconnected from " + bleDeviceSelected.name);
      _isConnected = false;
      _isConnecting = false;
      _isWritingChar = false;
      return true;
    }
    return false;
  }

  Future isBLEAvailable() {
    Completer c = new Completer();
    flutterBlue.isAvailable.then((val) {
      isAvailable = val;
      if (!val) {
        Fluttertoast.showToast(
            msg: "BLE unsupported on your device , too bad ^^ ");
      }
      c.complete(val);
    });
    return c.future;
  }

  Future isBLEEnable() {
    Completer c = new Completer();
    flutterBlue.isOn.then((val) {
      isEnable = val;
      if (!val) {
        Fluttertoast.showToast(
            msg: "BlueTooth is disabled , please enable Bluetooth ");
      }
      c.complete(val);
    });
    return c.future;
  }

  List<int> getCmd(String action) {
    String actionKey = "";
    print(action);
    switch (action) {
      case "BLE2":
        {
          return bLE2cmd;
        }
        break;
      case "Unlock Gate":
        {
          actionKey = unlockDoor;
        }
        break;
      case "Lock Gate":
        {
          actionKey = lockDoor;
        }
        break;
      case "Siren On":
        {
          actionKey = sirenOn;
        }
        break;
      case "Siren Off":
        {
          actionKey = sirenOff;
        }
    }
    actionKey = actionKey.substring(1, actionKey.length - 1);

    List<String> newCmd = [];
    List<String> key = actionKey.split(",").map((val) => val.trim()).toList();

    for (String i in key) {
      switch (i) {
        case "yy":
          {
            newCmd.add(getYear());
          }
          break;
        case "MM":
          {
            newCmd.add(getMonth());
          }
          break;
        case "dd":
          {
            newCmd.add(getDate());
          }
          break;
        case "hh":
          {
            newCmd.add(getHour());
          }
          break;
        case "mm":
          {
            newCmd.add(getMinute());
          }
          break;
        default:
          {
            print(i);
            newCmd.add(i);
          }
      }
    }
    Encrypted result = encryptor.encrypt(newCmd.toString(), iv: iv);
    print("Encryeted string is like this : " + result.bytes.toString());
    return result.bytes;
  }

  static Uint8List _createUint8ListFromHexString(String hex) {
    var result = new Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = hex.substring(i, i + 2);
      var byte = int.parse(num, radix: 16);
      result[i ~/ 2] = byte;
    }
    return result;
  }

  static String getYear() {
    String year = DateTime.now().year.toString();
    return year.substring(year.length - 2, year.length);
  }

  static String getMonth() {
    String month = "0" + DateTime.now().month.toString();
    return month.substring(month.length - 2, month.length);
  }

  static String getDate() {
    String date = "0" + DateTime.now().day.toString();
    return date.substring(date.length - 2, date.length);
  }

  static String getHour() {
    String hh = "0" + DateTime.now().hour.toString();
    return hh.substring(hh.length - 2, hh.length);
  }

  String getMinute() {
    String mm = "0" + DateTime.now().minute.toString();
    return mm.substring(mm.length - 2, mm.length);
  }
}
