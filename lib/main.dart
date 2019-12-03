import 'package:flutter/material.dart';
import 'package:flutter_ble_tool/Screen/BLE2Page.dart';
import 'package:flutter_ble_tool/Screen/BLE5Page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Tool',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter BLE Tool'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() {
    PageViewState pageViewState = PageViewState();
    return pageViewState;
  }
}

class PageViewState extends State<MyHomePage> {
  PageController _controller = PageController(initialPage: 0, keepPage: true);

  List<Widget> allPages = [BLE2Controller(), BLE5Controller()];
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter BLE Tool"),
        actions: <Widget>[
          ToggleButtons(
            children: <Widget>[Text("BLE 2"), Text("BLE 5")],
            onPressed: (index) {
              setState(() {
                _controller.jumpToPage(index);
              });
            },
            isSelected: <bool>[false, false],
          )
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemBuilder: (context, index) => allPages[index],
        itemCount: allPages.length,
      ),
    );
  }
}
