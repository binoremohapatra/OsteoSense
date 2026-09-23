# ESP32 JointSaathi Firmware Guide

## Overview
यह ESP32 firmware JointSaathi gait analysis app के लिए hardware sensor data provide करता है। यह BLE (Bluetooth Low Energy) के through real-time sensor data send करता है।

## Supported Sensors

| Sensor | Pin | Description | Data Range |
|--------|-----|-------------|------------|
| **Accelerometer** | MPU6050 I2C | 3-axis acceleration (X, Y, Z) | ±2g (scaled x1000) |
| **Gyroscope** | MPU6050 I2C | 3-axis angular velocity (X, Y, Z) | ±250°/s (rad/s x1000) |
| **Piezo** | GPIO 34 | Joint vibration sensor | -1.0 to +1.0 (x1000) |
| **EMG** | GPIO 35 | Muscle activity sensor | 0.0 to +1.0 (x1000) |
| **Battery** | GPIO 33 | Battery voltage monitoring | 0-100% |

## BLE Configuration

### Device Name
- **Name:** `JointSaathi`
- **Advertising:** Device name automatically appears in scan results

### Service UUID
```
4fafc201-1fb5-459e-8fcc-c5c9c331914b
```

### Characteristic UUIDs

| Sensor | UUID | Data Format | Update Rate |
|--------|------|-------------|-------------|
| Accelerometer | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | 6 bytes (int16 x3) | 50 Hz |
| Gyroscope | `beb5483f-36e1-4688-b7f5-ea07361b26a9` | 6 bytes (int16 x3) | 50 Hz |
| Piezo | `beb54840-36e1-4688-b7f5-ea07361b26aa` | 2 bytes (int16) | 50 Hz |
| EMG | `beb54841-36e1-4688-b7f5-ea07361b26ab` | 2 bytes (int16) | 50 Hz |
| Battery | `beb54843-36e1-4688-b7f5-ea07361b26ad` | 2 bytes (int16) | 1 Hz |

## Data Format

### Accelerometer (6 bytes - Little Endian)
```
Byte 0-1: accelX (int16, value x1000)
Byte 2-3: accelY (int16, value x1000)
Byte 4-5: accelZ (int16, value x1000)
```

**Example:**
- accelX = 0.5g → sends 500
- accelY = -0.3g → sends -300
- accelZ = 1.0g → sends 1000

### Gyroscope (6 bytes - Little Endian)
```
Byte 0-1: gyroX (int16, rad/s x1000)
Byte 2-3: gyroY (int16, rad/s x1000)
Byte 4-5: gyroZ (int16, rad/s x1000)
```

**Example:**
- gyroX = 0.1 rad/s → sends 100
- gyroY = -0.05 rad/s → sends -50
- gyroZ = 0.2 rad/s → sends 200

### Piezo (2 bytes - Little Endian)
```
Byte 0-1: piezoValue (int16, value x1000)
```

**Range:** -1000 to +1000 (represents -1.0 to +1.0)
- DC removal applied in hardware/firmware
- AC signal amplified x10 for graph visibility

### EMG (2 bytes - Little Endian)
```
Byte 0-1: emgValue (int16, value x1000)
```

**Range:** 0 to 1000 (represents 0.0 to 1.0)
- DC removal applied in hardware/firmware
- AC signal amplified x10 for graph visibility

### Battery (2 bytes - Little Endian)
```
Byte 0-1: batteryPercentage (int16, percentage 0-100)
```

**Range:** 0 to 100 (represents 0% to 100%)
- Battery voltage: 3.0V = 0%, 3.3V = 100%
- Linear scaling: percentage = ((voltage - 3.0) / 0.3) * 100
- Clamped to 0-100 range

## Sampling Rate
- **Rate:** 50 Hz (20ms delay between samples)
- **Buffer:** No local buffering - real-time streaming
- **Latency:** <50ms from sensor read to BLE notification

## Connection Handling

### Auto-Reconnect
```
- When device disconnects: Automatically restarts advertising
- Reconnect logic: Handled by Flutter app (BLE scanner)
- Connection timeout: None (persistent connection)
```

### Connection Callbacks
```cpp
void onConnect(BLEServer* pServer) {
  deviceConnected = true;
  // Start sending sensor data
}

void onDisconnect(BLEServer* pServer) {
  deviceConnected = false;
  BLEDevice::startAdvertising(); // Restart advertising
}
```

## Hardware Requirements

### ESP32 Board
- ESP32 DevKit or similar
- ESP32-WROOM32 or ESP32-WROVER
- USB power supply (5V, 500mA minimum)

### Sensors
- **MPU6050** (IMU sensor with accelerometer + gyroscope)
  - I2C interface
  - 3.3V or 5V compatible
  - Built-in 16-bit ADC

- **Piezo Sensor** (Joint vibration)
  - Analog output
  - 0-3.3V range
  - Requires voltage divider for ESP32

