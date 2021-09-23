// import 'dart:typed_data';
//
// import 'package:convert/convert.dart';
// import 'package:flutter/material.dart';
// import 'package:soter_flutter_blue/fake_windows_soter_blue.dart';
// import 'package:soter_flutter_blue/windows_lib/models.dart';
//
// const WOODEMI_SUFFIX = 'ba5e-f4ee-5ca1-eb1e5e4b1ce0';
//
// const WOODEMI_SERV__COMMAND = '57444d01-$WOODEMI_SUFFIX';
// const WOODEMI_CHAR__COMMAND_REQUEST = '57444e02-$WOODEMI_SUFFIX';
// const WOODEMI_CHAR__COMMAND_RESPONSE = WOODEMI_CHAR__COMMAND_REQUEST;
//
// const WOODEMI_MTU_WUART = 247;
//
// class PeripheralDetailPage extends StatefulWidget {
//   final String deviceId;
//
//   const PeripheralDetailPage(this.deviceId, {Key? key}) : super(key: key);
//
//   @override
//   State<StatefulWidget> createState() {
//     return _PeripheralDetailPageState();
//   }
// }
//
// class _PeripheralDetailPageState extends State<PeripheralDetailPage> {
//   @override
//   void initState() {
//     super.initState();
//     FakeWindowsSoterBlue.instance.setConnectionHandler(_handleConnectionChange);
//     FakeWindowsSoterBlue.instance.setServiceHandler(_handleServiceDiscovery);
//     FakeWindowsSoterBlue.instance.setValueHandler(_handleValueChange);
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     FakeWindowsSoterBlue.instance.setValueHandler(null);
//     FakeWindowsSoterBlue.instance.setServiceHandler(null);
//     FakeWindowsSoterBlue.instance.setConnectionHandler(null);
//   }
//
//   void _handleConnectionChange(String deviceId, BlueConnectionState state) {
//     print('_handleConnectionChange $deviceId, $state');
//   }
//
//   void _handleServiceDiscovery(String deviceId, String serviceId) {
//     print('_handleServiceDiscovery $deviceId, $serviceId');
//   }
//
//   void _handleValueChange(
//       String deviceId, String characteristicId, Uint8List value) {
//     print(
//         '_handleValueChange $deviceId, $characteristicId, ${hex.encode(value)}');
//   }
//
//   final serviceUUID = TextEditingController(text: WOODEMI_SERV__COMMAND);
//   final characteristicUUID =
//       TextEditingController(text: WOODEMI_CHAR__COMMAND_REQUEST);
//   final binaryCode = TextEditingController(
//       text: hex.encode([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PeripheralDetailPage'),
//       ),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: <Widget>[
//               ElevatedButton(
//                 child: const Text('connect'),
//                 onPressed: () {
//                   FakeWindowsSoterBlue.instance.connect(widget.deviceId);
//                 },
//               ),
//               ElevatedButton(
//                 child: const Text('disconnect'),
//                 onPressed: () {
//                   FakeWindowsSoterBlue.instance.disconnect(widget.deviceId);
//                 },
//               ),
//             ],
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: <Widget>[
//               ElevatedButton(
//                 child: const Text('discoverServices'),
//                 onPressed: () {
//                   FakeWindowsSoterBlue.instance
//                       .discoverServices(widget.deviceId);
//                 },
//               ),
//             ],
//           ),
//           ElevatedButton(
//             child: const Text('setNotifiable'),
//             onPressed: () {
//               FakeWindowsSoterBlue.instance.setNotifiable(
//                   widget.deviceId,
//                   WOODEMI_SERV__COMMAND,
//                   WOODEMI_CHAR__COMMAND_RESPONSE,
//                   BleInputProperty.indication);
//             },
//           ),
//           TextField(
//             controller: serviceUUID,
//             decoration: const InputDecoration(
//               labelText: 'ServiceUUID',
//             ),
//           ),
//           TextField(
//             controller: characteristicUUID,
//             decoration: const InputDecoration(
//               labelText: 'CharacteristicUUID',
//             ),
//           ),
//           TextField(
//             controller: binaryCode,
//             decoration: const InputDecoration(
//               labelText: 'Binary code',
//             ),
//           ),
//           ElevatedButton(
//             child: const Text('send'),
//             onPressed: () {
//               var value = Uint8List.fromList(hex.decode(binaryCode.text));
//               FakeWindowsSoterBlue.instance.writeValue(
//                   widget.deviceId,
//                   serviceUUID.text,
//                   characteristicUUID.text,
//                   value,
//                   BleOutputProperty.withResponse);
//             },
//           ),
//           ElevatedButton(
//             child: const Text('requestMtu'),
//             onPressed: () async {
//               var mtu = await FakeWindowsSoterBlue.instance
//                   .requestMtu(widget.deviceId, WOODEMI_MTU_WUART);
//               print('requestMtu $mtu');
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
