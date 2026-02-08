# Project Imsoniack 🌙

**A Comprehensive IoT-Enabled Sleep Tracking Ecosystem**

Project Imsoniack is a smart health solution designed to monitor, analyze, and improve sleep quality. By combining a custom-built IoT wearable with a sleek Flutter mobile application and a powerful Firebase backend, it provides real-time insights into sleep stages, heart rate, and movement.

---

## ⚡ Key Features

### 📱 Mobile Application (Flutter)
- **Sleep Analytics Dashboard**: Visualize deep sleep, light sleep, and awake periods.
- **Real-Time Monitoring**: View live heart rate and SpO2 data from the device.
- **Smart Alarm**: Wakes you up at the optimal time in your sleep cycle.
- **Sleep Aid**: Curated music and sounds to help you drift off.

### ⌚ IoT Wearable (ESP32)
- **Biometric Sensors**:
  - **MAX30102**: Precision Heart Rate & SpO2 sensing.
  - **MPU6050**: 6-axis accelerometer/gyroscope for movement and sleep posture tracking.
- **Smart Power Management**: Wake-on-motion and Deep Sleep modes for extended battery life.
- **Secure Data Transmission**: Direct HTTPS connection to Firebase Cloud Functions.

### ☁️ Backend (Firebase)
- **Cloud Functions**: Serverless environment for advanced signal processing logic.
- **Firestore Database**: secure, scalable storage for historical sleep data.
- **Authentication**: Secure user login and profile management.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Hardware**: ESP32, Arduino C++
- **Backend**: Node.js (Firebase Cloud Functions)
- **Database**: Cloud Firestore

---

## 🔐 Setup & Security

> [!IMPORTANT]
> This project uses environment variables and local configuration files to keep secrets safe. **These files are ignored by git** and must be created manually after cloning.

### 1. IoT Secrets (ESP32)
1. Navigate to `esp32_iot_code/`.
2. Copy `secrets_example.h` to `secrets.h`.
   ```bash
   cp esp32_iot_code/secrets_example.h esp32_iot_code/secrets.h
   ```
3. Open `secrets.h` and fill in your:
   - Wi-Fi SSID
   - Wi-Fi Password
   - API Key

### 2. Node.js Scripts
1. Navigate to the project root.
2. Copy `.env.example` to `.env`.
   ```bash
   cp .env.example .env
   ```
3. Open `.env` and add your `IOT_API_KEY`.
4. Install dependencies:
   ```bash
   cd scripts
   npm install dotenv
   ```

### 3. Firebase options
If `lib/firebase_options.dart` is missing (it is ignored for security), you need to reconfigure FlutterFire:
```bash
flutterfire configure
```

---

## 🚀 Getting Started

1. **Hardware**: Flash the code in `esp32_iot_code` to your ESP32 device.
2. **Backend**: Deploy functions in `functions/` using `firebase deploy --only functions`.
3. **App**: Run the Flutter app:
   ```bash
   flutter run
   ```

---

## 👥 Contributors

This project was originally developed as a group assignment for the KT34302 Technopreneurship (Group 7).

| Name | Profile Link |
| :--- | :--- |
| **Wan Ahmad Nurullah Bin Wan M. Azhari** | [LinkedIn](https://www.linkedin.com/in/wanahmadnurullah/) |
| **Christherressa Eduward** | [LinkedIn](https://www.linkedin.com/in/christherressa-eduward-109319291/) |
| **Putri Balqis Hakimah Binti Ismaily** | [LinkedIn]() |
| **Jessie Abbygil Anak Philip** | [LinkedIn]() |
| **Cody Ryan James** | [LinkedIn]() |
| **Joyce Grace George** | [LinkedIn]() |

