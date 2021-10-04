import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soter_flutter_blue/soter_flutter_blue.dart';
import 'package:soter_flutter_blue_example/peripheral_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<SoterBlueScanResult> _scanResults = [];
  final StreamController<SoterBlueScanResult> _controller = StreamController();
  Stream<SoterBlueScanResult> get resultStream => _controller.stream;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: // const Text('hello')
            Column(
          children: [
            FutureBuilder(
              future: Future.value(true), //SoterFlutterBlue.instance.isOn,
              builder: (context, snapshot) {
                var available = snapshot.data?.toString() ?? '...';
                return Text('Bluetooth init: $available');
              },
            ),
            _buildButtons(),
            const Divider(
              color: Colors.blue,
            ),
            _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
            child: const Text('startScan'),
            onPressed: () {
              _controller.addStream(startScan());
            }),
        ElevatedButton(
          child: const Text('stopScan'),
          onPressed: () {
            SoterFlutterBlue.instance.stopScan();
          },
        ),
      ],
    );
  }

  Stream<SoterBlueScanResult> startScan() {
    return SoterFlutterBlue.instance.scan();
  }

  Widget _buildListView() {
    return StreamBuilder(
        stream: resultStream,
        builder: (BuildContext context,
            AsyncSnapshot<SoterBlueScanResult> snapshot) {
          if (snapshot.hasData) {
            var result = snapshot.data!;
            if (!_scanResults.any((element) =>
                element.device.deviceId == result.device.deviceId)) {
              _scanResults.add(result);
            }
          }
          return Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => ListTile(
                title: Text(
                    '${_scanResults[index].device.name}(${_scanResults[index].rssi})\n${_scanResults[index].manufacturerData.toString()}'),
                subtitle: Text(_scanResults[index].device.deviceMac),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PeripheralDetailPage(_scanResults[index].device),
                      ));
                },
              ),
              separatorBuilder: (context, index) => const Divider(),
              itemCount: _scanResults.length,
            ),
          );
        });
  }
}
