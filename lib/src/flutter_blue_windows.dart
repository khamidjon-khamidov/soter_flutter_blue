part of soter_flutter_blue;

class _FlutterBlueWindows extends SoterFlutterBlue {
  static const MethodChannel _method = MethodChannel('$PLUGIN_NAME/method');
  static const _eventScanResult = EventChannel('$PLUGIN_NAME/event.scanResult');

  // used to get messages from windows
  static final StreamController<Map> _messageStreamController =
      StreamController.broadcast(); // ignore: close_sinks
  static Stream<Map> get _messageStream => _messageStreamController.stream;

  static const _messageConnector = BasicMessageChannel(
      '$PLUGIN_NAME/message.connector', StandardMessageCodec());
  static const DEFAULT_MTU = 20;

  final StreamController<MethodCall> _methodStreamController =
      StreamController.broadcast(); // ignore: close_sinks
  Stream<MethodCall> get _methodStream => _methodStreamController
      .stream; // Used internally to dispatch methods from platform.

  _FlutterBlueWindows() {
    _method.setMethodCallHandler((MethodCall call) async {
      print('SoterFlutterBlue: got new message: call');
      _methodStreamController.add(call);
    });

    _messageConnector.setMessageHandler(
        (dynamic message) async => _messageStreamController.add(message));
    _setLogLevelIfAvailable();
  }

  final LogLevel _logLevel = LogLevel.debug;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);

  final BehaviorSubject<List<SoterBlueScanResult>> _scanResults =
      BehaviorSubject.seeded([]);

  @override
  Stream<List<SoterBlueScanResult>> get scanResults => _scanResults.stream;

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
  LogLevel get logLevel => _logLevel;

  /// todo implement this method properly later
  @override
  Future<bool> get isAvailable async => Future.value(true);

  @override
  Future<bool> get isOn async =>
      (await _method.invokeMethod('isBluetoothAvailable') ?? false);

  @override
  Stream<SoterBlueScanResult> scan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) async* {
    if (_isScanning.value == true) {
      throw Exception('Another scan is already in progress.');
    }

    // Emit to isScanning
    _isScanning.add(true);

    final killStreams = <Stream>[];
    killStreams.add(_stopScanPill);
    if (timeout != null) {
      killStreams.add(Rx.timer(null, timeout));
    }

    // Clear scan results list
    _scanResults.add(<SoterBlueScanResult>[]);

    try {
      await _method.invokeMethod('startScan');
      print('startScan invokeMethod success');
    } catch (e) {
      print('Error starting scan.');
      _stopScanPill.add(null);
      _isScanning.add(false);
      throw e;
    }

    yield* _eventScanResult
        .receiveBroadcastStream({'name': 'scanResult'})
        .map((item) => SoterBlueScanResult.fromMap(item))
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(stopScan)
        .map((result) {
          final List<SoterBlueScanResult> list = _scanResults.value ?? [];
          int index = list.indexOf(result);
          if (index != -1) {
            list[index] = result;
          } else {
            list.add(result);
          }
          _scanResults.add(list);
          return result;
        });
  }

  @override
  Future startScan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Guid> withServices = const [],
      List<Guid> withDevices = const [],
      Duration? timeout,
      bool allowDuplicates = false}) async {
    await scan(
            scanMode: scanMode,
            withServices: withServices,
            withDevices: withDevices,
            timeout: timeout,
            allowDuplicates: allowDuplicates)
        .drain();
    return _scanResults.value;
  }

  @override
  Future stopScan() async {
    await _method.invokeMethod('stopScan');
    print('stopScan invokeMethod success');
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    await _method.invokeMethod('requestMtu', {
      'deviceId': deviceId,
      'expectedMtu': expectedMtu,
    });
    print('requestMtu invokeMethod success');
    return _messageStream
        .where((m) => m['mtuConfig'] != null)
        .map((m) => m['mtuConfig'] as int)
        .first;
  }

  @override
  Future<List<SoterBluetoothDevice>> get connectedDevices async {
    List devices = await _method.invokeMethod('connectedDevices');
    List<SoterBluetoothDevice> result = [];
    print('SoterFlutterBlue: got connected devices: count: ${devices.length}');
    for (var device in devices) {
      result.add(SoterBluetoothDevice(
        device['name'],
        device['deviceId'],
        null,
      ));
    }
    return result;
  }

  //////////////////// NOT USED INSIDE THE PROJECT FOR NOW //////////////

  @override
  void setLogLevel(LogLevel level) {
    // todo implement
  }

  @override
  Stream<BluetoothState> get state {
    // todo implement
    return const Stream.empty();
  }

  @override
  Future<bool?> startAdvertising(Uint8List manufacturerData) {
    // todo implement
    return Future.value(false);
  }

  @override
  Future<bool?> stopAdvertising() {
    // todo implement
    return Future.value(false);
  }

  @override
  Stream<bool> get isScanning {
    // todo implement
    return _isScanning.stream;
  }
}
