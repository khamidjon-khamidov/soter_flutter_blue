part of soter_flutter_blue;

abstract class SoterFlutterBlue {
  static final SoterFlutterBlue _instance =
      Platform.isWindows ? _FlutterBlueWindows() : _FlutterBlueIOSAndroid();

  static SoterFlutterBlue get instance => _instance;

  LogLevel get logLevel;

  Future<bool> get isAvailable;

  Future<bool> get isOn;

  Stream<bool> get isScanning;

  Stream<List<SoterBlueScanResult>> get scanResults;

  Stream<BluetoothState> get state;

  Future<List<BluetoothDevice>> get connectedDevices;

  Stream<SoterBlueScanResult> scan({
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
