# Hardware & Firmware Requirements Document
## ESP32 Wearable Device for JointSaathi Flutter App

**Version:** 1.0  
**Purpose:** Complete guide for hardware team to build ESP32 device that connects to Flutter app

---

## 📋 PROJECT OVERVIEW

**Goal:** Build ESP32-based wearable device for OA (Osteoarthritis) screening that connects to Flutter app via Bluetooth

**What the Device Does:**
- Worn on knee joint using adjustable strap
- Collects sensor data from 4 sensors during walking
- Sends real-time data to Flutter app via Bluetooth
- Battery-powered, rechargeable via USB-C
- No buttons required - fully automatic BLE connection

---

## 🔧 HARDWARE COMPONENTS REQUIRED

### 1. Main Components
| Component | Quantity | Purpose | Notes |
|-----------|----------|---------|-------|
| ESP32-WROOM-32 | 1 | Main microcontroller | Built-in BLE, WiFi, processing |
| MPU6050 Sensor | 1 | Accelerometer + Gyroscope | I2C interface, for gait analysis |
| Piezo Disc | 1 | Joint vibration sensor | 10-20mm diameter, analog output |
| EMG Module | 1 | Muscle activity sensor | With amplification circuit |
| LiPo Battery | 1 | Power source | 500-1000mAh, 3.7V |
| USB-C Charging Module | 1 | Battery charging | With protection circuit |
| 3.3V LDO Regulator | 1 | Voltage regulation | For sensors |
| Status LEDs | 3 | User feedback | Red (power), Green (connection), Blue (recording) |
| Elastic Strap | 1 | Knee attachment | Adjustable, breathable |
| Enclosure | 1 | Device housing | Small, lightweight, IP54 |

### 2. Additional Components
| Component | Purpose | Notes |
|-----------|---------|-------|
| 10kΩ Resistors | Pull-up resistors | For I2C lines |
| 0.1µF Capacitors | Decoupling | For power supply |
| Reset Button | Manual reset | Optional, GPIO0 |
| Piezo Amplifier | Signal conditioning | If piezo output is weak |
| EMG Bandpass Filter | Signal conditioning | 20-500Hz filter |

---

## 🔌 CIRCUIT DESIGN

### 1. Power Circuit
```
USB-C Charging Module
    ↓
LiPo Battery (3.7V)
    ↓
ESP32 VIN (3.3V regulated)
    ↓
3.3V LDO Regulator
    ↓
All Sensors (3.3V)
```

### 2. MPU6050 I2C Connection
```
ESP32          MPU6050
------         -------
GPIO21 ---- SDA
GPIO22 ---- SCL
3.3V  ---- VCC
GND   ---- GND
10kΩ ---- SDA to 3.3V (pull-up)
10kΩ ---- SCL to 3.3V (pull-up)
```

### 3. Piezo Sensor Circuit
```
Piezo Disc
    ↓
Amplifier Circuit (optional)
    ↓
ADC GPIO34
    ↓
ESP32 ADC (12-bit, 0-3.3V)
```

### 4. LED Indicators
```
GPIO2 ---- Red LED ---- Power (always on when powered)
GPIO4 ---- Green LED ---- Connection (on when BLE connected)
GPIO5 ---- Blue LED ---- Recording (blinks when sending data)
All LEDs ---- 220Ω resistor ---- GND
```

---

## 📡 BLUETOOTH LOW ENERGY (BLE) CONFIGURATION

### CRITICAL: Must Use These Exact UUIDs

### Service UUID
```
Primary Service UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b
```

### Characteristic UUIDs
```
Accelerometer: beb5483e-36e1-4688-b7f5-ea07361b26a8
Gyroscope:      beb5483f-36e1-4688-b7f5-ea07361b26a9
Piezo:          beb54840-36e1-4688-b7f5-ea07361b26aa
EMG:            beb54841-36e1-4688-b7f5-ea07361b26ab
```

### Device Name
```
BLE Device Name: "JointSaathi_Wearable"
```

### BLE Configuration Parameters
```
Advertising: Connectable Undirected
Power Level: Maximum (ESP_PWR_LVL_P7)
MTU Size: 517 bytes
Connection Interval: 20ms minimum
Slave Latency: 0ms
Appearance: Generic Watch (0x0042)
```

---

## 📊 DATA FORMAT SPECIFICATIONS

### CRITICAL: Must Follow Exact Data Format

### Data Format Rules
- **Byte Order:** Little-endian (LSB first)
- **Data Type:** Signed 16-bit integers (int16)
- **Scaling:** Multiply float by 1000, convert to int16
- **Format:** Fixed packet size per sensor

