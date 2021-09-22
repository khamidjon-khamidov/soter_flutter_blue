import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:soter_flutter_blue/soter_flutter_blue.dart';

import 'windows_lib/models.dart';

typedef OnConnectionChanged = void Function(
    String deviceId, BlueConnectionState state);

typedef OnServiceDiscovered = void Function(String deviceId, String serviceId);

typedef OnValueChanged = void Function(
    String deviceId, String characteristicId, Uint8List value);

abstract class FakeWindowsSoterBlue {
  OnConnectionChanged? onConnectionChanged;
  OnServiceDiscovered? onServiceDiscovered;
  OnValueChanged? onValueChanged;

  static final FakeWindowsSoterBlue _instance = Platform.isWindows
      ? _FakeWindowsSoterBlueImpl()
      : _FakeWindowsSoterBleEmptyImpl();

  static FakeWindowsSoterBlue get instance => _instance;

  Future<bool> isBluetoothAvailable();

  void startScan();

  void stopScan();

  Stream<BlueScanResult> get scanResultStream;

  void connect(String deviceId);

  void disconnect(String deviceId);

  void discoverServices(String deviceId);

  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty);

  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty);

  Future<int> requestMtu(String deviceId, int expectedMtu);

  void setValueHandler(OnValueChanged? onValueChanged);

  void setServiceHandler(OnServiceDiscovered? onServiceDiscovered);

  void setConnectionHandler(OnConnectionChanged? onConnectionChanged);
}

class _FakeWindowsSoterBlueImpl extends FakeWindowsSoterBlue {
  static const MethodChannel _method = MethodChannel('$PLUGIN_NAME/method');
  static const _eventScanResult = EventChannel('$PLUGIN_NAME/event.scanResult');
  static const _messageConnector = BasicMessageChannel(
      '$PLUGIN_NAME/message.connector', StandardMessageCodec());

  _FakeWindowsSoterBlueImpl() {
    _messageConnector.setMessageHandler(_handleConnectorMessage);
  }

  Future<void> _handleConnectorMessage(dynamic message) {
    print('_handleConnectorMessage $message');
    if (message['ConnectionState'] != null) {
      String deviceId = message['deviceId'];
      BlueConnectionState connectionState =
          BlueConnectionState.parse(message['ConnectionState']);
      onConnectionChanged?.call(deviceId, connectionState);
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'discovered') {
        String deviceId = message['deviceId'];
        List<dynamic> services = message['services'];
        for (var s in services) {
          onServiceDiscovered?.call(deviceId, s);
        }
      }
    } else if (message['characteristicValue'] != null) {
      String deviceId = message['deviceId'];
      var characteristicValue = message['characteristicValue'];
      String characteristic = characteristicValue['characteristic'];
      Uint8List value = Uint8List.fromList(
          characteristicValue['value']); // In case of _Uint8ArrayView
      onValueChanged?.call(deviceId, characteristic, value);
    } else if (message['mtuConfig'] != null) {
      _mtuConfigController.add(message['mtuConfig']);
    }

    return Future.value();
  }

  final Stream<BlueScanResult> _scanResultStream = _eventScanResult
      .receiveBroadcastStream({'name': 'scanResult'}).map(
          (item) => BlueScanResult.fromMap(item));

  @override
  Stream<BlueScanResult> get scanResultStream => _scanResultStream;

  @override
  void connect(String deviceId) {
    _method.invokeMethod('connect', {
      'deviceId': deviceId,
    }).then((_) => print('connect invokeMethod success'));
  }

  @override
  void disconnect(String deviceId) {
    _method.invokeMethod('disconnect', {
      'deviceId': deviceId,
    }).then((_) => print('disconnect invokeMethod success'));
  }

  @override
  void discoverServices(String deviceId) {
    _method.invokeMethod('discoverServices', {
      'deviceId': deviceId,
    }).then((_) => print('discoverServices invokeMethod success'));
  }

  @override
  Future<bool> isBluetoothAvailable() async =>
      (await _method.invokeMethod('isBluetoothAvailable') ?? false);

  // FIXME Close
  final _mtuConfigController = StreamController<int>.broadcast();

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    _method.invokeMethod('requestMtu', {
      'deviceId': deviceId,
      'expectedMtu': expectedMtu,
    }).then((_) => print('requestMtu invokeMethod success'));
    return await _mtuConfigController.stream.first;
  }

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) {
    return _method.invokeMethod('setNotifiable', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
      'bleInputProperty': bleInputProperty.value,
    }).then((_) => print('setNotifiable invokeMethod success'));
  }

  @override
  void startScan() {
    _method
        .invokeMethod('startScan')
        .then((_) => print('startScan invokeMethod success'));
  }

  @override
  void stopScan() {
    _method
        .invokeMethod('stopScan')
        .then((_) => print('stopScan invokeMethod success'));
  }

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) {
    return _method.invokeMethod('writeValue', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
      'value': value,
      'bleOutputProperty': bleOutputProperty.value,
    }).then((_) {
      print('writeValue invokeMethod success');
    }).catchError((onError) {
      // Characteristic sometimes unavailable on Android
      throw onError;
    });
  }

  @override
  void setConnectionHandler(OnConnectionChanged? onConnectionChanged) {
    this.onConnectionChanged = onConnectionChanged;
  }

  @override
  void setServiceHandler(OnServiceDiscovered? onServiceDiscovered) {
    this.onServiceDiscovered = onServiceDiscovered;
  }

  @override
  void setValueHandler(OnValueChanged? onValueChanged) {
    this.onValueChanged = onValueChanged;
  }
}

class _FakeWindowsSoterBleEmptyImpl extends FakeWindowsSoterBlue {
  @override
  void connect(String deviceId) {}

  @override
  void disconnect(String deviceId) {}

  @override
  void discoverServices(String deviceId) {}

  @override
  Future<bool> isBluetoothAvailable() {
    return Future.value(false);
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) {
    return Future.value(-1);
  }

  @override
  Stream<BlueScanResult> get scanResultStream => const Stream.empty();

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) {
    return Future.value();
  }

  @override
  void startScan() {}

  @override
  void stopScan() {}

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) {
    return Future.value();
  }

  @override
  void setConnectionHandler(OnConnectionChanged? onConnectionChanged) {}

  @override
  void setServiceHandler(OnServiceDiscovered? onServiceDiscovered) {}

  @override
  void setValueHandler(OnValueChanged? onValueChanged) {}
}

///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
