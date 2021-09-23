import 'dart:typed_data';

class BlueScanResult {
  String name;
  String deviceId;
  Uint8List manufacturerData;
  int rssi;

  static final RegExp _numeric = RegExp(r'^-?[0-9]+$');

  BlueScanResult.fromMap(map)
      : name = map['name'],
        deviceId = _numeric.hasMatch(map['deviceId'].toString()) &&
                !map['deviceId'].toString().contains(":")
            ? _createMacAddress(
                BigInt.parse(map['deviceId'], radix: 10).toRadixString(16))
            : map['deviceId'],
        manufacturerData = map['manufacturerData'],
        rssi = map['rssi'];

  Map toMap() => {
        'name': name,
        'deviceId': deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
      };

  static String _createMacAddress(String hexNum) {
    String temp = hexNum.toString();
    String result = temp.substring(0, 2);
    temp = temp.substring(2);

    do {
      result += (':' + temp.substring(0, 2));
      temp = temp.substring(2);
    } while (temp.isNotEmpty);

    return result.toUpperCase();
  }
}

class BlueConnectionState {
  static const disconnected = BlueConnectionState._('disconnected');
  static const connected = BlueConnectionState._('connected');

  final String value;

  const BlueConnectionState._(this.value);

  static BlueConnectionState parse(String value) {
    if (value == disconnected.value) {
      return disconnected;
    } else if (value == connected.value) {
      return connected;
    }
    throw ArgumentError.value(value);
  }
}

class BleInputProperty {
  static const disabled = BleInputProperty._('disabled');
  static const notification = BleInputProperty._('notification');
  static const indication = BleInputProperty._('indication');

  final String value;

  const BleInputProperty._(this.value);
}

class BleOutputProperty {
  static const withResponse = BleOutputProperty._('withResponse');
  static const withoutResponse = BleOutputProperty._('withoutResponse');

  final String value;

  const BleOutputProperty._(this.value);
}
