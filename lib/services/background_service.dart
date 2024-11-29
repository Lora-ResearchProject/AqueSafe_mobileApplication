// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'bluetooth_service.dart';

// void backgroundService() {
//   FlutterBackgroundService().onDataReceived.listen((event) {
//     if (event['action'] == 'startMonitoring') {
//       final BluetoothService bluetoothService = BluetoothService();
//       bluetoothService.monitorConnection();  // Start monitoring in the background
//     }
//   });
// }

// void startBackgroundService() {
//   FlutterBackgroundService().configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: backgroundService,
//       autoStart: true,
//       isInDebugMode: true,
//       notificationTitle: "AquaSafe Service",
//       notificationContent: "Monitoring Bluetooth Connection",
//       notificationIcon: "resource_icon", // Optional: custom notification icon
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: backgroundService,
//       onBackground: backgroundService,
//     ),
//   );
//   FlutterBackgroundService().start();
// }
