import "package:flutter/material.dart";
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_ble_tool/Model/obj_BLE.dart';

Function updateMsgText;

class BLE5Controller extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PageBLE5();
  }
}

class PageBLE5 extends State<BLE5Controller> {
  //var
  bool isLock = false;
  DeviceList2 deviceList;
  String msg = "Disconnected";
  BleObj obj = BleObj.internal();
  String action = "Lock Gate";

  @override
  void initState() {
    updateMsgText = updateMsg;
    super.initState();
  }

  void updateParent() {
    setState(() {});
  }

  void updateMsg(String text) {
    msg = text;
    updateParent();
  }

  List<DropdownMenuItem<String>> getDropDownItems() {
    return ["A", "B"].map<DropdownMenuItem<String>>((String val) {
      return DropdownMenuItem<String>(
        value: val,
        child: Text(
          val.toString(),
        ),
      );
    }).toList();
  }

  //build
  @override
  Widget build(BuildContext context) {
    if (deviceList == null) {
      deviceList = DeviceList2(parent: this);
    }
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
              Container(height: 300, child: deviceList),
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
                            color: obj.isConnected
                                ? Colors.black
                                : Colors.black12),
                      ),
                      onPressed: obj.isConnected
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
                          color: (obj.isWritingChar || !obj.isConnected)
                              ? Colors.black12
                              : Colors.black,
                        ),
                      ),
                      onPressed: (obj.isWritingChar || !obj.isConnected)
                          ? null
                          : () {
                              updateMsg("Sending Action to device...");
                              obj.sendAction().then((result) {
                                updateMsg("Done");
                              });
                              setState(() {});
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

  void startScanning(BuildContext context) {
    updateMsg("Scanning for Device...");
    obj.startScan().then((result) {
      deviceList.deviceListState.updateListView();
      updateMsg("Num of devices : " + result.length.toString());
    });
    setState(() {});
  }

  void disconnect() {
    if (obj.isConnected) {
      obj.disconnect();
      updateMsg("Disconnected");
    }
  }
}

class DeviceList2 extends StatefulWidget {
  final PageBLE5 parent;

  final DeviceListState2 deviceListState = DeviceListState2();

  DeviceList2({Key key, @required this.parent}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    deviceListState.parent = parent;
    return deviceListState;
  }
}

class DeviceListState2 extends State<DeviceList2> {
  PageBLE5 parent;
  BleObj obj = BleObj.internal();
  BuildContext bcontext;
  List<BluetoothDevice> bleDevices;

  @override
  Widget build(BuildContext context) {
    bleDevices = obj.getDeviceList();
    bcontext = context;
    return ListView.builder(
      itemCount: bleDevices.length,
      itemBuilder: (BuildContext context, int pos) {
        return GestureDetector(
          onTap: () {
            connectDevice(pos);
          },
          child: Card(
            color: Colors.white,
            elevation: 2,
            child: ListTile(
              title: Text(bleDevices[pos].name),
              subtitle: Text(bleDevices[pos].id.toString()),
            ),
          ),
        );
      },
    );
  }

  // function
  void updateListView() {
    setState(() {});
  }

  void connectDevice(int pos) {
    var device = bleDevices[pos];
    updateMsgText("Connecting to " + device.name + "...");
    obj.connectToDevice(device).then((result) {
      updateMsgText("Connected to " + device.name);
    });
  }
}
