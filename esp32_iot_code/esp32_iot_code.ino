#include "MAX30105.h"
#include "secrets.h"
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>
#include <WiFi.h>
#include <Wire.h>
#include <spo2_algorithm.h>


// --- Configuration ---
#define WIFI_SSID WIFI_SSID_SECRET
#define WIFI_PASSWORD WIFI_PASSWORD_SECRET
#define CLOUD_FUNCTION_URL                                                     \
  "https://asia-southeast1-project-imsoniack-1.cloudfunctions.net/"            \
  "storeIoTData"
#define API_KEY API_KEY_SECRET
#define SWITCH_PIN 27 // Switch Logic

// --- I2C Bus Objects ---
TwoWire I2C_MPU = TwoWire(0);
TwoWire I2C_MAX = TwoWire(1);

// --- Sensor Objects ---
Adafruit_MPU6050 mpu;
MAX30105 max30102;

// --- PPG Buffers ---
#define SAMPLES 100 // Must match BUFFER_SIZE in spo2_algorithm.h
#if SAMPLES != BUFFER_SIZE
#error "SAMPLES must match BUFFER_SIZE in spo2_algorithm.h"
#endif

uint32_t irBuffer[SAMPLES];
uint32_t redBuffer[SAMPLES];

int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;

unsigned long sendDataPrevMillis = 0;
const unsigned long SEND_INTERVAL = 5000; // 5 seconds

// Toggle Logic Variables
bool isSystemActive = true;
int lastButtonState = HIGH;
int currentButtonState;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;

void setup() {
  Serial.begin(115200);
  pinMode(SWITCH_PIN, INPUT_PULLUP); // Init Switch

  // --- Wi-Fi Connection ---
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());

  // --- Initialize MPU6050 ---
  // SDA=21, SCL=22
  I2C_MPU.begin(21, 22);
  if (!mpu.begin(0x68, &I2C_MPU)) {
    Serial.println("MPU6050 Failed!");
    while (1)
      delay(10);
  }
  Serial.println("MPU6050 Ready!");

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  // --- Initialize MAX30102 ---
  // SDA=32, SCL=33
  I2C_MAX.begin(32, 33);
  if (!max30102.begin(I2C_MAX)) {
    Serial.println("MAX30102 Failed!");
    while (1)
      delay(10);
  }
  Serial.println("MAX30102 Ready!");

  // max30102.setup(); // Default is too fast (400Hz)
  byte ledBrightness = 60; // Options: 0=Off to 255=50mA
  byte sampleAverage = 4;  // Options: 1, 2, 4, 8, 16, 32
  byte ledMode = 2; // Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
  int sampleRate = 100; // Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
  int pulseWidth = 411; // Options: 69, 118, 215, 411
  int adcRange = 4096;  // Options: 2048, 4096, 8192, 16384

  max30102.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth,
                 adcRange);
}

void handleButton() {
  int reading = digitalRead(SWITCH_PIN);

  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != currentButtonState) {
      currentButtonState = reading;

      if (currentButtonState == LOW) {
        isSystemActive = !isSystemActive;
        if (isSystemActive) {
          Serial.println("System ACTIVATED");
          max30102.wakeUp(); // Wake up
          // Re-configure to ensure LED turns back on (WakeUp alone might not be
          // enough) Use previous settings
          byte ledBrightness = 60;
          byte sampleAverage = 4;
          byte ledMode = 2;
          int sampleRate = 100;
          int pulseWidth = 411;
          int adcRange = 4096;
          max30102.setup(ledBrightness, sampleAverage, ledMode, sampleRate,
                         pulseWidth, adcRange);
        } else {
          Serial.println("System STANDBY (Paused)");
          max30102.shutDown();
        }
      }
    }
  }
  lastButtonState = reading;
}

void loop() {
  handleButton(); // Check at start

  // Standby Mode
  if (!isSystemActive) {
    delay(100);
    return;
  }

  // Only process and send if interval passed
  if (millis() - sendDataPrevMillis > SEND_INTERVAL ||
      sendDataPrevMillis == 0) {
    sendDataPrevMillis = millis();

    // 1. Read MAX30102 (Blocking ~1-2 seconds with timeout resilience)
    Serial.println("Reading MAX30102 samples...");
    for (int i = 0; i < SAMPLES; i++) {
      handleButton(); // Check button during sampling
      if (!isSystemActive)
        break; // Abort if turned off

      // Timeout for availability check (prevent "Stuck" if sensor fails)
      unsigned long startCheck = millis();
      while (!max30102.available()) {
        max30102.check();
        if (millis() - startCheck > 100)
          break; // Skip sample if stuck > 100ms
      }

      redBuffer[i] = max30102.getRed();
      irBuffer[i] = max30102.getIR();
      max30102.nextSample();
    }

    // Abort if system was turned off during sampling
    if (!isSystemActive)
      return;
    Serial.println("MAX30102 read complete.");

    // 2. Run Algorithm
    maxim_heart_rate_and_oxygen_saturation(irBuffer, SAMPLES, redBuffer, &spo2,
                                           &validSPO2, &heartRate,
                                           &validHeartRate);

    // 3. Read MPU6050 Snapshot
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // 4. Debug Print
    Serial.print("HR: ");
    Serial.print(validHeartRate ? String(heartRate) : "Invalid");
    Serial.print(" | SpO2: ");
    Serial.print(validSPO2 ? String(spo2) : "Invalid");
    Serial.print(" | Accel X: ");
    Serial.println(a.acceleration.x);

    // 5. Send to Cloud
    // Always push data, even if biomedical sensors are invalid (e.g. only accel
    // data)
    if (true) {
      if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;

        StaticJsonDocument<500> doc;

        // Send -1 if the reading is flagged as invalid
        doc["heart_rate"] = (validHeartRate == 1) ? heartRate : -1;
        doc["spo2"] = (validSPO2 == 1) ? spo2 : -1;

        // Other environmental data
        doc["temperature"] = temp.temperature; // MPU temp as proxy

        JsonObject accel = doc.createNestedObject("accel");
        accel["x"] = a.acceleration.x;
        accel["y"] = a.acceleration.y;
        accel["z"] = a.acceleration.z;

        String requestBody;
        serializeJson(doc, requestBody);

        http.begin(CLOUD_FUNCTION_URL);
        http.addHeader("Content-Type", "application/json");
        http.addHeader("x-api-key", API_KEY);

        Serial.println("POST Payload: " + requestBody);
        int httpResponseCode = http.POST(requestBody);

        if (httpResponseCode > 0) {
          String response = http.getString();
          Serial.printf("Response: %d - %s\n", httpResponseCode,
                        response.c_str());
        } else {
          Serial.printf("Error on sending POST: %d\n", httpResponseCode);
        }
        http.end();
      } else {
        Serial.println("WiFi Disconnected! Attempting reconnect next cycle.");
        WiFi.disconnect();
        WiFi.reconnect();
      }
    }
  }
}
