import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';

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
}

class _FlutterBlueWindows extends SoterFlutterBlue {
  static const MethodChannel _channel = MethodChannel('$NAMESPACE/methods');
  static const EventChannel _eventChannel = EventChannel('$NAMESPACE/state');
  final StreamController<MethodCall> _methodStreamController =
      StreamController.broadcast(); // ignore: close_sinks
  Stream<MethodCall> get _methodStream => _methodStreamController
      .stream; // Used internally to dispatch methods from platform.

  _FlutterBlueWindows() {
    _channel.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
    });

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

  @override
  Stream<bool> get isScanning {
    // todo implement
    return _isScanning.stream;
  }

  @override
  // TODO: implement connectedDevices
  Future<List<BluetoothDevice>> get connectedDevices {
    // todo implement
    return Future.value([]);
  }

  @override
  // TODO: implement isAvailable
  Future<bool> get isAvailable {
    // todo implement
    return Future.value(false);
  }

  @override
  // TODO: implement isOn
  Future<bool> get isOn {
    // todo implement
    return Future.value(false);
  }

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

  @override
  // TODO: implement scanResults
  Stream<List<ScanResult>> get scanResults {
    // todo implement
    return const Stream.empty();
  }

  @override
  Future<bool?> startAdvertising(Uint8List manufacturerData) {
    // todo implement
    return Future.value(false);
  }

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

  @override
  // TODO: implement state
  Stream<BluetoothState> get state {
    // todo implement
    return const Stream.empty();
  }

  @override
  Future<bool?> stopAdvertising() {
    // todo implement
    return Future.value(false);
  }

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
///
///
///
///
