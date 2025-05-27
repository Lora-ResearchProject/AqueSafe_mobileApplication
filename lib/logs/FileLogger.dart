import 'dart:io';
import 'package:path_provider/path_provider.dart'; // To get directory paths
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions

class FileLogger {
  // Method to get the file path
  Future<File> _getLogFile() async {
    final directory = await _getLogDirectory();
    final logFilePath = '${directory.path}/app_log.txt';
    return File(logFilePath);
  }

  // Custom method to get the directory path
  Future<Directory> _getLogDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getExternalStorageDirectory();
      print("Run android external storage directory: $directory");
      return directory!;
    } else {
      throw Exception('Unsupported platform for log file.');
    }
  }

  // Method to request permission to write to external storage
  Future<bool> _requestPermission() async {
    PermissionStatus permission = await Permission.storage.request();
    return permission.isGranted;
  }

  // Method to write log to file
  Future<void> log(String message) async {
    bool permissionGranted = await _requestPermission();

    if (permissionGranted) {
      final file = await _getLogFile();
      IOSink sink = file.openWrite(mode: FileMode.append);

      // Add current timestamp to each log message
      String timestamp = DateTime.now().toIso8601String().substring(11, 19);
      sink.writeln('$timestamp - $message');

      await sink.flush(); // Ensure content is written to the file
      await sink.close();
    } else {
      print("Permission denied! Cannot write to external storage.");
    }
  }
}
