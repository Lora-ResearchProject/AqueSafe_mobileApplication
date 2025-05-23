import 'dart:typed_data';
import '../services/checksum_service.dart';
import '../services/encryption_service.dart';
import '../services/compression_service.dart';

Map<String, dynamic> decodeLoRaPayload(Uint8List encrypted) {
  final decrypted = decrypt(encrypted);
  final verified = verifyChecksum(decrypted);
  final decompressed = decompressData(verified);
  return decompressed;
}