### Accelerometer Data (6 bytes)
```
Byte 0-1: X-axis (int16, ×1000)
Byte 2-3: Y-axis (int16, ×1000)
Byte 4-5: Z-axis (int16, ×1000)

Example: X=0.5g → 500 → [0xF4, 0x01]
Range: ±2g (-2000 to +2000)
```

### Gyroscope Data (6 bytes)
```
Byte 0-1: X-axis (int16, ×1000)
Byte 2-3: Y-axis (int16, ×1000)
Byte 4-5: Z-axis (int16, ×1000)

Example: X=0.2°/s → 200 → [0xC8, 0x00]
Range: ±250°/s
```

### Piezo Data (2 bytes)
```
Byte 0-1: Vibration value (int16, ×1000)

Example: Vibration=0.5 → 500 → [0xF4, 0x01]
Range: -1.0 to +1.0 normalized
```

### EMG Data (2 bytes)
```
Byte 0-1: Muscle activity (int16, ×1000)

Example: Activity=0.8 → 800 → [0x20, 0x03]
Range: 0.0 to +1.0 normalized
```

---

## ⚙️ SENSOR CONFIGURATION

### MPU6050 Settings
```
I2C Address: 0x68
I2C Pins: SDA=GPIO21, SCL=GPIO22
Clock Speed: 400kHz
Accel Range: ±2g (sensitive for walking)
Gyro Range: ±250°/s (sensitive for joint movement)
Sample Rate: 50Hz
Digital Low Pass Filter: Enabled (44Hz cutoff)
Wake-on-Motion: Enabled
```

### ADC Configuration
```
ADC Resolution: 12-bit (0-4095)
Piezo Pin: GPIO34 (ADC1_CH6)
EMG Pin: GPIO35 (ADC1_CH7)
Sampling Rate: 50Hz (synchronized with MPU6050)
Voltage Range: 0-3.3V
```

---

## 💻 ESP32 FIRMWARE CODE STRUCTURE

### Required Libraries
```cpp
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <MPU6050.h>
```

### Setup Function
```cpp
void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(POWER_LED, OUTPUT);
  pinMode(CONNECTION_LED, OUTPUT);
  pinMode(RECORDING_LED, OUTPUT);
  pinMode(PIEZO_PIN, INPUT);
  pinMode(EMG_PIN, INPUT);
  
  digitalWrite(POWER_LED, HIGH); // Power on
  
  // Initialize MPU6050
  Wire.begin();
  mpu.initialize();
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_2);
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_250);
  
  // Initialize BLE
  initBLE();
  
  Serial.println("JointSaathi Wearable Ready");
}
```

### BLE Initialization
```cpp
void initBLE() {
  BLEDevice::init("JointSaathi_Wearable");
  BLEDevice::setPower(ESP_PWR_LVL_P7);
  
  pServer = BLEDevice::createServer();
  BLEService* pService = pServer->createService(SERVICE_UUID);
  
  // Create characteristics
  pAccelCharacteristic = pService->createCharacteristic(
    ACCEL_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  // Add notification descriptors
  pAccelCharacteristic->addDescriptor(new BLE2902());
  
  // Repeat for gyro, piezo, EMG
  
  pService->start();
  
  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  BLEDevice::startAdvertising();
}
```

### Main Loop
```cpp
void loop() {
  if (isRecording && isConnected) {
    // Sample at 50Hz
    if (millis() - lastSampleTime >= 20) {
      lastSampleTime = millis();
      readAndSendSensors();
    }
  }
}
```

---

## 🚀 STEP-BY-STEP INTEGRATION GUIDE

### Phase 1: Hardware Assembly
1. **Step 1:** Solder ESP32 to PCB
2. **Step 2:** Connect MPU6050 via I2C
3. **Step 3:** Connect piezo sensor to ADC
4. **Step 4:** Connect EMG sensor to ADC
5. **Step 5:** Connect LEDs with resistors
6. **Step 6:** Connect charging circuit
7. **Step 7:** Test power consumption
8. **Step 8:** Mount in enclosure with strap

### Phase 2: Firmware Upload
1. **Step 1:** Install Arduino IDE or PlatformIO
2. **Step 2:** Install required libraries (BLE, MPU6050)
3. **Step 3:** Copy firmware code to IDE
4. **Step 4:** Select ESP32 board and port
5. **Step 5:** Upload firmware
6. **Step 6:** Open Serial Monitor (115200 baud)
7. **Step 7:** Verify "JointSaathi Wearable Ready" message

### Phase 3: Testing
1. **Step 1:** Power on device
2. **Step 2:** Check power LED (red) is on
3. **Step 3:** Use nRF Connect app to scan for device
4. **Step 4:** Verify device appears as "JointSaathi_Wearable"
5. **Step 5:** Connect to device
6. **Step 6:** Verify service UUID matches
7. **Step 7:** Subscribe to characteristics
8. **Step 8:** Send START command and verify data

