# AquaSafe Mobile App

**AquaSafe** LoRa-based mobile application designed to aid small-scale fishermen in challenging maritime environments. This app enables critical features such as offline communication, emergency SOS alerts, weather prediction, and fishing hotspot analysis—all without the need for internet connectivity by depending on LoRa for long range connectivity and Bluetooth Low Energy for local device interaction.

## Key Features
- **Offline Communication:** Bi-directional chat system enabling communication among fishermen via the LoRa network.
- **Real-Time SOS Alerts:** Trigger emergency alerts in distress situations.
- **Weather Prediction:** Provides accurate rain predictions for the current and suggested hotspot locations.
- **Fishing Hotspot Analysis:** Analyze and identify optimal fishing locations.

## System Architechture Diagram
![MobileAppSystemDiagram](/assets/system_diagram.png)

*Figure 1: AquaSafe Mobile App System Architecture*

## System Requirements

### Software Requirements
- Flutter SDK
- VS Code or Android Studio
- Java Development Kit (JDK): Recommended Version: Java 21
- Arduino IDE

### Hardware Requirements
- ESP32 Board configured as a BLE device
- Android Device with BLE support

## Installation

### Flutter Setup:
#### For Windows
 - Download Flutter SDK.
 - Extract the SDK to ```C:\flutter```
 - Set env variables by adding Flutter to PATH ```setx PATH "%PATH%;C:\flutter\bin"```

#### For macOS
- Install Flutter using Homebrew ```brew install flutter```

### Development Tools:
 - Use VS Code or Android Studio.
 - Install plugins for Flutter and Dart in your IDE.

### Android SDK:
 - Open Android Studio.
 - Go to Tools > SDK Manager.
 - Under SDK Tools, install:
   - Android SDK Command-line Tools
   - Android SDK Build-Tools

### Verify Installation (for both windows and macOS):
 - Run ```flutter doctor```

### Running the App:
 - Clone the repository: ```git clone https://github.com/Lora-ResearchProject/AqueSafe_mobileApplication.git```
 - Get dependencies: ```flutter pub get```
 - Run the app: ```flutter run```
 - Set up an emulator or connect a physical device via USB.

## Bluetooth Connection & Configuration

### Bluetooth Connection:
- The app use ```flutter_reactive_ble``` package to bluetooth low energy.
- No manual pairing is required; the app automatically detects and connects when the ESP32 is advertising within range.

### BLE Configuration with ESP32:
- Get the [ESP32 BLE configuration code](https://github.com/Lora-ResearchProject/ESP32_MultiService_BLE.git) from the repository
- Open the .ino file in Arduino IDE.
- Connect Esp32 to the PC via USB
- Select Board as ESP32 Dev Module and appropriate COM port.
- Check UUID Synchronization : Ensure that the service and characteristic UUIDs defined in the ESP32 code match those in the AquaSafe mobile app's ```lib/utils/constants.dart file```.
- Compile and upload the code

### Verify BLE Server Advertising:
 - After uploading the code, use a BLE scanning tool (e.g., nRF Connect, ) or BLE-compatible device to check if the ESP32 is visible.
 - The ESP32 should advertise its BLE services as ESP32-MultiService.

### Connect the Mobile App:
 - Launch the AquaSafe mobile app and ensure it automatically connects to the BLE device.


