import 'package:flutter/material.dart';
import 'package:soter_flutter_blue/soter_flutter_blue.dart';

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
  List<SoterBluetoothDevice> connectedDevices = [];

  String convertConnectedDevicesToString() {
    String result = 'Connected Devices: ${connectedDevices.length}\n';
    for (var device in connectedDevices) {
      result +=
          'name: ${device.name}, deviceId: ${device.deviceId}, mac: ${device.deviceMac}\n';
    }
    return result;
  }

  String convertServicesToString() {
    String result = '';
    for (var service in services) {
      result += ', ${service.uuid}';
    }

    return result;
  }

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
            child: const Text('Connected Devices'),
            onPressed: () async {
              connectedDevices =
                  await SoterFlutterBlue.instance.connectedDevices;
              setState(() {});
            },
          ),
          Text('${convertConnectedDevicesToString()}'),
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