- **EMG Sensor** (Muscle activity)
  - Analog output
  - 0-3.3V range
  - Requires amplifier circuit

- **Battery Monitoring** (Li-ion/LiPo battery)
  - Voltage divider required (if battery > 3.3V)
  - 3.0V = 0%, 3.3V = 100%
  - Connect voltage divider output to GPIO 33

### Pin Connections

| ESP32 Pin | Sensor | Notes |
|-----------|--------|-------|
| GPIO 21 (SDA) | MPU6050 SDA | I2C Data |
| GPIO 22 (SCL) | MPU6050 SCL | I2C Clock |
| GPIO 34 | Piezo | Analog input (ADC1_CH6) |
| GPIO 35 | EMG | Analog input (ADC1_CH7) |
| GPIO 33 | Battery | Analog input (ADC1_CH5) |
| GPIO 25 | DAC Output | For piezo signal output |
| 3.3V | Sensors | Power supply |
| GND | Sensors | Ground |

## Installation

### Prerequisites
1. Arduino IDE 1.8.x or 2.x
2. ESP32 Board Support Package
3. Required Libraries:
   - Wire (I2C)
   - MPU6050
   - BLEDevice (ESP32 BLE)

### Upload Steps
1. Open `ESP32_FIRMWARE.ino` in Arduino IDE
2. Select Board: ESP32 Dev Module
3. Select Port: COM port of ESP32
4. Click Upload
5. Monitor Serial Output (115200 baud)

### Expected Serial Output
```
BLE Address: aa:bb:cc:dd:ee:ff
BLE advertising started - Device name: JointSaathi
MPU6050 connected
Accel: 100, -50, 9800
Gyro: 10, -5, 20
Piezo: 2048 Amp: 10
EMG: 512
Battery: 3.15V (50%)
```

## Testing

### Mobile App Testing
1. Open JointSaathi Flutter app
2. Go to Gait Test screen
3. Select "Hardware" mode
4. Tap "Connect ESP32 Device"
5. Select "JointSaathi" from BLE scan list
6. Verify connection status
7. Start recording
8. Check sensor graphs (Accel, Gyro, Piezo, EMG)

### Serial Monitor Testing
- Open Arduino Serial Monitor (115200 baud)
- Verify sensor readings update every 20ms
- Check for "MPU6050 connected" message
- Verify BLE advertising started

### LED Indicators (Optional)
- Add LED on GPIO 2 for connection status
- ON when connected, OFF when disconnected

## Troubleshooting

### Device Not Scanning
- **Issue:** ESP32 not visible in BLE scan
- **Solution:**
  - Check ESP32 power supply
  - Verify BLE advertising started (Serial output)
  - Restart ESP32
  - Check BLE permissions on phone

### Sensor Data Not Updating
- **Issue:** Graphs show flat lines or no data
- **Solution:**
  - Check sensor wiring
  - Verify MPU6050 I2C connection
  - Check analog sensor power supply
  - Verify characteristic notifications enabled

### Connection Drops
- **Issue:** Frequent disconnections
- **Solution:**
  - Reduce sampling rate (increase delay)
  - Check BLE signal strength
  - Verify BLE MTU size (request 512)
  - Check phone BLE compatibility

### Wrong Data Values
- **Issue:** Sensor values out of range
- **Solution:**
  - Check voltage divider for analog sensors
  - Verify ADC calibration
  - Check scaling factors in firmware
  - Verify data format in Flutter app

## Power Consumption

### Active Mode (Connected + Streaming)
- **Current:** ~50-80mA
- **Voltage:** 3.3V
- **Power:** ~165-264mW

### Idle Mode (Advertising only)
- **Current:** ~15-20mA
- **Voltage:** 3.3V
- **Power:** ~50-66mW

### Deep Sleep (Optional)
- **Current:** ~0.1-10mA
- **Voltage:** 3.3V
- **Power:** ~0.3-33mW

## Future Enhancements

1. **Battery Monitoring**
   - Add voltage divider for battery level
   - Send battery % via BLE characteristic

2. **Data Logging**
   - Add SD card module
   - Log sensor data locally
   - Sync with app on demand

3. **Sensor Calibration**
   - Add calibration mode
   - Store calibration values in EEPROM
   - Auto-calibrate on startup

4. **Multiple Sensors**
   - Support multiple FSR sensors (left/right foot)
   - Add more EMG channels
   - Support additional IMU sensors

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-09-18 | Initial release with Accel, Gyro, Piezo, EMG |
| 1.1 | 2024-09-22 | Added battery monitoring (3.0V-3.3V range, 0-100% display) |

## License
MIT License - JointSaathi Project

## Support
For issues or questions, contact:
- GitHub: https://github.com/binoremohapatra/OsteoSense
- Email: support@jointsaathi.com
