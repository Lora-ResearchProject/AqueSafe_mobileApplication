import 'dart:typed_data';
import 'dart:convert';

Uint8List compressData(Map<String, dynamic> item) {
  final buffer = BytesBuilder();
  final idParts = item['id'].split('|');
  final idNum = int.parse(idParts[0]);
  final idStr = idParts[1];
  final idStrBytes = ascii.encode(idStr);

  buffer.add([(idNum >> 8) & 0xFF, idNum & 0xFF]);
  buffer.add([idStrBytes.length]);
  buffer.add(idStrBytes);

  int control = 0;
  if (item.containsKey('l')) control |= 1 << 0;
  if (item.containsKey('s')) control |= (item['s'] & 0x01) << 1;
  if (item.containsKey('m')) control |= 1 << 2;
  if (item.containsKey('wr')) control |= (item['wr'] & 0x01) << 3;
  if (item.containsKey('w')) control |= 1 << 4;
  buffer.add([control]);

  if (item.containsKey('l')) {
    final parts = item['l'].split('|');
    int lat = (double.parse(parts[0]) * 10000).round();
    int lon = (double.parse(parts[1]) * 10000).round();
    buffer.add(_int24ToBytes(lat));
    buffer.add(_int24ToBytes(lon));
  }

  if (item.containsKey('m')) buffer.add([item['m'] & 0x7F]);
  if (item.containsKey('w')) buffer.add([item['w'] & 0x7F]);

  return buffer.toBytes();
}

Map<String, dynamic> decompressData(Uint8List data) {
  int idNum    = (data[0] << 8) | data[1];
  int idStrLen = data[2];
  String idStr = ascii.decode(data.sublist(3, 3 + idStrLen));
  int control  = data[3 + idStrLen];
  int pos      = 4 + idStrLen;

  // ← here!
  final Map<String, dynamic> result = {
    'id': '$idNum|$idStr',
  };

  if ((control & (1 << 0)) != 0) {
    int lat = _bytesToInt24(data.sublist(pos,     pos + 3));
    int lon = _bytesToInt24(data.sublist(pos + 3, pos + 6));
    result['l'] = '${(lat / 10000).toStringAsFixed(4)}'
                '|${(lon / 10000).toStringAsFixed(4)}';
    pos += 6;
  }

  if (((control >> 1) & 0x01) == 1)   result['s']  = 1;
  if ((control & (1 << 2))     != 0)   result['m']  = data[pos++];
  if (((control >> 3) & 0x01)  == 1)   result['wr'] = 1;
  if ((control & (1 << 4))     != 0)   result['w']  = data[pos];

  return result;
}


List<int> _int24ToBytes(int value) {
  final b = ByteData(4);
  b.setInt32(0, value);
  return b.buffer.asUint8List().sublist(1);
}

int _bytesToInt24(List<int> bytes) {
  final full = Uint8List(4);
  full[0] = (bytes[0] & 0x80) != 0 ? 0xFF : 0x00;
  full.setRange(1, 4, bytes);
  return ByteData.sublistView(full).getInt32(0);
}
