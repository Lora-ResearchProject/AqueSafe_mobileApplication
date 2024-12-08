# AquaSafe Mobile App

**AquaSafe** is a cutting-edge, LoRa-based mobile application designed to aid fishermen in challenging maritime environments. This app enables critical features such as offline communication, emergency SOS alerts, weather prediction, and fishing hotspot analysis—all without the need for internet connectivity.


## Key Features

- **Offline Communication:** Bi-directional chat system enabling communication among fishermen via the LoRa network.
- **Real-Time SOS Alerts:** Trigger emergency alerts in distress situations.
- **Weather Prediction:** Provides accurate weather forecasts tailored to the location of the fisherman.
- **Fishing Hotspot Analysis:** Analyze and identify optimal fishing locations.


## System Architechture Diagram
![MobileAppSystemDiagram](/assets/system_diagram.png)

*Figure 1: AquaSafe Mobile App System Architecture*

## Installation

#### Flutter Setup:
 - Install Flutter SDK.
 - Ensure the environment variables are set correctly for flutter commands.

#### Development Tools:
 - Use VS Code or Android Studio.
 - Install plugins for Flutter and Dart in your IDE.

#### Android SDK:
 - Open Android Studio.
 - Go to Tools > SDK Manager.
 - Under SDK Tools, install:
   - Android SDK Command-line Tools
   - Android SDK Build-Tools

#### Verify Installation:
 - Run ```flutter doctor``` to ensure all components are installed correctly.

#### Running the App:
 - Clone the repository: ```git clone https://github.com/Lora-ResearchProject/AqueSafe_mobileApplication.git```
 - Get dependencies: ```flutter pub get```
 - Run the app: ```flutter run```
 - Optional: Set up an emulator or connect a physical device via USB.


## Bluetooth Connection 

 - The app connects to a hardware device via Bluetooth for data exchange
 - Supports built in bluetooth ensuring seamless BLE connectivity.
 - The mobile app automatically detects and connects to the BLE device when the ESP32 is configured and advertising within range.
 - This enables access to key features like SOS alerts, chat, fishing hotspots, weather updates, and GPS data without requiring manual pairing.


## Hardware Requirements

#### ESP32 Module:
 - Configured with BLE services and characteristics for communication.
 - Refer to the repository ESP32 MultiService BLE for detailed configuration and setup guide.

#### Power Supply:
 - Battery or USB-powered setup for ESP32 devices.
   
#### Bluetooth Low Energy (BLE) Connectivity:
 - Ensure the smartphone supports BLE and is configured to communicate with the ESP32 module.


## ESP32 Configuration

#### 1. Obtain ESP32 Configuration Code:
 - Get the [ESP32 BLE configuration code](https://github.com/Lora-ResearchProject/ESP32_MultiService_BLE.git) from the repository

#### 2. Compile and upload the code to the ESP32 device:
 - Open the .ino file from the repository in Arduino IDE.
 - Select the correct Board (e.g., ESP32 Dev Module) and Port under the Tools menu.
 - Get a new sketch and paste the code

#### 3. Check UUID Synchronization
 - Ensure that the service and characteristic UUIDs defined in the ESP32 code match those in the AquaSafe mobile app's ```lib/utils/constants.dart file```.
 - This alignment is essential for the app to interact correctly with the BLE device.
   
#### 4. Compile and upload the code to the ESP32 device.
 - After checking UUIDs match compile and upload the code in to ESP32

#### 5. Verify BLE Server Advertising:
 - After uploading the code, use a suitable mobile app, such as  (e.g., nRF Connect, ) or BLE-compatible device to scan for BLE devicesservers.
 - Ensure the ESP32 device (ESP32-MultiService) is visible and advertising the necessaryits services.

## Connect the Mobile App
 - Launch the AquaSafe mobile app and ensure it automatically connects to the BLE device.
 - The app should successfully retrieve data from the BLE services (e.g., GPS, SOS alerts).


