import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';

final key = Uint8List.fromList([
  0x01, 0x23, 0x45, 0x67,
  0x89, 0xAB, 0xCD, 0xEF,
  0x01, 0x23, 0x45, 0x67,
  0x89, 0xAB, 0xCD, 0xEF,
]);

Uint8List encrypt(Uint8List data) {
  final iv = Uint8List.fromList(List.generate(12, (_) => Random().nextInt(256)));
  final ivFull = Uint8List.fromList([...iv, 0, 0, 0, 0]);
  final cipher = CTRStreamCipher(AESFastEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), ivFull));

  final encrypted = cipher.process(data);
  final tag = Hmac(sha256, key).convert([...iv, ...encrypted]).bytes.sublist(0, 4);

  return Uint8List.fromList([...iv, ...encrypted, ...tag]);
}

Uint8List decrypt(Uint8List full) {
  final iv = full.sublist(0, 12);
  final ciphertext = full.sublist(12, full.length - 4);
  final tag = full.sublist(full.length - 4);
  final expected = Hmac(sha256, key).convert([...iv, ...ciphertext]).bytes.sublist(0, 4);

  if (!ListEquality().equals(tag, expected)) throw Exception("HMAC failed");

  final ivFull = Uint8List.fromList([...iv, 0, 0, 0, 0]);
  final cipher = CTRStreamCipher(AESFastEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), ivFull));

  return cipher.process(ciphertext);
}
