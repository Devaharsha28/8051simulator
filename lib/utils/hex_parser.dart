/// Intel HEX file parser for 8051 simulator
/// Supports standard Intel HEX format used for 8051 programs
class HexParser {
  /// Parse an Intel HEX file and return a map of address -> byte
  /// Throws FormatException if the hex file is invalid
  static Map<int, int> parse(String hexContent) {
    final Map<int, int> memory = {};
    final lines = hexContent.split('\n');
    int extendedAddress = 0;

    for (var line in lines) {
      line = line.trim();
      
      // Skip empty lines
      if (line.isEmpty) continue;
      
      // Skip comments (if any)
      if (line.startsWith('#') || line.startsWith(';')) continue;
      
      // All valid records start with ':'
      if (!line.startsWith(':')) {
        throw FormatException('Invalid HEX line: missing colon');
      }
      
      // Remove the colon
      line = line.substring(1);
      
      // Validate hex characters
      if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(line)) {
        throw FormatException('Invalid HEX line: non-hex characters');
      }
      
      // Need at least: byteCount(2) + address(4) + recordType(2) + checksum(2) = 10 chars
      if (line.length < 10) {
        throw FormatException('Invalid HEX line: too short');
      }
      
      // Parse record fields
      final byteCount = int.parse(line.substring(0, 2), radix: 16);
      final address = int.parse(line.substring(2, 6), radix: 16);
      final recordType = int.parse(line.substring(6, 8), radix: 16);
      
      // Expected length: byteCount*2 (data) + 10 (header+checksum)
      final expectedLength = byteCount * 2 + 10;
      if (line.length < expectedLength) {
        throw FormatException('Invalid HEX line: data length mismatch');
      }
      
      // Extract data bytes
      final dataBytes = <int>[];
      for (int i = 0; i < byteCount; i++) {
        final byteStr = line.substring(8 + i * 2, 10 + i * 2);
        dataBytes.add(int.parse(byteStr, radix: 16));
      }
      
      // Extract checksum
      final checksum = int.parse(line.substring(8 + byteCount * 2, 10 + byteCount * 2), radix: 16);
      
      // Verify checksum
      int calculatedChecksum = byteCount + (address >> 8) + (address & 0xFF) + recordType;
      for (var byte in dataBytes) {
        calculatedChecksum += byte;
      }
      calculatedChecksum = (~calculatedChecksum + 1) & 0xFF;
      
      if (calculatedChecksum != checksum) {
        throw FormatException('Invalid HEX line: checksum mismatch');
      }
      
      // Process based on record type
      switch (recordType) {
        case 0x00: // Data record
          final fullAddress = extendedAddress + address;
          for (int i = 0; i < dataBytes.length; i++) {
            memory[fullAddress + i] = dataBytes[i];
          }
          break;
          
        case 0x01: // End of file
          return memory;
          
        case 0x02: // Extended segment address (not commonly used for 8051)
          if (byteCount == 2) {
            extendedAddress = ((dataBytes[0] << 8) | dataBytes[1]) << 4;
          }
          break;
          
        case 0x04: // Extended linear address
          if (byteCount == 2) {
            extendedAddress = ((dataBytes[0] << 8) | dataBytes[1]) << 16;
          }
          break;
          
        case 0x05: // Start linear address (ignored for 8051)
          break;
          
        default:
          // Unknown record type, skip
          break;
      }
    }
    
    return memory;
  }
  
  /// Load hex file and validate it's suitable for 8051 (address range check)
  static Map<int, int> parseFor8051(String hexContent) {
    final memory = parse(hexContent);
    
    // Check if addresses are within 8051 code memory range (typically 0-64KB)
    for (var address in memory.keys) {
      if (address < 0 || address > 0xFFFF) {
        throw FormatException('Address out of range for 8051: 0x${address.toRadixString(16)}');
      }
    }
    
    return memory;
  }
}
