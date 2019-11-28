import "package:flutter/material.dart";
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_ble_tool/Model/obj_BLE.dart';

Function updateMsgText;

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
  DeviceList deviceList;
  String msg = "Disconnected";
  BleObj obj = BleObj.internal();

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

  //build
  @override
  Widget build(BuildContext context) {
    if (deviceList == null) {
      deviceList = DeviceList(parent: this);
    }
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
              Container(height: 300, child: deviceList),
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

class DeviceList extends StatefulWidget {
  final PageBLE2 parent;

  final DeviceListState deviceListState = DeviceListState();

  DeviceList({Key key, @required this.parent}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    deviceListState.parent = parent;
    return deviceListState;
  }
}

class DeviceListState extends State<DeviceList> {
  PageBLE2 parent;
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
