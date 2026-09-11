import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'sensor_data_source.dart';

/// BLE wearable device sensor data source
/// Template for integrating external Bluetooth wearables (e.g., smartwatch, accelerometer bracelet)
/// Supports ESP32-based OA wearable with: MPU6050 (accel+gyro), Piezo (joint vibration), EMG (muscle activity)
class BLEWearableSensorSource implements SensorDataSource {
  // Exact UUIDs matching ESP32 firmware
  static const String _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String _accelCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String _gyroCharUuid = 'beb5483f-36e1-4688-b7f5-ea07361b26a9';
  static const String _piezoCharUuid = 'beb54840-36e1-4688-b7f5-ea07361b26aa';
  static const String _emgCharUuid = 'beb54841-36e1-4688-b7f5-ea07361b26ab';

  final BluetoothDevice device;
  BluetoothCharacteristic? _accelCharacteristic;
  BluetoothCharacteristic? _gyroCharacteristic;
  BluetoothCharacteristic? _piezoCharacteristic;
  BluetoothCharacteristic? _emgCharacteristic;

  StreamSubscription<List<int>>? _accelSubscription;
  StreamSubscription<List<int>>? _gyroSubscription;
  StreamSubscription<List<int>>? _piezoSubscription;
  StreamSubscription<List<int>>? _emgSubscription;

  final StreamController<SensorData> _accelerometerController =
      StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _gyroscopeController =
      StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _piezoController =
      StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _emgController =
      StreamController<SensorData>.broadcast();

  bool _isConnected = false;
  bool _isRecording = false;

  BLEWearableSensorSource({required this.device});

  @override
  Stream<SensorData> get accelerometerStream =>
      _accelerometerController.stream;

  @override
  Stream<SensorData> get gyroscopeStream => _gyroscopeController.stream;

  /// Additional streams for ESP32 wearable sensors
  Stream<SensorData> get piezoStream => _piezoController.stream;
  Stream<SensorData> get emgStream => _emgController.stream;

  @override
  String get deviceName => device.platformName;

  @override
  bool get isConnected => _isConnected;

