// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:soter_flutter_blue/fake_windows_soter_blue.dart';
// import 'package:soter_flutter_blue/windows_lib/models.dart';
// import 'package:soter_flutter_blue_example/peripheral_detail_page.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   StreamSubscription<BlueScanResult?>? _subscription;
//
//   final List<BlueScanResult> _scanResults = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _subscription =
//         FakeWindowsSoterBlue.instance.scanResultStream.listen((result) {
//       if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
//         print('khamidjon: result: $result');
//         setState(() => _scanResults.add(result));
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _subscription?.cancel();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         body: // const Text('hello')
//             Column(
//           children: [
//             FutureBuilder(
//               future: FakeWindowsSoterBlue.instance.isBluetoothAvailable(),
//               builder: (context, snapshot) {
//                 var available = snapshot.data?.toString() ?? '...';
//                 return Text('Bluetooth init: $available');
//               },
//             ),
//             _buildButtons(),
//             const Divider(
//               color: Colors.blue,
//             ),
//             _buildListView(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: <Widget>[
//         ElevatedButton(
//           child: const Text('startScan'),
//           onPressed: () {
//             FakeWindowsSoterBlue.instance.startScan();
//           },
//         ),
//         ElevatedButton(
//           child: const Text('stopScan'),
//           onPressed: () {
//             FakeWindowsSoterBlue.instance.stopScan();
//           },
//         ),
//       ],
//     );
//   }
//
//   Widget _buildListView() {
//     return Expanded(
//       child: ListView.separated(
//         itemBuilder: (context, index) => ListTile(
//           title: Text(
//               '${_scanResults[index].name}(${_scanResults[index].rssi})\n${_scanResults[index].manufacturerData.toString()}'),
//           subtitle: Text(_scanResults[index].deviceId),
//           onTap: () {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       PeripheralDetailPage(_scanResults[index].deviceId),
//                 ));
//           },
//         ),
//         separatorBuilder: (context, index) => const Divider(),
//         itemCount: _scanResults.length,
//       ),
//     );
//   }
// }
