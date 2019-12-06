import 'dart:async';

import "package:flutter/material.dart";
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_ble_tool/Model/BLEController.dart';

class BLE2Controller extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PageBLE2();
  }
}

class PageBLE2 extends State<BLE2Controller> {
  //var
  bool isLock = false;
  int bleChannel = 1;
  String msg = "Disconnected";
  BleObj obj = BleObj.internal();
  bool _resting = false;
  List<BluetoothDevice> bleDevices;
  int _selectedIndex = -1;
  StreamSubscription<BluetoothDeviceState> bleSub;

  //build
  @override
  Widget build(BuildContext context) {
    bleDevices = obj.getDeviceList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("BLE 2.0"),
        backgroundColor: Colors.deepOrange,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: RawMaterialButton(
              elevation: 1.0,
              focusElevation: 2.0,
              fillColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(5),
              child: Text("Scan for device",
                  style: TextStyle(
                    color: obj.isScanning ? Colors.white24 : Colors.white,
                  )),
              onPressed: obj.isScanning
                  ? null
                  : () {
                      startScanning(context);
                    },
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: bleDevices.length,
                  itemBuilder: (BuildContext context, int pos) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                        _selectedIndex = pos;
                        });
                      },
                      child: Card(
                        color: (_selectedIndex == pos) ? Colors.blueAccent : Colors.white,
                        elevation: 2,
                        child: ListTile(
                          title: Text(bleDevices[pos].name),
                          subtitle: Text(bleDevices[pos].id.toString()),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RawMaterialButton(
                      elevation: 1.0,
                      focusElevation: 2.0,
                      fillColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(),
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Disconnect",
                        style: TextStyle(
                            color: obj.isConnected || obj.isConnecting
                                ? Colors.black
                                : Colors.black12),
                      ),
                      onPressed: obj.isConnected || obj.isConnecting
                          ? () {
                              disconnect();
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    RawMaterialButton(
                      elevation: 1.0,
                      focusElevation: 2.0,
                      fillColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(),
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Unlock/Lock Gate",
                        style: TextStyle(
                          color: (obj.isWritingChar || !obj.isConnected)
                              ? Colors.black12
                              : Colors.black,
                        ),
                      ),
                      onPressed: (obj.isWritingChar || !obj.isConnected)
                          ? null
                          : () {
                              sendUnlockAction();
                            },
                    ),
                  ]),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Status :\n" + msg,
                  style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //function
  @override
  void initState() {
    super.initState();
  }

  void updateMsg(String text) {
    setState(() {
      msg = text;
    });
  }

  void restNow() {
    _resting = true;
    new Timer(const Duration(seconds: 2), () => _resting = false);
  }

  void sendUnlockAction() {
    if (_resting) {
      Fluttertoast.showToast(
          msg: "Please wait 2 seconds before sending another action");
    } else {
      restNow();
      updateMsg("Sending Action to device...");
      obj.sendAction("BLE2").then((result) {
        updateMsg("Done");
      });
      setState(() {});
    }
  }

  void startScanning(BuildContext context) {
    _selectedIndex = -1;
    updateMsg("Scanning for Device...");
    obj.startScan().then((result) {
      if (!result) {
        updateMsg("Disconnected");
      } else {
        updateMsg("Num of devices : " + obj.getDeviceList().length.toString());
      }
    });
    setState(() {});
  }

  void disconnect() {
    bleSub?.cancel();
    if (obj.disconnect()) {
      updateMsg("Disconnected");
    }
  }

  void connectDevice(int pos) {
    var device = bleDevices[pos];
    updateMsg("Connecting to " + device.name + "...");
    obj.connectToDevice(device).then((result) {
      updateMsg("Connected to " + device.name);
      if (result) {
        listenNow();
      }
    });
    setState(() {});
  }

  void listenNow() {
    bleSub = obj.selectedDevice.state.listen((status) {
      if (status.index == 0) {
        updateMsg("Disconnected");
        bleSub.cancel();
      }
    });
  }
}
