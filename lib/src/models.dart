part of soter_flutter_blue;

class SoterBluetoothService {
  final Guid uuid;
  final String deviceId;
  final List<SoterBluetoothCharacteristic> characteristics;

  SoterBluetoothService(this.uuid, this.deviceId, this.characteristics);

  SoterBluetoothService.fromBluetoothService(BluetoothService service)
      : uuid = service.uuid,
        deviceId = service.deviceId.id,
        characteristics = service.characteristics
            .map((characteristic) =>
                SoterBluetoothCharacteristic.fromFlutterBlueCharacteristic(
                    characteristic))
            .toList();
}

class SoterBluetoothCharacteristic {
  final Guid? _uuid;
  final Guid? _serviceUuid;
  final String? _deviceId;
  final BluetoothCharacteristic? _bluetoothCharacteristicFlutterBlue;

  BehaviorSubject<List<int>> _value;

  SoterBluetoothCharacteristic(this._uuid, this._serviceUuid, this._deviceId,
      List<int> values, this._bluetoothCharacteristicFlutterBlue)
      : _value = BehaviorSubject.seeded(values);

  SoterBluetoothCharacteristic.fromFlutterBlueCharacteristic(
      BluetoothCharacteristic characteristic)
      : _uuid = characteristic.uuid,
        _serviceUuid = characteristic.serviceUuid,
        _deviceId = characteristic.deviceId.id,
        _bluetoothCharacteristicFlutterBlue = characteristic,
        _value = BehaviorSubject.seeded(characteristic.lastValue);

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
                (m['value'] as Uint8List).toList(),
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
        ? SoterBleOutputProperty.withoutResponse.value
        : SoterBleOutputProperty.withResponse.value;

    _FlutterBlueWindows._method.invokeMethod('writeValue', {
      'deviceId': _deviceId,
      'service': _serviceUuid.toString(),
      'characteristic': _uuid.toString(),
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
      'bleInputProperty': notify
          ? SoterBleInputProperty.notification.value
          : SoterBleInputProperty.disabled.value,
    });
    print('setNotifiable invokeMethod success');

    return _FlutterBlueWindows._messageStream
        .where((m) => m['SetNotificationResponse'] != null)
        .where((m) => m['deviceId'] == _deviceId!)
        .map<bool>((m) => m['SetNotificationResponse'])
        .first;
  }
}

class SoterBluetoothDevice {
  final String name;
  final String _deviceId;
  final BluetoothDevice? _flutterBlueDevice;

  static final RegExp _numeric = RegExp(r'^-?[0-9]+$');

  SoterBluetoothDevice(this.name, this._deviceId, this._flutterBlueDevice);

  String get deviceId => _deviceId;

  String get deviceMac {
    if (!Platform.isWindows) {
      return _deviceId;
    }
    if (_deviceId.contains(':') || _numeric.hasMatch(_deviceId)) {
      return _deviceId;
    }
    print('_createMacAddress: _deviceId: $_deviceId');
    String temp = BigInt.parse(_deviceId, radix: 10).toRadixString(16);

    if (temp.length != 12) {
      return _deviceId;
    }

    String result = temp.substring(0, 2);
    temp = temp.substring(2);

    while (temp.isNotEmpty) {
      result += (':' + temp.substring(0, 2));
      temp = temp.substring(2);
    }

    print('_createMacAddress: mac: $result');
    return result;
  }

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

      print('SoterFlutterBlue: trying to connect to $deviceId');

      await _FlutterBlueWindows._method.invokeMethod('connect', {
        'deviceId': deviceId,
      });
      print('connect invokeMethod success');

      timer?.cancel();