### Phase 4: Flutter App Integration
1. **Step 1:** Open Flutter app
2. **Step 2:** Go to Gait Test screen
3. **Step 3:** Select "Hardware" data source
4. **Step 4:** Click "Connect ESP32 Device"
5. **Step 5:** Select "JointSaathi_Wearable"
6. **Step 6:** Verify connection success message
7. **Step 7:** Start gait test
8. **Step 8:** Verify real-time sensor data on graphs

---

## 🧪 TESTING CHECKLIST

### Hardware Tests
- [ ] Power LED turns on when device is powered
- [ ] MPU6050 responds to I2C communication
- [ ] Piezo sensor outputs voltage on joint vibration
- [ ] EMG sensor outputs voltage on muscle movement
- [ ] Battery charges via USB-C
- [ ] Device is comfortable on knee joint
- [ ] Weight is under 50g
- [ ] Device is water-resistant

### BLE Tests
- [ ] Device appears in BLE scan as "JointSaathi_Wearable"
- [ ] Service UUID matches specification
- [ ] All 4 characteristics are discoverable
- [ ] Device connects without errors
- [ ] Connection stays stable for 30+ minutes
- [ ] Data transmission starts automatically

### Integration Tests
- [ ] Flutter app discovers device
- [ ] Connection establishes within 10 seconds
- [ ] Connection LED turns green
- [ ] Accelerometer data appears in app
- [ ] Gyroscope data appears in app
- [ ] Piezo data appears in app
- [ ] EMG data appears in app
- [ ] Data rate is approximately 50Hz
- [ ] No connection drops during 30-second test
- [ ] Battery lasts 4+ hours

---

## 📏 PERFORMANCE REQUIREMENTS

### Electrical
- Operating Voltage: 3.3V ±5%
- Current Idle: <15mA
- Current Recording: <60mA
- Battery Life: 4+ hours continuous

### Environmental
- Temperature: 0°C to 40°C
- Humidity: 20% to 80% non-condensing
- Water Resistance: IP54 minimum

### Mechanical
- Dimensions: Max 50mm × 30mm × 15mm
- Weight: Max 50g including battery
- Strap Length: Adjustable 300-500mm
- Strap Material: Elastic, breathable

---

## 🔧 TROUBLESHOOTING

### Device Not Discoverable
**Possible Causes:**
- BLE not initialized in firmware
- Device name doesn't match
- Power supply issue
- Radio interference

**Solutions:**
- Check Serial Monitor for initialization errors
- Verify device name is "JointSaathi_Wattery"
- Test with different power source
- Try different phone for testing

### Connection Drops
**Possible Causes:**
- Low battery
- BLE parameter issues
- Range too far
- WiFi interference

**Solutions:**
- Check battery level
- Increase BLE power level
- Keep phone within 2 meters
- Turn off WiFi during testing

### No Data Sending
**Possible Causes:**
- Characteristics not set to notify
- Data format incorrect
- Sensors not connected
- Sampling not started

**Solutions:**
- Verify BLE2902 descriptors added
- Check data format (16-bit little-endian)
- Test sensors individually
- Verify recording command received

---

## 📦 DELIVERABLES

### Hardware
1. Working ESP32 wearable device
2. Adjustable knee strap
3. USB-C charging cable
4. Quick start guide

### Software
1. Complete firmware source code
2. Circuit schematic
3. PCB design files (Gerber)
4. Bill of materials
5. Test report

---

## ✅ FINAL CHECKLIST

Before declaring device ready:

- [ ] Device name is "JointSaathi_Wearable"
- [ ] All BLE UUIDs match specification exactly
- [ ] Data format is 16-bit little-endian with ×1000 scaling
- [ ] Sampling rate is 50Hz
- [ ] All 4 sensors are functional
- [ ] Battery lasts 4+ hours
- [ ] Device is comfortable and wearable
- [ ] Device connects to Flutter app without errors
- [ ] Real-time data appears in app graphs
- [ ] Connection is stable during 30-second test

---

## 🎯 SUCCESS CRITERIA

Device is successful when:
- ✅ Appears in BLE scan as "JointSaathi_Wearable"
- ✅ Connects to Flutter app without errors
- ✅ All 4 sensors send real-time data
- ✅ Data format matches app expectations
- ✅ Battery lasts 4+ hours
- ✅ Device is comfortable for knee attachment
- ✅ Works reliably for multiple screening sessions

---

## 📞 CONTACT

For questions about:
- **Hardware Design:** Hardware team
- **Firmware:** Software team
- **Integration:** Joint development meeting
- **Testing:** Quality assurance team

---

**Document Owner:** Flutter App Development Team  
**Version:** 1.0  
**Status:** Final
