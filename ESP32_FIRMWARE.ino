/*
 * JointSaathi ESP32 Wearable Firmware
 * For OA (Osteoarthritis) Screening Device
 * Connects to Flutter App via Bluetooth Low Energy
 * 
 * This firmware collects data from 4 sensors:
 * - MPU6050 (Accelerometer + Gyroscope)
 * - Piezo (Joint Vibration)
 * - EMG (Muscle Activity)
 * 
 * Data is sent to Flutter app via BLE at 50Hz
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <MPU6050.h>

// ==================== CONFIGURATION ====================

// Device Name
#define DEVICE_NAME "JointSaathi_Wearable"

// BLE UUIDs (MUST MATCH EXACTLY)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define ACCEL_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define GYRO_CHAR_UUID     "beb5483f-36e1-4688-b7f5-ea07361b26a9"
#define PIEZO_CHAR_UUID    "beb54840-36e1-4688-b7f5-ea07361b26aa"
#define EMG_CHAR_UUID      "beb54841-36e1-4688-b7f5-ea07361b26ab"

// Sensor Pins
#define PIEZO_PIN 34
#define EMG_PIN 35

// LED Pins
#define POWER_LED 2
#define CONNECTION_LED 4
#define RECORDING_LED 5

// Sampling Configuration
#define SAMPLE_RATE 50  // Hz (50 samples per second)
#define SAMPLE_INTERVAL_MS (1000 / SAMPLE_RATE)

// MPU6050 Configuration
#define ACCEL_RANGE 2     // ±2g
#define GYRO_RANGE 250    // ±250°/s

// ==================== GLOBAL VARIABLES ====================

MPU6050 mpu;
bool isRecording = false;
bool isConnected = false;
unsigned long lastSampleTime = 0;

// BLE Server and Characteristics
BLEServer* pServer = NULL;
BLECharacteristic* pAccelCharacteristic = NULL;
BLECharacteristic* pGyroCharacteristic = NULL;
BLECharacteristic* pPiezoCharacteristic = NULL;
BLECharacteristic* pEMGCharacteristic = NULL;

// ==================== SETUP ====================

void setup() {
  Serial.begin(115200);
  Serial.println("Starting JointSaathi Wearable...");
  
  // Initialize Pins
  pinMode(POWER_LED, OUTPUT);
  pinMode(CONNECTION_LED, OUTPUT);
  pinMode(RECORDING_LED, OUTPUT);
  pinMode(PIEZO_PIN, INPUT);
  pinMode(EMG_PIN, INPUT);
  
  // Power LED on
  digitalWrite(POWER_LED, HIGH);
  
  // Initialize MPU6050
  Serial.println("Initializing MPU6050...");
  Wire.begin();
  mpu.initialize();
  
  // Configure MPU6050
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_2);
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_250);
  
  // Test MPU6050 connection
  if (mpu.testConnection()) {
    Serial.println("MPU6050 connected successfully");
  } else {
    Serial.println("MPU6050 connection failed!");
  }
  
  // Initialize BLE
  Serial.println("Initializing BLE...");
  initBLE();
  
  Serial.println("JointSaathi Wearable Ready!");
  Serial.println("Waiting for connection from Flutter app...");
}

// ==================== MAIN LOOP ====================

void loop() {
  // Check if recording and connected
  if (isRecording && isConnected) {
    unsigned long currentTime = millis();
    
    // Sample at specified rate
    if (currentTime - lastSampleTime >= SAMPLE_INTERVAL_MS) {
      lastSampleTime = currentTime;
      readAndSendSensors();
    }
  }
  
  // Small delay to prevent watchdog
  delay(1);
}

// ==================== BLE INITIALIZATION ====================

void initBLE() {
  // Initialize BLE device
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setPower(ESP_PWR_LVL_P7); // Maximum power
  
  // Create BLE server
  pServer = BLEDevice::createServer();
  
  // Create service
  BLEService* pService = pServer->createService(SERVICE_UUID);
  
  // Create characteristics
  pAccelCharacteristic = pService->createCharacteristic(
    ACCEL_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pGyroCharacteristic = pService->createCharacteristic(
    GYRO_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pPiezoCharacteristic = pService->createCharacteristic(
    PIEZO_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pEMGCharacteristic = pService->createCharacteristic(
    EMG_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  // Add notification descriptors (REQUIRED for data streaming)
  pAccelCharacteristic->addDescriptor(new BLE2902());
  pGyroCharacteristic->addDescriptor(new BLE2902());
  pPiezoCharacteristic->addDescriptor(new BLE2902());
  pEMGCharacteristic->addDescriptor(new BLE2902());
  
  // Start service
  pService->start();
  
  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE advertising started");
  Serial.print("Device Name: ");
  Serial.println(DEVICE_NAME);
}

// ==================== SENSOR READING ====================

void readAndSendSensors() {
  // Read MPU6050
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  
  // Convert to g-force and deg/s
  float accelX = ax / 16384.0;  // ±2g range
  float accelY = ay / 16384.0;
  float accelZ = az / 16384.0;
  float gyroX = gx / 131.0;    // ±250°/s range
  float gyroY = gy / 131.0;
  float gyroZ = gz / 131.0;
  
  // Read Piezo (joint vibration)
  int piezoRaw = analogRead(PIEZO_PIN);
  float piezoValue = (piezoRaw / 4095.0) * 2.0 - 1.0; // Normalize to -1 to 1
  
  // Read EMG (muscle activity)
  int emgRaw = analogRead(EMG_PIN);
  float emgValue = emgRaw / 4095.0; // Normalize to 0 to 1
  
  // Send via BLE
  sendAccelerometerData(accelX, accelY, accelZ);
  sendGyroscopeData(gyroX, gyroY, gyroZ);
  sendPiezoData(piezoValue);
  sendEMGData(emgValue);
  
  // Blink recording LED
  digitalWrite(RECORDING_LED, !digitalRead(RECORDING_LED));
}

// ==================== BLE DATA SENDING ====================

void sendAccelerometerData(float x, float y, float z) {
  // Convert to 16-bit integers (scale by 1000)
  int16_t xInt = (int16_t)(x * 1000);
  int16_t yInt = (int16_t)(y * 1000);
  int16_t zInt = (int16_t)(z * 1000);
  
  uint8_t data[6];
  data[0] = xInt & 0xFF;
  data[1] = (xInt >> 8) & 0xFF;
  data[2] = yInt & 0xFF;
  data[3] = (yInt >> 8) & 0xFF;
  data[4] = zInt & 0xFF;
  data[5] = (zInt >> 8) & 0xFF;
  
  pAccelCharacteristic->setValue(data, 6);
  pAccelCharacteristic->notify();
}

void sendGyroscopeData(float x, float y, float z) {
  int16_t xInt = (int16_t)(x * 1000);
  int16_t yInt = (int16_t)(y * 1000);
  int16_t zInt = (int16_t)(z * 1000);
  
  uint8_t data[6];
  data[0] = xInt & 0xFF;
  data[1] = (xInt >> 8) & 0xFF;
  data[2] = yInt & 0xFF;
  data[3] = (yInt >> 8) & 0xFF;
  data[4] = zInt & 0xFF;
  data[5] = (zInt >> 8) & 0xFF;
  
  pGyroCharacteristic->setValue(data, 6);
  pGyroCharacteristic->notify();
}

void sendPiezoData(float value) {
  int16_t valueInt = (int16_t)(value * 1000);
  
  uint8_t data[2];
  data[0] = valueInt & 0xFF;
  data[1] = (valueInt >> 8) & 0xFF;
  
  pPiezoCharacteristic->setValue(data, 2);
  pPiezoCharacteristic->notify();
}

void sendEMGData(float value) {
  int16_t valueInt = (int16_t)(value * 1000);
  
  uint8_t data[2];
  data[0] = valueInt & 0xFF;
  data[1] = (valueInt >> 8) & 0xFF;
  
  pEMGCharacteristic->setValue(data, 2);
  pEMGCharacteristic->notify();
}

// ==================== CONNECTION CALLBACKS ====================

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    isConnected = true;
    digitalWrite(CONNECTION_LED, HIGH);
    Serial.println("Device Connected to Flutter App");
  };
  
  void onDisconnect(BLEServer* pServer) {
    isConnected = false;
    isRecording = false;
    digitalWrite(CONNECTION_LED, LOW);
    digitalWrite(RECORDING_LED, LOW);
    Serial.println("Device Disconnected");
    
    // Restart advertising
    BLEDevice::startAdvertising();
  }
};

class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    
    // Parse commands from Flutter app
    if (value == "START_RECORDING") {
      isRecording = true;
      Serial.println("Recording Started");
    } else if (value == "STOP_RECORDING") {
      isRecording = false;
      Serial.println("Recording Stopped");
    }
  }
};

// Add callbacks in setup (uncomment and add to setup function):
/*
void setup() {
  // ... existing setup code ...
  
  // Add callbacks
  pServer->setCallbacks(new MyServerCallbacks());
  pAccelCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pGyroCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pPiezoCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pEMGCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
}
*/
