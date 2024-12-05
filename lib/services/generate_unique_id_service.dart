class GenerateUniqueIdService {
  // Base62 characters
  static const String _chars =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

  // Converts a number to its Base62 representation
  String toBase62(int num) {
    String base62 = "";

    // Convert number to Base62
    while (num > 0) {
      int remainder = num % 62;
      base62 = _chars[remainder] + base62;
      num = num ~/ 62; // Integer division
    }

    return base62;
  }

  // Generates a unique ID based on the current timestamp
  String generateId() {
    // Get the current timestamp in milliseconds
    int timestampMs = DateTime.now().millisecondsSinceEpoch;

    // Convert timestamp to Base62
    return toBase62(timestampMs);
  }
}
