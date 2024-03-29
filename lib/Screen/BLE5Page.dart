import 'dart:async';

import "package:flutter/material.dart";
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_ble_tool/Model/BLEController.dart';

class BLE5Controller extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PageBLE5();
  }
}

class PageBLE5 extends State<BLE5Controller> {
  //var
  bool isLock = false;
  String msg = "Disconnected";
  BleObj obj = BleObj.internal();
  String action = "Lock Gate";
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
        title: Text("BLE 5.0"),
        backgroundColor: Colors.deepPurple,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: RawMaterialButton(
              elevation: 1.0,
              focusElevation: 2.0,
              fillColor: Colors.purple,
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
                        color: _selectedIndex == pos
                            ? Colors.blueAccent
                            : Colors.white,
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
              Container(
                width: 150,
                height: 50,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1.0, style: BorderStyle.solid),
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 0, right: 0),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: Icon(
                          FontAwesomeIcons.caretDown,
                        ),
                        iconSize: 24,
                        value: action,
                        onChanged: (newAction) {
                          setState(() {
                            action = newAction;
                          });
                        },
                        items: obj.actionsList
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.toString(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
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
                        "Send Action",
                        style: TextStyle(
                          color: (obj.isWritingChar || _selectedIndex == -1)
                              ? Colors.black12
                              : Colors.black,
                        ),
                      ),
                      onPressed: (obj.isWritingChar || _selectedIndex == -1)
                          ? null
                          //(){obj.getCmd(action);}
                          : () {
                              //obj.getCmd(action);
                              sendUserAction();
                            },
                    ),
                  ]),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Status :\n" + msg,
                  style: TextStyle(
                      color: Colors.deepPurple, fontWeight: FontWeight.bold),
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

  void updateParent() {
    setState(() {});
  }

  void updateMsg(String text) {
    msg = text;
    updateParent();
  }

  void restNow() {
    _resting = true;
    new Timer(const Duration(seconds: 2), () => _resting = false);
  }

  // void sendUserAction() {
  //   if (_resting) {
  //     Fluttertoast.showToast(
  //         msg: "Please wait 2 seconds before sending another action");
  //   } else {
  //     restNow();
  //     //obj.getCmd(action);
  //     updateMsg("Sending Action to device...");
  //     obj.sendAction(action).then((result) {
  //       updateMsg("Done");
  //     });
  //     setState(() {});
  //   }
  // }

  void sendUserAction() {
    var device = bleDevices[_selectedIndex];
    if (_resting) {
      Fluttertoast.showToast(
          msg: "Please wait 2 seconds before sending another action");
    } else {
      restNow();
      updateMsg("Sending Action to device...");
      obj.connectToDevice(device).then((result) {
        if (result) {
          listenNow();
          obj.sendAction(action).then((r) {
            if (r) {
              updateMsg("Done");
            } else {
              updateMsg("Fail");
            }
          });
        } else {
          updateMsg("Unable to connect device");
        }
      });

      setState(() {});
    }
  }

  void startScanning(BuildContext context) {
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

  // void connectDevice(int pos) {
  //   var device = bleDevices[pos];
  //   updateMsg("Connecting to " + device.name + "...");
  //   obj.connectToDevice(device).then((result) {
  //     if (result) {
  //       updateMsg("Connected to " + device.name);
  //       listenNow();
  //     } else {
  //       updateMsg("Unable to connected to " + device.name);
  //     }
  //   });
  //   setState(() {});
  // }

  void listenNow() {
    bleSub = obj.selectedDevice.state.listen((status) {
      if (status.index == 0) {
        updateMsg("Disconnected");
        bleSub.cancel();
      }
    });
  }
}
