#include <Wire.h>
#include <MPU6050.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLEAdvertisedDevice.h>

MPU6050 mpu;

// Sensor Pins Setup
#define PIEZO_PIN   34
#define EMG_PIN     35    // EMG Pin
#define BATTERY_PIN 33    // Battery voltage monitoring (ADC1_CH5)
#define MIDPOINT    2048
#define DAC_OUT_PIN 25

// BLE setup
BLEServer* pServer = NULL;
bool deviceConnected = false;

// Service + characteristic UUIDs 
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define ACCEL_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define GYRO_UUID    "beb5483f-36e1-4688-b7f5-ea07361b26a9"
#define PIEZO_UUID   "beb54840-36e1-4688-b7f5-ea07361b26aa"
#define EMG_UUID     "beb54841-36e1-4688-b7f5-ea07361b26ab"
#define BATTERY_UUID "beb54843-36e1-4688-b7f5-ea07361b26ad" 

BLECharacteristic *pAccelChar;
BLECharacteristic *pGyroChar;
BLECharacteristic *pPiezoChar;
BLECharacteristic *pEMGChar; // EMG Characteristic
BLECharacteristic *pBatteryChar; // Battery Characteristic

// Piezo & EMG Average padhne ka function
int readSensorAverage(int pin, int samples) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
  }
  return sum / samples;
}

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) { deviceConnected = true; }
  void onDisconnect(BLEServer* pServer) { 
    deviceConnected = false; 
    BLEDevice::startAdvertising(); // Disconnect hone pe wapas advertise karega
  }
};

