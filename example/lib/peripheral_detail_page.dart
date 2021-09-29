import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:soter_flutter_blue/soter_flutter_blue.dart';

const WOODEMI_SUFFIX = 'ba5e-f4ee-5ca1-eb1e5e4b1ce0';

const WOODEMI_SERV__COMMAND = '57444d01-$WOODEMI_SUFFIX';
const WOODEMI_CHAR__COMMAND_REQUEST = '57444e02-$WOODEMI_SUFFIX';
const WOODEMI_CHAR__COMMAND_RESPONSE = WOODEMI_CHAR__COMMAND_REQUEST;

const WOODEMI_MTU_WUART = 247;

class PeripheralDetailPage extends StatefulWidget {
  final SoterBluetoothDevice device;

  const PeripheralDetailPage(this.device, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PeripheralDetailPageState();
  }
}

class _PeripheralDetailPageState extends State<PeripheralDetailPage> {
  List<SoterBluetoothService> services = [];
  int mtu = -1;
  String status = 'not connected';

  String convertServicesToString() {
    String result = '';
    for (var service in services) {
      result += ', ${service.uuid}';
    }

    return result;
  }

  final serviceUUID = TextEditingController(text: WOODEMI_SERV__COMMAND);
  final characteristicUUID =
      TextEditingController(text: WOODEMI_CHAR__COMMAND_REQUEST);
  final binaryCode = TextEditingController(
      text: hex.encode([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeripheralDetailPage'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: Text('connect: $status'),
                onPressed: () async {
                  print('Khamidjon: starting trying connection');
                  await widget.device.connect();
                  setState(() {
                    status = 'Connected';
                    print('Khamidjon: status CONNECTED');
                  });
                },
              ),
              ElevatedButton(
                child: Text('disconnect: $status'),
                onPressed: () async {
                  await widget.device.disconnect();
                  setState(() {
                    status = 'Disconnected';
                    print('Khamidjon: status DISCONNECTED');
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: Text('discoverServices: ${convertServicesToString()}'),
                onPressed: () async {
                  services = await widget.device.discoverServices();
                  setState(() {});
                },
              ),
            ],
          ),
          ElevatedButton(
            child: const Text('setNotifiable'),
            onPressed: () {
              // widget.device..setNotifiable(
              //     widget.deviceId,
              //     WOODEMI_SERV__COMMAND,
              //     WOODEMI_CHAR__COMMAND_RESPONSE,
              //     BleInputProperty.indication);
            },
          ),
          TextField(
            controller: serviceUUID,
            decoration: const InputDecoration(
              labelText: 'ServiceUUIDs: ',
            ),
          ),
          TextField(
            controller: characteristicUUID,
            decoration: const InputDecoration(
              labelText: 'CharacteristicUUID',
            ),
          ),
          TextField(
            controller: binaryCode,
            decoration: const InputDecoration(
              labelText: 'Binary code',
            ),
          ),
          // ElevatedButton(
          //   child: const Text('send'),
          //   onPressed: () {
          //     var value = Uint8List.fromList(hex.decode(binaryCode.text));
          //     FakeWindowsSoterBlue.instance.writeValue(
          //         widget.deviceId,
          //         serviceUUID.text,
          //         characteristicUUID.text,
          //         value,
          //         BleOutputProperty.withResponse);
          //   },
          // ),
          ElevatedButton(
            child: Text('requestMtu, current mtu: $mtu'),
            onPressed: () async {
              mtu = await widget.device.mtu.first;
            },
          ),
        ],
      ),
    );
  }
}
