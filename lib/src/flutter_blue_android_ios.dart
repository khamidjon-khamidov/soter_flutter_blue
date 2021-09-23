part of soter_flutter_blue;

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
  Stream<List<SoterBlueScanResult>> get scanResults =>
      FlutterBlue.instance.scanResults.map((List<ScanResult> results) => results
          .map((result) => SoterBlueScanResult.fromFlutterBlue(result))
          .toList());

  @override
  Stream<BluetoothState> get state => FlutterBlue.instance.state;

  @override
  Future<List<BluetoothDevice>> get connectedDevices =>
      FlutterBlue.instance.connectedDevices;

  @override
  Stream<SoterBlueScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  }) =>
      FlutterBlue.instance
          .scan(
            scanMode: scanMode,
            withServices: withServices,
            withDevices: withDevices,
            timeout: timeout,
            allowDuplicates: allowDuplicates,
          )
          .map((result) => SoterBlueScanResult.fromFlutterBlue(result));

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
