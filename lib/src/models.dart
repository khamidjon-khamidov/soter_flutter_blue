part of soter_flutter_blue;

class SoterBluetoothService {
  final Guid uuid;
  final String deviceId;
  final List<SoterBluetoothCharacteristic> characteristics;

  SoterBluetoothService(this.uuid, this.deviceId, this.characteristics);
}

class SoterBluetoothCharacteristic {
  final Guid? _uuid;
  final Guid? _serviceUuid;
  final String? _deviceId;
  final BluetoothCharacteristic? _bluetoothCharacteristicFlutterBlue;

  BehaviorSubject<List<int>> _value;

  SoterBluetoothCharacteristic(this._uuid, this._serviceUuid, this._deviceId,
      this._value, this._bluetoothCharacteristicFlutterBlue);

  Guid get uuid {
    if (!Platform.isWindows) {
      return _bluetoothCharacteristicFlutterBlue!.uuid;
    }
    return _uuid!;
  }

  Guid get serviceUuid {
    if (!Platform.isWindows) {
      return _bluetoothCharacteristicFlutterBlue!.serviceUuid;
    }
    return _serviceUuid!;
  }

  Stream<List<int>> get value {
    if (!Platform.isWindows) {
      return _bluetoothCharacteristicFlutterBlue!.value;
    }
    return Rx.merge([
      _value.stream,
      _onValueChangedStream,
    ]);
  }

  List<int> get lastValue {
    if (!Platform.isWindows) {
      return _bluetoothCharacteristicFlutterBlue!.lastValue;
    }
    return _value.value ?? [];
  }

  Stream<SoterBluetoothCharacteristic> get _onCharacteristicChangedStream =>
      _FlutterBlueWindows._messageStream
          .where((m) => m['characteristicChanged'] != null)
          .where((m) => _deviceId == m['deviceId'])
          .where((m) => m['characteristicUuid'] == uuid.toString())
          .map((m) => SoterBluetoothCharacteristic(
                Guid(m['characteristicUuid']),
                Guid(m['serviceUuid']),
                m['deviceId'],
                BehaviorSubject.seeded((m['value'] as Uint8List).toList()),
                null,
              ));

  Stream<List<int>> get _onValueChangedStream =>
      _onCharacteristicChangedStream.map((c) => c.lastValue);

  /// Writes the value of a characteristic.
  /// [CharacteristicWriteType.withoutResponse]: the write is not
  /// guaranteed and will return immediately with success.
  /// [CharacteristicWriteType.withResponse]: the method will return after the
  /// write operation has either passed or failed.
  Future<Null> write(List<int> value,
      {bool withoutResponse = false, bool returnValueOnSuccess = false}) async {
    if (!Platform.isWindows) {
      return _bluetoothCharacteristicFlutterBlue!.write(
        value,
        withoutResponse: withoutResponse,
        returnValueOnSuccess: returnValueOnSuccess,
      );
    }

    final type = withoutResponse
        ? BleOutputProperty.withoutResponse
        : BleOutputProperty.withResponse;

    _FlutterBlueWindows._method.invokeMethod('writeValue', {
      'deviceId': _deviceId,
      'service': _serviceUuid,
      'characteristic': _uuid,
      'value': Uint8List.fromList(value),
      'bleOutputProperty': type,
    });

    print('writeValue invokeMethod success');

    return _FlutterBlueWindows._messageStream
        .where((m) => m['WriteCharacteristicResponse'] == 0)
        .map((m) {
          print(
              'WriteValueResponse came from device: ${m['deviceId']}. Status: ${m['success']}');
          return m;
        })
        .where((m) =>
            (_deviceId == m['deviceId']) &&
            (_serviceUuid == m['serviceUuid']) &&
            (_uuid == m['characteristicsUuid']))
        .first
        .then((m) => m['success'])
        .then((success) => (!success)
            ? throw Exception('Failed to write the characteristic')
            : null)
        .then((_) {
          if (returnValueOnSuccess) {
            _value.add(value);
          }
        })
        .then((_) => null);
  }

  Future<bool> setNotifyValue(bool notify) async {
    if (!Platform.isWindows) {
      return _bluetoothCharacteristicFlutterBlue!.setNotifyValue(notify);
    }

    await _FlutterBlueWindows._method.invokeMethod('setNotifiable', {
      'deviceId': _deviceId.toString(),
      'service': _serviceUuid.toString(),
      'characteristic': _uuid.toString(),
      'bleInputProperty':
          notify ? BleInputProperty.notification : BleInputProperty.disabled,
    });
    print('setNotifiable invokeMethod success');

    return _FlutterBlueWindows._messageStream
        .where((m) => m['SetNotificationResponse'] != null)
        .map<bool>((m) => m['SetNotificationResponse'])
        .last;
  }
}

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
    // if (message['ServiceState'] == 'discovered') {
    //   String deviceId = message['deviceId'];
    //   List<dynamic> services = message['services'];
    //   for (var s in services) {
    //     onServiceDiscovered?.call(deviceId, s);
    //   }
    // }
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
        manufacturerData = result.manufacturerData.toList().sublist(2),
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
  String _deviceId;
  Uint8List manufacturerData;
  int rssi;

  static final RegExp _numeric = RegExp(r'^-?[0-9]+$');

  String get deviceId {
    if (_deviceId.contains(':') || _numeric.hasMatch(_deviceId)) {
      return _deviceId;
    }
    print('_createMacAddress: _deviceId: $_deviceId');
    String temp = BigInt.parse(_deviceId, radix: 10).toRadixString(16);
    String result = temp.substring(0, 2);
    temp = temp.substring(2);

    while (temp.isNotEmpty) {
      result += (':' + temp.substring(0, 2));
      temp = temp.substring(2);
    }

    print('_createMacAddress: mac: $result');
    return result;
  }

  BlueScanResult.fromMap(map)
      : name = map['name'],
        _deviceId = map['deviceId'],
        manufacturerData = map['manufacturerData'],
        rssi = map['rssi'];

  Map toMap() => {
        'name': name,
        'deviceId': deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
      };
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
