import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_wearable_source.dart';
import '../services/gait_sensor_pipeline.dart';
import '../models/signal_test_models.dart';

/// Global BLE device state that persists across the entire app lifecycle.
/// Once connected, the device stays connected as user navigates between screens.
class BleDeviceProvider extends ChangeNotifier {
  static final BleDeviceProvider _instance = BleDeviceProvider._internal();
  factory BleDeviceProvider() => _instance;
  BleDeviceProvider._internal();

  BluetoothDevice? _connectedDevice;
  BLEWearableSensorSource? _bleSource;
  String? _connectedDeviceName;
  bool _isConnecting = false;
  bool _isConnected = false;
  int? _batteryPercentage;
  bool _modelReady = false;
  bool _sensorsOK = false;

  StreamSubscription<BluetoothConnectionState>? _connStateSub;
  StreamSubscription<int>? _batterySub;
  StreamSubscription<Map<String, bool>>? _statusSub;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;
  int? get batteryPercentage => _batteryPercentage;
  bool get modelReady => _modelReady;
  bool get sensorsOK => _sensorsOK;
  BLEWearableSensorSource? get bleSource => _bleSource;

  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    notifyListeners();
    try {
      await _cleanupConnection();
      final source = BLEWearableSensorSource(device: device);
      await source.initialize();
      _connectedDevice = device;
      _bleSource = source;
      _connectedDeviceName = device.platformName.isNotEmpty ? device.platformName : 'JointSaathi';
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      final pipeline = GaitSensorPipeline();
      pipeline.setHardwareSource(source);
      pipeline.setSourceType(SignalSourceType.hardware);
      _subscribeToBattery();
      _subscribeToStatus();
      _watchConnectionState();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('BleDeviceProvider: connect error: $e');
      _isConnecting = false;
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts;
    await _cleanupConnection();
    _connectedDeviceName = null;
    notifyListeners();
  }

  Future<void> _cleanupConnection() async {
    _connStateSub?.cancel();
    _batterySub?.cancel();
    _statusSub?.cancel();
    _connStateSub = null;
    _batterySub = null;
    _statusSub = null;
    try { await _bleSource?.dispose(); } catch (_) {}
    final pipeline = GaitSensorPipeline();
    pipeline.setHardwareSource(null);
    pipeline.setSourceType(SignalSourceType.simulated);
    _bleSource = null;
    _connectedDevice = null;
    _isConnected = false;
    _batteryPercentage = null;
    _modelReady = false;
    _sensorsOK = false;
  }

  void _watchConnectionState() {
    final device = _connectedDevice;
    if (device == null) return;
    _connStateSub?.cancel();
    _connStateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _isConnected = false;
        _batteryPercentage = null;
        notifyListeners();
        if (_reconnectAttempts < _maxReconnectAttempts) _scheduleReconnect(device);
      } else if (state == BluetoothConnectionState.connected) {
        _isConnected = true;
        _reconnectAttempts = 0;
        notifyListeners();
      }
    });
  }

  void _scheduleReconnect(BluetoothDevice device) {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_isConnected) return;
      _reconnectAttempts++;
      try {
        await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
        _isConnected = true;
        _reconnectAttempts = 0;
        notifyListeners();
        _watchConnectionState();
        _subscribeToBattery();
        _subscribeToStatus();
      } catch (e) {
        _scheduleReconnect(device);
      }
    });
  }

  void _subscribeToBattery() {
    _batterySub?.cancel();
    _batterySub = _bleSource?.batteryStream.listen((pct) {
      _batteryPercentage = pct;
      notifyListeners();
    });
  }

  void _subscribeToStatus() {
    _statusSub?.cancel();
    _statusSub = _bleSource?.deviceStatusStream.listen((status) {
      _modelReady = status['modelReady'] ?? false;
      _sensorsOK = status['sensorsOK'] ?? false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _connStateSub?.cancel();
    _batterySub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}