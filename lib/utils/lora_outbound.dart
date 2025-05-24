import 'dart:typed_data';
import '../services/compression_service.dart';
import '../services/checksum_service.dart';
import '../services/encryption_service.dart';

Uint8List prepareLoRaPayload(Map<String, dynamic> message) {
  final compressed = compressData(message);
  final crc = addChecksum(compressed);
  final encrypted = encrypt(crc);
  return encrypted;
}