      return _FlutterBlueWindows._messageStream
          .where((m) => m['ConnectionRequestState'] != null)
          .map((m) {
            print(
                'Connection Request result: deviceId: ${m['deviceId']}, status: ${m['ConnectionRequestState']}');
            return m;
          })
          .where((m) => m['deviceId'] == deviceId)
          .map<void>((event) {
            print('Connected to device: $deviceId');
          })
          .first;
    }

    throw Exception('Couldn\'t make connection');
  }

  /// Cancels connection to the Bluetooth Device
  Future disconnect() async {
    if (!Platform.isWindows) {
      return _flutterBlueDevice?.disconnect();
    }

    print('SoterFlutterBlue: trying to disconnect: $deviceId');

    if (Platform.isWindows) {
      await _FlutterBlueWindows._method.invokeMethod('disconnect', {
        'deviceId': deviceId,
      });

      print('SoterFlutterBlue: disconnected');
      return Future.value();
    }

    return Future.value();
    //   print('SoterFlutterBlue: disconnection request sent to $deviceId');
    //   return _FlutterBlueWindows._messageStream
    //       .where((m) => m['DisconnectionRequestState'] != null)
    //       .map((m) {
    //         print('Disconnected device: deviceId: ${m['deviceId']}');
    //         return m;
    //       })
    //       .where((m) {
    //         print(
    //             'Disconnected device: deviceId: ${m['deviceId']}, expectedDeviceId: ${deviceId}');
    //         return (m['deviceId'] as String) == deviceId;
    //       })
    //       .map<void>((event) {})
    //       .first;
    // }
  }

  /// The MTU size in bytes
  Stream<int> get mtu async* {
    if (!Platform.isWindows) {
      yield* _flutterBlueDevice?.mtu ?? const Stream.empty();
    }

    if (Platform.isWindows) {
      yield await (SoterFlutterBlue.instance as _FlutterBlueWindows)
          .requestMtu(deviceId, _FlutterBlueWindows.DEFAULT_MTU);
    }
  }

  Future<List<SoterBluetoothService>> discoverServices() async {
    if (!Platform.isWindows) {
      return (await _flutterBlueDevice!.discoverServices())
          .map((BluetoothService service) =>
              SoterBluetoothService.fromBluetoothService(service))
          .toList();
    }

    await _FlutterBlueWindows._method.invokeMethod('discoverServices', {
      'deviceId': deviceId,
    });

    return _FlutterBlueWindows._messageStream
        .where((m) => m['DiscoverServicesState'] != null)
        .map((m) {
          print(
              'Received DiscoverServices Response from device: ${m['deviceId']}. Status: ${m['DiscoverServicesState']}');
          return m;
        })
        .where((m) => m['deviceId'] == _deviceId)
        .map<List<SoterBluetoothService>>((m) {
          if (m['DiscoverServicesState'] == 'Failure') {
            return [];
          }
          List<SoterBluetoothService> services = [];
          List servicesMapped = m['services'];
          for (var serviceMapped in servicesMapped) {
            List<SoterBluetoothCharacteristic> characteristics = [];
            List characteristicsMapped = serviceMapped['characteristics'];
            for (var charMapped in characteristicsMapped) {
              characteristics.add(SoterBluetoothCharacteristic(
                Guid(charMapped['uuid']),
                Guid(charMapped['serviceUuid']),
                charMapped['deviceId'],
                (charMapped['value'] as Uint8List).toList(),
                null,
              ));
            }

            services.add(SoterBluetoothService(
              Guid(serviceMapped['uuid']),
              serviceMapped['deviceId'],
              characteristics,
            ));
          }
          return services;
        })
        .first;
  }

  @override
  String toString() {
    return 'SoterBluetoothDevice{name: $name, _deviceId: $_deviceId, mac: $deviceMac}';
  }
}

class SoterBlueScanResult {
  final SoterBluetoothDevice device;
  final List<int> manufacturerData;
  final int rssi;

  SoterBlueScanResult.fromFlutterBlue(ScanResult result)
      : device = SoterBluetoothDevice(
          result.advertisementData.localName,
          result.device.id.id,
          result.device,
        ),
        manufacturerData =
            result.advertisementData.manufacturerData.values.first,
        rssi = result.rssi;

  SoterBlueScanResult.fromMap(Map map)
      : device = SoterBluetoothDevice(
          map['name'],
          map['deviceId'],
          null,
        ),
        manufacturerData =
            (map['manufacturerData'] as Uint8List).toList().sublist(2),
        rssi = map['rssi'];

  Map toMap() => {
        'name': device.name,
        'deviceId': device._deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoterBlueScanResult &&
          runtimeType == other.runtimeType &&
          device == other.device &&
          manufacturerData == other.manufacturerData &&
          rssi == other.rssi;

  @override
  int get hashCode =>
      device.hashCode ^ manufacturerData.hashCode ^ rssi.hashCode;

  @override
  String toString() {
    return 'SoterBlueScanResult{device: $device, manufacturerData: $manufacturerData, rssi: $rssi}';
  }
}

class SoterBlueConnectionState {
  static const disconnected = SoterBlueConnectionState._('disconnected');
  static const connected = SoterBlueConnectionState._('connected');

  final String value;

  const SoterBlueConnectionState._(this.value);

  static SoterBlueConnectionState parse(String value) {
    if (value == disconnected.value) {
      return disconnected;
    } else if (value == connected.value) {
      return connected;
    }
    throw ArgumentError.value(value);
  }
}

class SoterBleInputProperty {
  static const disabled = SoterBleInputProperty._('disabled');
  static const notification = SoterBleInputProperty._('notification');
  static const indication = SoterBleInputProperty._('indication');

  final String value;

  const SoterBleInputProperty._(this.value);
}

class SoterBleOutputProperty {
  static const withResponse = SoterBleOutputProperty._('withResponse');
  static const withoutResponse = SoterBleOutputProperty._('withoutResponse');

  final String value;

  const SoterBleOutputProperty._(this.value);
}
