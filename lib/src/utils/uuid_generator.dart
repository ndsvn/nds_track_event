import 'dart:math';

/// Simple UUID v4 generator
class UuidGenerator {
  static final Random _random = Random();

  /// Generate a UUID v4 string
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC4122
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    return _formatUuid(bytes);
  }

  static String _formatUuid(List<int> bytes) {
    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${toHex(bytes[0])}${toHex(bytes[1])}${toHex(bytes[2])}${toHex(bytes[3])}-'
        '${toHex(bytes[4])}${toHex(bytes[5])}-'
        '${toHex(bytes[6])}${toHex(bytes[7])}-'
        '${toHex(bytes[8])}${toHex(bytes[9])}-'
        '${toHex(bytes[10])}${toHex(bytes[11])}${toHex(bytes[12])}${toHex(bytes[13])}${toHex(bytes[14])}${toHex(bytes[15])}';
  }
}

