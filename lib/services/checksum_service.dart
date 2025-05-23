import 'dart:typed_data';

Uint8List addChecksum(Uint8List data) {
  int crc = 0x00;
  for (var byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 0x80) != 0 ? (crc << 1) ^ 0x07 : crc << 1;
    }
    crc &= 0xFF;
  }
  return Uint8List.fromList([...data, crc]);
}

Uint8List verifyChecksum(Uint8List dataWithCrc) {
  final data = dataWithCrc.sublist(0, dataWithCrc.length - 1);
  final crcReceived = dataWithCrc.last;
  int crc = 0x00;
  for (var byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 0x80) != 0 ? (crc << 1) ^ 0x07 : crc << 1;
    }
    crc &= 0xFF;
  }
  if (crc != crcReceived) throw Exception("Checksum verification failed");
  return Uint8List.fromList(data);
}
