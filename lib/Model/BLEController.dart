import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

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
  static BluetoothDevice _selectedDevice;
  static List<BluetoothService> bleService;
  static BluetoothService selectedBleService;
  static List<BluetoothCharacteristic> bleCharacteristic;
  static BluetoothCharacteristic selectedbleChar;
  static BluetoothCharacteristic notificationChar;
  static int currentState = -1;
  static final BleObj _bleObj = new BleObj.internal();
  //var encryptor = Encrypter(AES(Key.fromBase16(_encryptionKey), mode: AESMode.cbc));
  //var iv = IV.fromBase16(_encryptionIV);
  static final String _encryptionKey =
      "15135A26471B59561B3B213D5B0C600215212141411F013B100637053D172403";
  static final String _encryptionIV = "da2b282b6331ae40cb927a51411c5b14";

  static const String _actBle2 = "BLE2",
      _actUnlock = "Unlock Gate",
      _actLock = "Lock Gate",
      _actSiren = "Siren On",
      _actSirenOff = "Siren Off",
      _actSetDoorConfig = "Set Door Config",
      _actClearSiren = "Clear Siren",
      _actSetSiren = "Set Siren",
      // _actclearSchedule = "Clear Schedule",
      // _actsetSchedule = "Set Schedule",
      // _actclearHoliday = "Clear Holiday",
      // _actsetHoliday = "Set Holiday",
      // _actclearWifiSSID = "Clear WifiSSID",
      // _actsetWifiSSID = "Set WifiSSID",
      // _actclearWifiPassword = "Clear WifiPassword",
      // _actsetWifiPassword = "Set WifiPassword",
      _actclearDateTime = "Clear DateTime",
      _actsetDateTime = "Set DateTime" //,
      // _actenableFCU = "Enable FCU",
      // _actdisableFCU = "Disable FCU"
      ;

  static const Map<String, String> _actionKeyItems = {
    _actUnlock: "[B5,01,00,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]",
    _actLock: "[B5,01,01,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]",
    _actSiren: "[B5,02,01,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]",
    _actSirenOff: "[B5,02,00,yy,MM,dd,hh,mm,00,00,00,00,00,00,00,00]",
    _actSetDoorConfig: "[B5,03,01,03,20,03,20,03,20,00,00,00,00,00,00,00]",
    _actClearSiren: "[B5,03,00,00,00,00,00,00,00,00,00,00,00,00,00,00]",
    _actSetSiren: "[B5,03,01,00,C8,04,B0,09,C4,00,00,00,00,00,00,00]",
    // _actclearSchedule :"[B5,04,00,01,01,15,20,15,30,00,00,00,00,00,00,00]";
    // _actsetSchedule :"[B5,04,01,01,01,15,16,15,17,00,00,00,00,00,00,00]",
    // _actclearHoliday :"[B5,05,00,00,00,00,00,00,00,00,00,00,00,00,00,00]",
    // _actsetHoliday :"[B5,05,01,01,19,08,31,00,00,00,00,00,00,00,00,00]",
    // _actclearWifiSSID :"[B5,06,00,00,00,00,00,00,00,00,00,00,00,00,00,00]",
    // _actsetWifiSSID :"[B5,06,01,11,01,T,i,m,e,T,e,c,C,l,o,u,B5,06,01,11,02,d,-,A,s,u,s,00,00,00,00,00]",
    // _actclearWifiPassword :"[B5,07,00,00,00,00,00,00,00,00,00,00,00,00,00,00]",
    // _actsetWifiPassword :"[B5,07,01,0C,01,e,p,i,c,a,m,e,r,a,@,9,B5,07,01,0C,02,9,00,00,00,00,00,00,00,00,00,00]",
    _actclearDateTime: "[B5,08,00,00,00,00,00,00,00,00,00,00,00,00,00,00]",
    _actsetDateTime: "[B5,08,01,yy,MM,dd,DD,hh,mm,ss,00,08,00,00,00,00]",
    // _actenableFCU : "[B5,09,01,12,00,00,00,00,00,00,00,00,00,00,00,00]",
    // _actdisableFCU :"[B5,09,00,00,00,00,00,00,00,00,00,00,00,00,00,00]"
  };

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
  get actionsList {
    return [
      _actUnlock,
      _actLock,
      _actSiren,
      _actSirenOff,
      _actSetDoorConfig,
      _actClearSiren,
      _actSetSiren,
      // _actclearSchedule ,
      // _actsetSchedule ,
      // _actclearHoliday ,
      // _actsetHoliday ,
      // _actclearWifiSSID ,
      // _actsetWifiSSID ,
      // _actclearWifiPassword ,
      // _actsetWifiPassword ,
      _actclearDateTime,
      _actsetDateTime,
      // _actenableFCU ,
      // _actdisableFCU
    ];
  }

  BluetoothDevice get selectedDevice {
    return _selectedDevice;
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

  get actUnlock {
    return _actUnlock;
  }

//setter
  void setSelectedDevice(BluetoothDevice device) {
    _selectedDevice = device;
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
  Future startScan() async {
    Completer completer = new Completer();
    if (await isBLEAvailable() == false) {
      completer.complete(isAvailable);
      return completer.future;
    }
    if (await isBLEEnable() == false) {
      completer.complete(isEnable);
      return completer.future;
    }
    if (!_isScanning) {
      _isScanning = true;
      flutterBlue.startScan(timeout: Duration(seconds: scanDuration));
      scanSub = flutterBlue.scanResults.listen((scanResult) {
        // do something with scan result
        devices = scanResult
            .where((item) => item.device.name.trim().isNotEmpty)
            .map((item) {
              return item.device;
            })
            .toSet()
            .toList();
      });
    }
    Timer(Duration(seconds: scanDuration), () {
      completer.complete(true);
      scanSub.cancel();
      _isScanning = false;
    });
    return await completer.future;
  }

//Connect to Device
  Future connectToDevice(BluetoothDevice device) {
    Completer completer = new Completer();
    if (_isConnecting) {
      Fluttertoast.showToast(
          msg: "Please wait , Bluetooh is connecting to " +
              _selectedDevice.name);
      completer.complete();
    } else if (!_isConnected) {
      Fluttertoast.showToast(msg: "Connecting to " + device.name);
      _selectedDevice = device;
      _isConnecting = true;
      startListeningState();
      connectDevice().then((val) {
        Fluttertoast.showToast(msg: "Connected to " + device.name);
        getDeviceService().then((sucess) {
          completer.complete(sucess);
        });
      });
    } else if (device.name == _selectedDevice.name && _isConnected) {
      Fluttertoast.showToast(
          msg: "Already connected to " + _selectedDevice.name);
      completer.complete();
    } else {
      disconnect();
      connectToDevice(device).then((val) {
        completer.complete(val);
      });
    }
    return completer.future;
  }

  Future connectDevice() {
    return selectedDevice.connect();
  }

  Future getDeviceService() {
    Completer c = new Completer();
    if (_selectedDevice != null && _isConnected) {
      getBleService().then((services) {
        selectedBleService =
            services.firstWhere((s) => (s.uuid.toString() == _serviceUUID));
        if (selectedBleService != null) {
          selectedbleChar = selectedBleService.characteristics
              .firstWhere((c) => (c.uuid.toString() == _characteristicUUID));
          notificationChar = selectedBleService.characteristics
              .firstWhere((n) => (n.uuid.toString() == _notificationUUID));
          c.complete(true);
        }
      });
    } else {
      Fluttertoast.showToast(msg: "Device is not connected");
      c.complete(false);
    }
    return c.future;
  }

  Future sendAction(String action) {
    Completer c = new Completer();

    if (_isWritingChar) {
      Fluttertoast.showToast(msg: "Still sending Action ...");
    } else {
      Fluttertoast.showToast(msg: "Sending Action to Device...");
      _isWritingChar = true;

      List<int> listToBeWrite = [];
      if (action == _actBle2) {
        listToBeWrite = bLE2cmd;
      } else {
        listToBeWrite = getCmd(action);
      }

      writeCharacteristic(listToBeWrite).then((result) {
        _isWritingChar = false;
        disconnect();
        c.complete(result);
        Fluttertoast.showToast(
            msg: "Success Sending Action : " + result.toString());
      });
    }

    return c.future;
  }

  Future writeCharacteristic(List<int> cmd) {
    Completer c = new Completer();
    StreamSubscription<List<int>> notiSub;
    bool done = false;
    selectedbleChar.setNotifyValue(true).then((value) {
      notiSub = selectedbleChar.value.listen((val) {
        Timer(Duration(seconds: 3), () {
          if (!done) {
            c.complete(false);
            notiSub.cancel();
          }
        });
        if (val.length > 0) {
          print("notification updated , door unlocked status : " +
              (val[4] != 0).toString());
          if (val[4] != 0) {
            done = true;
            c.complete(true);
            notiSub.cancel();
          }
        }
      });
      selectedbleChar.write(cmd);
    });
    return c.future;
  }

  Future getBleService() async {
    var comp = new Completer();
    _selectedDevice.discoverServices().then((services) {
      bleService = services;
      comp.complete(bleService);
    });
    return comp.future;
  }

  void startListeningState() {
    bleSub = _selectedDevice.state.listen((onData) {
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
      _selectedDevice.disconnect();
      bleSub.cancel();
      Fluttertoast.showToast(msg: "Disconnected from " + _selectedDevice.name);
      selectedbleChar = null;
      selectedBleService = null;
      _selectedDevice = null;
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

    actionKey = _actionKeyItems[action];
    actionKey = actionKey.substring(1, actionKey.length - 1);

    List<int> newCmd = [];
    List<String> key = actionKey.split(",").map((val) => val.trim()).toList();

    for (String i in key) {
      switch (i) {
        case "yy":
          {
            newCmd.add(int.parse(getYear(), radix: 16));
            //newCmd.add(getYear());
          }
          break;
        case "MM":
          {
            //newCmd.add(getMonth());
            newCmd.add(int.parse(getMonth(), radix: 16));
          }
          break;
        case "dd":
          {
            //newCmd.add(getDate());
            newCmd.add(int.parse(getDate(), radix: 16));
          }
          break;
        case "hh":
          {
            //newCmd.add(getHour());
            newCmd.add(int.parse(getHour(), radix: 16));
          }
          break;
        case "mm":
          {
            //newCmd.add(getMinute());
            newCmd.add(int.parse(getMinute(), radix: 16));
          }
          break;
        case "ss":
          {
            newCmd.add(int.parse(getSecond(), radix: 16));
          }
          break;
        case "DD":
          {
            newCmd.add(int.parse(getDayofWeek(), radix: 16));
          }
          break;
        default:
          {
            print(hex.decode(i));
            newCmd.add(int.parse(i, radix: 16));
          }
      }
    }
    Uint8List result = encrypt(Uint8List.fromList(newCmd));
    //print("result is :" + result.toString());
    return result;
  }

  Uint8List encrypt(Uint8List data) {
    KeyParameter key =
        KeyParameter(createUint8ListFromHexString(_encryptionKey));
    ParametersWithIV params =
        ParametersWithIV(key, createUint8ListFromHexString(_encryptionIV));
    CBCBlockCipher cipher = CBCBlockCipher(AESFastEngine());
    cipher.init(true, params);
    return cipher.process(data);
  }

  //Helper

  static Uint8List createUint8ListFromHexString(String hex) {
    var result = new Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = hex.substring(i, i + 2);
      var byte = int.parse(num, radix: 16);
      result[i ~/ 2] = byte;
    }

    return result;
  }

  static String getYear() {
    return DateTime.now().year.toString();
  }

  static String getMonth() {
    return DateTime.now().month.toString();
  }

  static String getDate() {
    return DateTime.now().day.toString();
  }

  static String getHour() {
    return DateTime.now().hour.toString();
  }

  static String getMinute() {
    return DateTime.now().minute.toString();
  }

  static String getSecond() {
    return DateTime.now().second.toString();
  }

  static String getDayofWeek() {
    return DateTime.now().weekday.toString();
  }
}
