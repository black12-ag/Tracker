import 'dart:math';

class AppUuid {
  AppUuid._();

  static final Random _random = Random.secure();

  static String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final parts = bytes.map(hex).toList(growable: false);

    return '${parts[0]}${parts[1]}${parts[2]}${parts[3]}-'
        '${parts[4]}${parts[5]}-'
        '${parts[6]}${parts[7]}-'
        '${parts[8]}${parts[9]}-'
        '${parts[10]}${parts[11]}${parts[12]}${parts[13]}${parts[14]}${parts[15]}';
  }
}
