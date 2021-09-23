part of soter_flutter_blue;

class SoterBluetoothDevice {
  final String name;
  final String deviceId;
  final BluetoothDevice? _flutterBlueDevice;

  SoterBluetoothDevice(this.name, this.deviceId, this._flutterBlueDevice);

  SoterBluetoothDevice.fromScanResult(SoterBlueScanResult scanResult)
      : name = scanResult.name,
        deviceId = scanResult.deviceId,
        _flutterBlueDevice = scanResult._flutterBlueDevice;

  /// Establishes a connection to the Bluetooth Device.
  Future<void> connect({
    Duration? timeout,
    bool autoConnect = true,
  }) async {
    if (!Platform.isWindows && _flutterBlueDevice != null) {
      return _flutterBlueDevice?.connect(
          timeout: timeout, autoConnect: autoConnect);
    }

    if (Platform.isWindows) {
      Timer? timer;
      if (timeout != null) {
        timer = Timer(timeout, () {
          disconnect();
          throw TimeoutException('Failed to connect in time.', timeout);
        });
      }

      await _FlutterBlueWindows._method.invokeMethod('connect', {
        'deviceId': deviceId,
      });
      print('connect invokeMethod success');

      timer?.cancel();

      return;
    }

    throw Exception('Couldn\'t make connection');
  }

  /// Cancels connection to the Bluetooth Device
  Future disconnect() async {
    if (!Platform.isWindows) {
      return _flutterBlueDevice?.disconnect();
    }

    if (Platform.isWindows) {
      return _FlutterBlueWindows._method.invokeMethod('disconnect', {
        'deviceId': deviceId,
      });
    }
  }

  /// The MTU size in bytes
  Stream<int> get mtu async* {
    if (!Platform.isWindows) {
      yield* _flutterBlueDevice?.mtu ?? const Stream.empty();
    }

    if (Platform.isWindows) {}
    yield await (SoterFlutterBlue.instance as _FlutterBlueWindows)
        .requestMtu(deviceId, _FlutterBlueWindows.DEFAULT_MTU);
  }

  // todo implement this
  Future<List<BluetoothService>> discoverServices() async {
    // todo
    return Future.value([]);
  }
}

class SoterBlueScanResult {
  final String name;
  final String deviceId;
  final List<int> manufacturerData;
  final int rssi;
  final BluetoothDevice? _flutterBlueDevice;

  SoterBlueScanResult.fromFlutterBlue(ScanResult result)
      : name = result.advertisementData.localName,
        deviceId = result.device.id.id,
        manufacturerData =
            result.advertisementData.manufacturerData.values.first,
        rssi = result.rssi,
        _flutterBlueDevice = result.device;

  SoterBlueScanResult.fromQuickBlueScanResult(BlueScanResult result)
      : name = result.name,
        deviceId = result.deviceId,
        manufacturerData = result.manufacturerData.toList(),
        rssi = result.rssi,
        _flutterBlueDevice = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoterBlueScanResult &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  String toString() {
    return 'SoterBlueScanResult{name: $name, deviceId: $deviceId, manufacturerData: $manufacturerData, rssi: $rssi}';
  }

  @override
  int get hashCode => deviceId.hashCode;
}

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