void setup() {
  Serial.begin(115200);
  Wire.begin();
  
  pinMode(PIEZO_PIN, INPUT);
  pinMode(EMG_PIN, INPUT);
  pinMode(BATTERY_PIN, INPUT);

  // MPU init
  mpu.initialize();
  if (mpu.testConnection()) {
    Serial.println("MPU6050 connected");
  } else {
    Serial.println("MPU6050 failed");
  }

  // BLE init
  BLEDevice::init("JointSaathi");
  Serial.print("BLE Address: ");
  Serial.println(BLEDevice::getAddress().toString().c_str());

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create characteristics
  pAccelChar = pService->createCharacteristic(
    ACCEL_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  pAccelChar->addDescriptor(new BLE2902());

  pGyroChar = pService->createCharacteristic(
    GYRO_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  pGyroChar->addDescriptor(new BLE2902());

  pPiezoChar = pService->createCharacteristic(
    PIEZO_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  pPiezoChar->addDescriptor(new BLE2902());
  
  // EMG Characteristic
  pEMGChar = pService->createCharacteristic(
    EMG_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  pEMGChar->addDescriptor(new BLE2902());

  // Battery Characteristic
  pBatteryChar = pService->createCharacteristic(
    BATTERY_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  pBatteryChar->addDescriptor(new BLE2902());

  pService->start();
  
  // Robust BLE Advertising setup
  // Main adv packet: Service UUID (so phones can filter/find us)
  // Scan response packet: Device name (so Android shows "JointSaathi" not "Unknown Device")
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  
  // Explicitly put device name in scan response so Android shows it correctly
  BLEAdvertisementData scanResponse;
  scanResponse.setName("JointSaathi");   // This is what phone will display
  pAdvertising->setScanResponseData(scanResponse);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE advertising started - Device name: JointSaathi");
}

void loop() {
  // --- 1. Read MPU ---
  int16_t ax, ay, az;
  int16_t gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  
  // Convert into real units (G-force and degree/s)
  float accelX = ax / 16384.0;
  float accelY = ay / 16384.0;
  float accelZ = az / 16384.0;
  float gyroX_deg = gx / 131.0;
  float gyroY_deg = gy / 131.0;
  float gyroZ_deg = gz / 131.0;

  // Convert gyro to rad/s to avoid int16 overflow when multiplying by 1000
  float gyroX = gyroX_deg * 0.01745329;
  float gyroY = gyroY_deg * 0.01745329;
  float gyroZ = gyroZ_deg * 0.01745329;

  // --- 2. Read Piezo ---
  int rawPiezo = readSensorAverage(PIEZO_PIN, 10);
  int amplitude = abs(rawPiezo - MIDPOINT);
  float piezoValue = (rawPiezo / 4095.0) * 2.0 - 1.0; // Graph ke liye -1 se +1

  // --- DAC output ---
  int dacValue = map(rawPiezo, 0, 4095, 0, 255);
  dacWrite(DAC_OUT_PIN, dacValue);
  
  // --- 3. Read EMG ---
  int rawEMG = readSensorAverage(EMG_PIN, 10);
  float emgValue = rawEMG / 4095.0; // Graph ke liye 0 se +1

  // --- 4. Read Battery ---
  int rawBattery = readSensorAverage(BATTERY_PIN, 10);
  float batteryVoltage = (rawBattery / 4095.0) * 3.3; // 0-3.3V range
  // Calculate battery percentage (3.0V = 0%, 3.3V = 100%)
  float batteryPercentage = ((batteryVoltage - 3.0) / 0.3) * 100.0;
  if (batteryPercentage < 0) batteryPercentage = 0;
  if (batteryPercentage > 100) batteryPercentage = 100;

  // --- 5. Send via BLE (APP EXPECTS BINARY DATA, NOT STRINGS) ---
  if (deviceConnected) {
    
    // Accelerometer
    int16_t axInt = (int16_t)(accelX * 1000);
    int16_t ayInt = (int16_t)(accelY * 1000);
    int16_t azInt = (int16_t)(accelZ * 1000);
    uint8_t aData[6] = { (uint8_t)(axInt & 0xFF), (uint8_t)((axInt >> 8) & 0xFF),
                         (uint8_t)(ayInt & 0xFF), (uint8_t)((ayInt >> 8) & 0xFF),
                         (uint8_t)(azInt & 0xFF), (uint8_t)((azInt >> 8) & 0xFF) };
    pAccelChar->setValue(aData, 6);
    pAccelChar->notify();

    // Gyroscope
    int16_t gxInt = (int16_t)(gyroX * 1000);
    int16_t gyInt = (int16_t)(gyroY * 1000);
    int16_t gzInt = (int16_t)(gyroZ * 1000);
    uint8_t gData[6] = { (uint8_t)(gxInt & 0xFF), (uint8_t)((gxInt >> 8) & 0xFF),
                         (uint8_t)(gyInt & 0xFF), (uint8_t)((gyInt >> 8) & 0xFF),
                         (uint8_t)(gzInt & 0xFF), (uint8_t)((gzInt >> 8) & 0xFF) };
    pGyroChar->setValue(gData, 6);
    pGyroChar->notify();

    // Piezo
    int16_t pInt = (int16_t)(piezoValue * 1000);
    uint8_t pData[2] = { (uint8_t)(pInt & 0xFF), (uint8_t)((pInt >> 8) & 0xFF) };
    pPiezoChar->setValue(pData, 2);
    pPiezoChar->notify();
    
    // EMG
    int16_t eInt = (int16_t)(emgValue * 1000);
    uint8_t eData[2] = { (uint8_t)(eInt & 0xFF), (uint8_t)((eInt >> 8) & 0xFF) };
    pEMGChar->setValue(eData, 2);
    pEMGChar->notify();

    // Battery (send as percentage 0-100)
    int16_t battInt = (int16_t)(batteryPercentage);
    uint8_t battData[2] = { (uint8_t)(battInt & 0xFF), (uint8_t)((battInt >> 8) & 0xFF) };
    pBatteryChar->setValue(battData, 2);
    pBatteryChar->notify();
  }

  // --- Debug print ---
  Serial.print("Accel: "); Serial.print(ax); Serial.print(", "); Serial.print(ay); Serial.print(", "); Serial.println(az);
  Serial.print("Gyro: ");  Serial.print(gx); Serial.print(", "); Serial.print(gy); Serial.print(", "); Serial.println(gz);
  Serial.print("Piezo: "); Serial.print(rawPiezo); Serial.print(" Amp: "); Serial.println(amplitude);
  Serial.print("EMG: ");   Serial.println(rawEMG);
  Serial.print("Battery: "); Serial.print(batteryVoltage); Serial.print("V ("); Serial.print(batteryPercentage); Serial.println("%)");

  delay(20); // 50Hz pe sampling (App model expects 50Hz)
}