  /// Initialize BLE connection and discover sensor services
  @override
  Future<void> initialize() async {
    try {
      // Connect to BLE device
      await device.connect();
      _isConnected = true;

      // Discover services and characteristics
      final services = await device.discoverServices();

      // Look for our specific service UUID
      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();

        // Check if this is our JointSaathi service
        if (serviceUuid.contains(_serviceUuid.toLowerCase()) ||
            serviceUuid.contains('4fafc201')) {
          print('Found JointSaathi service: $serviceUuid');

          // Discover characteristics
          for (final characteristic in service.characteristics) {
            final uuid = characteristic.uuid.toString().toLowerCase();

            // Exact UUID matching for ESP32 JointSaathi wearable
            if (uuid.contains(_accelCharUuid.toLowerCase())) {
              _accelCharacteristic = characteristic;
              print('Found accelerometer characteristic: $uuid');
            }
            if (uuid.contains(_gyroCharUuid.toLowerCase())) {
              _gyroCharacteristic = characteristic;
              print('Found gyroscope characteristic: $uuid');
            }
            if (uuid.contains(_piezoCharUuid.toLowerCase())) {
              _piezoCharacteristic = characteristic;
              print('Found piezo characteristic: $uuid');
            }
            if (uuid.contains(_emgCharUuid.toLowerCase())) {
              _emgCharacteristic = characteristic;
              print('Found EMG characteristic: $uuid');
            }
          }
        }
      }

      // At minimum, need accelerometer and gyroscope
      if (_accelCharacteristic == null || _gyroCharacteristic == null) {
        throw Exception('Required IMU characteristics not found on device. '
            'Make sure ESP32 firmware uses correct UUIDs.');
      }

      print('BLE initialization successful. Sensors: Accel=${_accelCharacteristic != null}, '
            'Gyro=${_gyroCharacteristic != null}, Piezo=${_piezoCharacteristic != null}, '
            'EMG=${_emgCharacteristic != null}');
    } catch (e) {
      print('BLE initialization error: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Start receiving sensor data from wearable
  @override
  Future<void> startRecording() async {
    if (!_isConnected) {
      throw Exception('Device not connected');
    }

    _isRecording = true;

    // Enable notifications on accelerometer characteristic
    if (_accelCharacteristic != null) {
      await _accelCharacteristic!.setNotifyValue(true);
      _accelSubscription = _accelCharacteristic!.onValueReceived.listen(
        (value) {
          if (_isRecording) {
            _parseAccelerometerData(value);
          }
        },
        onError: (error) => print('Accelerometer stream error: $error'),
      );
    }

    // Enable notifications on gyroscope characteristic
    if (_gyroCharacteristic != null) {
      await _gyroCharacteristic!.setNotifyValue(true);
      _gyroSubscription = _gyroCharacteristic!.onValueReceived.listen(
        (value) {
          if (_isRecording) {
            _parseGyroscopeData(value);
          }
        },
        onError: (error) => print('Gyroscope stream error: $error'),
      );
    }

    // Enable notifications on piezo characteristic (joint vibration)
    if (_piezoCharacteristic != null) {
      await _piezoCharacteristic!.setNotifyValue(true);
      _piezoSubscription = _piezoCharacteristic!.onValueReceived.listen(
        (value) {
          if (_isRecording) {
            _parsePiezoData(value);
          }
        },
        onError: (error) => print('Piezo stream error: $error'),
      );
    }

    // Enable notifications on EMG characteristic (muscle activity)
    if (_emgCharacteristic != null) {
      await _emgCharacteristic!.setNotifyValue(true);
      _emgSubscription = _emgCharacteristic!.onValueReceived.listen(
        (value) {
          if (_isRecording) {
            _parseEMGData(value);
          }
        },
        onError: (error) => print('EMG stream error: $error'),
      );
    }

    print('Started recording from all available sensors');
  }

  /// Stop receiving sensor data
  @override
  Future<void> stopRecording() async {
    _isRecording = false;

    if (_accelCharacteristic != null) {
      await _accelCharacteristic!.setNotifyValue(false);
    }
    if (_gyroCharacteristic != null) {
      await _gyroCharacteristic!.setNotifyValue(false);
    }
    if (_piezoCharacteristic != null) {
      await _piezoCharacteristic!.setNotifyValue(false);
    }
    if (_emgCharacteristic != null) {
      await _emgCharacteristic!.setNotifyValue(false);
    }

    await _accelSubscription?.cancel();
    await _gyroSubscription?.cancel();
    await _piezoSubscription?.cancel();
    await _emgSubscription?.cancel();

    print('Stopped recording from all sensors');
  }

  /// Cleanup and disconnect from wearable
  @override
  Future<void> dispose() async {
    await stopRecording();
    await device.disconnect();
    await _accelerometerController.close();
    await _gyroscopeController.close();
    await _piezoController.close();
    await _emgController.close();
    _isConnected = false;
  }

  /// Parse accelerometer data from BLE packet
  /// ESP32 wearable format: 6 bytes (2 bytes per axis, little-endian)
  void _parseAccelerometerData(List<int> data) {
    try {
      if (data.length < 6) return;

      final x = _bytesToInt16(data, 0) / 1000.0; // Convert to g-force
      final y = _bytesToInt16(data, 2) / 1000.0;
      final z = _bytesToInt16(data, 4) / 1000.0;

      _accelerometerController.add(
        SensorData(
          x: x,
          y: y,
          z: z,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error parsing accelerometer data: $e');
    }
  }

  /// Parse gyroscope data from BLE packet
  /// ESP32 wearable format: 6 bytes (2 bytes per axis, little-endian)
  void _parseGyroscopeData(List<int> data) {
    try {
      if (data.length < 6) return;

      final x = _bytesToInt16(data, 0) / 1000.0; // Convert to rad/s
      final y = _bytesToInt16(data, 2) / 1000.0;
      final z = _bytesToInt16(data, 4) / 1000.0;

      _gyroscopeController.add(
        SensorData(
          x: x,
          y: y,
          z: z,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error parsing gyroscope data: $e');
    }
  }

  /// Parse piezo (joint vibration) data from BLE packet
  /// ESP32 wearable format: 2 bytes (little-endian)
  void _parsePiezoData(List<int> data) {
    try {
      if (data.length < 2) return;

      final vibration = _bytesToInt16(data, 0) / 1000.0; // Normalized vibration value

      _piezoController.add(
        SensorData(
          x: vibration, // Use single value as x-axis
          y: 0,
          z: 0,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error parsing piezo data: $e');
    }
  }

  /// Parse EMG (muscle activity) data from BLE packet
  /// ESP32 wearable format: 2 bytes (little-endian)
  void _parseEMGData(List<int> data) {
    try {
      if (data.length < 2) return;

      final muscleActivity = _bytesToInt16(data, 0) / 1000.0; // Normalized EMG value

      _emgController.add(
        SensorData(
          x: muscleActivity, // Use single value as x-axis
          y: 0,
          z: 0,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error parsing EMG data: $e');
    }
  }

  /// Helper: Convert 2 bytes to signed 16-bit integer (little-endian)
  int _bytesToInt16(List<int> data, int offset) {
    int value = data[offset] | (data[offset + 1] << 8);
    if (value & 0x8000 != 0) {
      value -= 0x10000;
    }
    return value;
  }
}
