import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //StreamSubscription<BlueScanResult?>? _subscription;

  //final List<BlueScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    // _subscription =
    //     FakeWindowsSoterBlue.instance.scanResultStream.listen((result) {
    //   if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
    //     print('khamidjon: result: $result');
    //     setState(() => _scanResults.add(result));
    //   }
    // });
  }

  @override
  void dispose() {
    super.dispose();
    //_subscription?.cancel();
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
              future: Future.value(
                  false), // FakeWindowsSoterBlue.instance.isBluetoothAvailable(),
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
            //FakeWindowsSoterBlue.instance.startScan();
          },
        ),
        ElevatedButton(
          child: const Text('stopScan'),
          onPressed: () {
            //FakeWindowsSoterBlue.instance.stopScan();
          },
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title: Text('hello'),
          // title: Text(
          //     '${_scanResults[index].name}(${_scanResults[index].rssi})\n${_scanResults[index].manufacturerData.toString()}'),
          // subtitle: Text(_scanResults[index].deviceId),
          onTap: () {
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => null
            //           // PeripheralDetailPage(_scanResults[index].deviceId),)
            //     );
          },
        ),
        separatorBuilder: (context, index) => const Divider(),
        itemCount: 0, //_scanResults.length,
      ),
    );
  }
}
