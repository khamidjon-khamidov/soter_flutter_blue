import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';
import 'package:soter_flutter_blue/windows_lib/models.dart';

import 'fake_windows_soter_blue.dart';

const PLUGIN_NAME = 'soter_flutter_blue';

abstract class SoterFlutterBlue {
  static final SoterFlutterBlue _instance =
      Platform.isWindows ? _FlutterBlueWindows() : _FlutterBlueIOSAndroid();

  static SoterFlutterBlue get instance => _instance;

  LogLevel get logLevel;

  Future<bool> get isAvailable;

  Future<bool> get isOn;

  Stream<bool> get isScanning;

  Stream<List<ScanResult>> get scanResults;

  Stream<BluetoothState> get state;

  Future<List<BluetoothDevice>> get connectedDevices;

  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  });
  Future startScan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  });
  Future stopScan();

  Future<bool?> startAdvertising(final Uint8List manufacturerData);
  Future<bool?> stopAdvertising();

  void setLogLevel(LogLevel level);

  void setValueHandler(OnValueChanged? onValueChanged);

  void setServiceHandler(OnServiceDiscovered? onServiceDiscovered);

  void setConnectionHandler(OnConnectionChanged? onConnectionChanged);
}

class _FlutterBlueWindows extends SoterFlutterBlue {
  static const MethodChannel _method = MethodChannel('$PLUGIN_NAME/method');
  static const _eventScanResult = EventChannel('$PLUGIN_NAME/event.scanResult');
  static const _messageConnector = BasicMessageChannel(
      '$PLUGIN_NAME/message.connector', StandardMessageCodec());

  OnConnectionChanged? onConnectionChanged;
  OnServiceDiscovered? onServiceDiscovered;
  OnValueChanged? onValueChanged;

  final StreamController<MethodCall> _methodStreamController =
      StreamController.broadcast(); // ignore: close_sinks
  Stream<MethodCall> get _methodStream => _methodStreamController
      .stream; // Used internally to dispatch methods from platform.

  _FlutterBlueWindows() {
    _method.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
    });

    _messageConnector.setMessageHandler(_handleConnectorMessage);
    _setLogLevelIfAvailable();
  }

  final LogLevel _logLevel = LogLevel.debug;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);

  final BehaviorSubject<List<ScanResult>> _scanResults =
      BehaviorSubject.seeded([]);

  final PublishSubject _stopScanPill = PublishSubject();

  _setLogLevelIfAvailable() async {
    if (await isAvailable) {
      // Send the log level to the underlying platforms.
      setLogLevel(logLevel);
    }
  }

  void _log(LogLevel level, String message) {
    if (level.index <= _logLevel.index) {
      print(message);
    }
  }

  /// todo implement this method properly later
  @override
  Future<bool> get isAvailable async => Future.value(true);

  /// todo this method is used in soter_ble
  @override
  Future<bool> get isOn async =>
      (await _method.invokeMethod('isBluetoothAvailable') ?? false);

  /// todo this method is used in soter_ble
  @override
  Stream<ScanResult> scan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) {
    // todo implement
    return const Stream.empty();
  }

  /// todo this method is used in soter_ble
  @override
  // TODO: implement scanResults
  Stream<List<ScanResult>> get scanResults {
    // todo implement
    return const Stream.empty();
  }

  /// todo this method is used in soter_ble
  @override
  Future<bool?> startAdvertising(Uint8List manufacturerData) {
    // todo implement
    return Future.value(false);
  }

  /// todo this method is used in soter_ble
  @override
  Future startScan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) {
    // todo implement
    return Future.value();
  }

  /// todo this method is used in soter_ble
  @override
  // TODO: implement state
  Stream<BluetoothState> get state {
    // todo implement
    return const Stream.empty();
  }

  /// todo this method is used in soter_ble
  @override
  Future<bool?> stopAdvertising() {
    // todo implement
    return Future.value(false);
  }

  /// todo this method is used in soter_ble
  @override
  Future stopScan() {
    // todo implement
    return Future.value(false);
  }

  @override
  void setLogLevel(LogLevel level) {
    // todo implement
  }

  @override
  LogLevel get logLevel => _logLevel;

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

  // FIXME Close
  final _mtuConfigController = StreamController<int>.broadcast();

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

  /// not used in soter_ble
  @override
  Stream<bool> get isScanning {
    // todo implement
    return _isScanning.stream;
  }

  /// not used in soter_ble
  @override
  // TODO: implement connectedDevices
  Future<List<BluetoothDevice>> get connectedDevices {
    // todo implement
    return Future.value([]);
  }
}

class _FlutterBlueIOSAndroid extends SoterFlutterBlue {
  @override
  LogLevel get logLevel => FlutterBlue.instance.logLevel;

  @override
  Future<bool> get isAvailable => FlutterBlue.instance.isAvailable;

  @override
  Future<bool> get isOn => FlutterBlue.instance.isOn;

  @override
  Stream<bool> get isScanning => FlutterBlue.instance.isScanning;

  @override
  Stream<List<ScanResult>> get scanResults => FlutterBlue.instance.scanResults;

  @override
  Stream<BluetoothState> get state => FlutterBlue.instance.state;

  @override
  Future<List<BluetoothDevice>> get connectedDevices =>
      FlutterBlue.instance.connectedDevices;

  @override
  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  }) =>
      FlutterBlue.instance.scan(
        scanMode: scanMode,
        withServices: withServices,
        withDevices: withDevices,
        timeout: timeout,
        allowDuplicates: allowDuplicates,
      );

  @override
  Future startScan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  }) =>
      FlutterBlue.instance.startScan(
        scanMode: scanMode,
        withServices: withServices,
        withDevices: withDevices,
        timeout: timeout,
        allowDuplicates: allowDuplicates,
      );

  @override
  Future stopScan() => FlutterBlue.instance.stopScan();

  @override
  Future<bool?> startAdvertising(final Uint8List manufacturerData) =>
      FlutterBlue.instance.startAdvertising(manufacturerData);

  @override
  Future<bool?> stopAdvertising() => FlutterBlue.instance.stopAdvertising();

  @override
  void setLogLevel(LogLevel level) => FlutterBlue.instance.setLogLevel(level);

  @override
  void setConnectionHandler(OnConnectionChanged? onConnectionChanged) {
    // TODO: unnecessary method, find other way to remove it
  }

  @override
  void setServiceHandler(OnServiceDiscovered? onServiceDiscovered) {
    // TODO: unnecessary method, find other way to remove it
  }

  @override
  void setValueHandler(OnValueChanged? onValueChanged) {
    // TODO: unnecessary method, find other way to remove it
  }
}
