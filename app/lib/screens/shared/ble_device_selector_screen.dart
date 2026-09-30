import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/index.dart';
import '../../services/ble_wearable_source.dart';
import '../../services/gait_sensor_pipeline.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_device_provider.dart';
import '../../models/signal_test_models.dart';

class BLEDeviceSelectorScreen extends StatefulWidget {
  const BLEDeviceSelectorScreen({super.key});

  @override
  State<BLEDeviceSelectorScreen> createState() => _BLEDeviceSelectorScreenState();
}

class _BLEDeviceSelectorScreenState extends State<BLEDeviceSelectorScreen> {
  final List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  static const String _targetServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String _targetDeviceName = 'JointSaathi';

  // BUG FIX: Save subscriptions so we can cancel before re-subscribing.
  // Without this, every _startScan() call adds a NEW listener to BLE streams
  // causing race conditions that made the device list appear empty on 2nd scan.
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    // Cancel old listeners before creating new ones.
    // Without this, every tap on Refresh adds ANOTHER listener to the same
    // BLE stream. Multiple listeners then call setState with _scanResults.clear()
    // and addAll in competing order, causing the list to stay empty on 2nd scan.
    await _scanResultsSubscription?.cancel();
    await _isScanningSubscription?.cancel();
    _scanResultsSubscription = null;
    _isScanningSubscription = null;

    if (mounted) {
      setState(() {
        _isScanning = true;
        _scanResults.clear();
      });
    }

    try {
      // Stop any ongoing scan first to ensure a clean BLE stack state
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Listen BEFORE starting the scan - save subscription references
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults.clear();
            // Filter: show only JointSaathi devices OR devices with our Service UUID
            _scanResults.addAll(results.where((r) {
              final name = r.device.platformName.toLowerCase();
              final hasTargetName = name == _targetDeviceName.toLowerCase();
              final hasTargetUuid = r.advertisementData.serviceUuids
                  .any((uuid) => uuid.toString().toLowerCase() == _targetServiceUuid.toLowerCase());
              // Show ONLY if exact name matches OR exact UUID matches
              return hasTargetName || hasTargetUuid;
            }));
          });
        }
      });

      // Also listen to the isScanning stream so UI updates when timeout hits
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        if (mounted) {
          setState(() => _isScanning = isScanning);
        }
      });

      // Scan without hardware filter for maximum compatibility (we filter in software above)
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      print('Error starting scan: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start scan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopScan() async {
    if (mounted) setState(() => _isScanning = false);
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      // Use global BleDeviceProvider so connection persists across all screens
      final bleProvider = Provider.of<BleDeviceProvider>(context, listen: false);
      final success = await bleProvider.connectToDevice(device);
      if (success && mounted) {
        setState(() => _connectedDevice = device);
        final name = device.platformName.isNotEmpty ? device.platformName : 'JointSaathi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $name'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, name);
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_connect'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_connect'.tr() + ': $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connect ESP32 Device',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _scanResults.isEmpty
          ? _buildEmptyState()
          : _buildDeviceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _isScanning ? 'Scanning for devices...' : 'No devices found',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isScanning
                ? 'Make sure your ESP32 device is powered on and nearby'
                : 'Tap refresh to scan again',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!_isScanning)
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: Text('scan_again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingLg),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        return _buildDeviceCard(result, index);
      },
    );
  }

  Widget _buildDeviceCard(ScanResult result, int index) {
    final device = result.device;
    final isConnected = _connectedDevice?.remoteId == device.remoteId;
    final displayName = device.platformName.isNotEmpty
        ? device.platformName
        : (result.advertisementData.advName.isNotEmpty
            ? result.advertisementData.advName
            : 'JointSaathi Device');
    final rssi = result.rssi;
    final signalStrength = rssi > -60 ? '🟢 Strong' : (rssi > -80 ? '🟡 Good' : '🔴 Weak');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isConnected
            ? Border.all(color: Colors.green, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isConnected ? null : () => _connectToDevice(device),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Bluetooth icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? Colors.green : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isConnected) ...
                          [
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Connected',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.remoteId}  $signalStrength ($rssi dBm)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Connection status
              if (isConnected)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else if (_isConnecting)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ))
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(
      begin: 0.1,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }
}
