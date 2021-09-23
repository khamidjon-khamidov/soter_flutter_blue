part of soter_flutter_blue;

typedef OnConnectionChanged = void Function(
    String deviceId, BlueConnectionState state);

typedef OnServiceDiscovered = void Function(String deviceId, String serviceId);

typedef OnValueChanged = void Function(
    String deviceId, String characteristicId, Uint8List value);

class _FlutterBlueWindows extends SoterFlutterBlue {
  static const MethodChannel _method = MethodChannel('$PLUGIN_NAME/method');
  static const _eventScanResult = EventChannel('$PLUGIN_NAME/event.scanResult');
  static const _messageConnector = BasicMessageChannel(
      '$PLUGIN_NAME/message.connector', StandardMessageCodec());
  static const DEFAULT_MTU = 20;

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
      _method
          .invokeMethod('startScan')
          .then((_) => print('startScan invokeMethod success'));
    } catch (e) {
      print('Error starting scan.');
      _stopScanPill.add(null);
      _isScanning.add(false);
      throw e;
    }

    yield* _eventScanResult
        .receiveBroadcastStream({'name': 'scanResult'})
        .map((item) => BlueScanResult.fromMap(item))
        .map((p) {
          final result = SoterBlueScanResult.fromQuickBlueScanResult(p);
          final list = _scanResults.value ?? [];
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

  /// todo implement this
  @override
  Future<bool?> startAdvertising(Uint8List manufacturerData) {
    // todo implement
    return Future.value(false);
  }

  /// todo implement this
  @override
  Stream<BluetoothState> get state {
    // todo implement
    return const Stream.empty();
  }

  /// todo implement this
  @override
  Future<bool?> stopAdvertising() {
    // todo implement
    return Future.value(false);
  }

  @override
  Future stopScan() async {
    await _method.invokeMethod('stopScan');
    print('stopScan invokeMethod success');
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  @override
  void setLogLevel(LogLevel level) {
    // todo implement
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

  // FIXME Close
  final _mtuConfigController = StreamController<int>.broadcast();

  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    _method.invokeMethod('requestMtu', {
      'deviceId': deviceId,
      'expectedMtu': expectedMtu,
    }).then((_) => print('requestMtu invokeMethod success'));
    return await _mtuConfigController.stream.first;
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
