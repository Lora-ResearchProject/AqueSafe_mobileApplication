class SOSAlert {
  final String id;
  final String location;
  final int status;

  // Constructor
  SOSAlert({required this.id, required this.location, required this.status});

  // Factory method to parse JSON into SOSAlert object
  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'],            // SOS ID (e.g., "004-0000")
      location: json['l'],       // Location as "latitude-longitude"
      status: json['s'],         // SOS status (1 for alert)
    );
  }

  // Method to convert SOSAlert object back to a Map (for sending to a server, etc.)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'l': location,
      's': status,
    };
  }
}
