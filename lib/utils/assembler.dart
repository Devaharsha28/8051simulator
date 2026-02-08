class Assembler8051 {
  Map<String, int> labels = {};
  List<AssembledLine> assembledCode = [];
  List<String> errors = [];
  int currentAddress = 0;

  // Opcode map for 8051 instructions
  static const Map<String, int> opcodes = {
    // Data Transfer
    'MOV A,Rn': 0xE8,
    'MOV A,@Ri': 0xE6,
    'MOV A,direct': 0xE5,
    'MOV A,#data': 0x74,
    'MOV Rn,A': 0xF8,
    'MOV Rn,direct': 0xA8,
    'MOV Rn,#data': 0x78,
    'MOV direct,A': 0xF5,
    'MOV direct,Rn': 0x88,
    'MOV direct,direct': 0x85,
    'MOV direct,@Ri': 0x86,
    'MOV direct,#data': 0x75,
    'MOV @Ri,A': 0xF6,
    'MOV @Ri,direct': 0xA6,
    'MOV @Ri,#data': 0x76,
    'MOV DPTR,#data16': 0x90,
    'MOVC A,@A+DPTR': 0x93,
    'MOVC A,@A+PC': 0x83,
    'MOVX A,@Ri': 0xE2,
    'MOVX A,@DPTR': 0xE0,
    'MOVX @Ri,A': 0xF2,
    'MOVX @DPTR,A': 0xF0,
    'PUSH direct': 0xC0,
    'POP direct': 0xD0,
    'XCH A,Rn': 0xC8,
    'XCH A,direct': 0xC5,
    'XCH A,@Ri': 0xC6,
    'XCHD A,@Ri': 0xD6,
    
    // Arithmetic
    'ADD A,Rn': 0x28,
    'ADD A,direct': 0x25,
    'ADD A,@Ri': 0x26,
    'ADD A,#data': 0x24,
    'ADDC A,Rn': 0x38,
    'ADDC A,direct': 0x35,
    'ADDC A,@Ri': 0x36,
    'ADDC A,#data': 0x34,
    'SUBB A,Rn': 0x98,
    'SUBB A,direct': 0x95,
    'SUBB A,@Ri': 0x96,
    'SUBB A,#data': 0x94,
    'INC A': 0x04,
    'INC Rn': 0x08,
    'INC direct': 0x05,
    'INC @Ri': 0x06,
    'INC DPTR': 0xA3,
    'DEC A': 0x14,
    'DEC Rn': 0x18,
    'DEC direct': 0x15,
    'DEC @Ri': 0x16,
    'MUL AB': 0xA4,
    'DIV AB': 0x84,
    'DA A': 0xD4,
    
    // Logical
    'ANL A,Rn': 0x58,
    'ANL A,direct': 0x55,
    'ANL A,@Ri': 0x56,
    'ANL A,#data': 0x54,
    'ANL direct,A': 0x52,
    'ANL direct,#data': 0x53,
    'ORL A,Rn': 0x48,
    'ORL A,direct': 0x45,
    'ORL A,@Ri': 0x46,
    'ORL A,#data': 0x44,
    'ORL direct,A': 0x42,
    'ORL direct,#data': 0x43,
    'XRL A,Rn': 0x68,
    'XRL A,direct': 0x65,
    'XRL A,@Ri': 0x66,
    'XRL A,#data': 0x64,
    'XRL direct,A': 0x62,
    'XRL direct,#data': 0x63,
    'CLR A': 0xE4,
    'CPL A': 0xF4,
    'RL A': 0x23,
    'RLC A': 0x33,
    'RR A': 0x03,
    'RRC A': 0x13,
    'SWAP A': 0xC4,
    
    // Bit Operations
    'CLR C': 0xC3,
    'CLR bit': 0xC2,
    'SETB C': 0xD3,
    'SETB bit': 0xD2,
    'CPL C': 0xB3,
    'CPL bit': 0xB2,
    'ANL C,bit': 0x82,
    'ANL C,/bit': 0xB0,
    'ORL C,bit': 0x72,
    'ORL C,/bit': 0xA0,
    'MOV C,bit': 0xA2,
    'MOV bit,C': 0x92,
    
    // Jumps
    'SJMP rel': 0x80,
    'LJMP addr16': 0x02,
    'AJMP addr11': 0x01,
    'JMP @A+DPTR': 0x73,
    'JZ rel': 0x60,
    'JNZ rel': 0x70,
    'JC rel': 0x40,
    'JNC rel': 0x50,
    'JB bit,rel': 0x20,
    'JNB bit,rel': 0x30,
    'JBC bit,rel': 0x10,
    'CJNE A,direct,rel': 0xB5,
    'CJNE A,#data,rel': 0xB4,
    'CJNE Rn,#data,rel': 0xB8,
    'CJNE @Ri,#data,rel': 0xB6,
    'DJNZ Rn,rel': 0xD8,
    'DJNZ direct,rel': 0xD5,
    
    // Subroutines
    'ACALL addr11': 0x11,
    'LCALL addr16': 0x12,
    'RET': 0x22,
    'RETI': 0x32,
    
    // Miscellaneous
    'NOP': 0x00,
  };

  // Special Function Register addresses
  static const Map<String, int> sfrAddresses = {
    'P0': 0x80, 'SP': 0x81, 'DPL': 0x82, 'DPH': 0x83,
    'P1': 0x90, 'P2': 0xA0, 'P3': 0xB0,
    'PSW': 0xD0, 'ACC': 0xE0, 'A': 0xE0, 'B': 0xF0,
    'IE': 0xA8, 'IP': 0xB8,
    'TCON': 0x88, 'TMOD': 0x89, 'TL0': 0x8A, 'TL1': 0x8B,
    'TH0': 0x8C, 'TH1': 0x8D,
    'SCON': 0x98, 'SBUF': 0x99,
    'PCON': 0x87,
  };

  AssembleResult assemble(String sourceCode) {
    labels.clear();
    assembledCode.clear();
    errors.clear();
    currentAddress = 0;

    final lines = sourceCode.split('\n');

    // First pass: collect labels and calculate addresses
    for (var i = 0; i < lines.length; i++) {
      final line = _cleanLine(lines[i]);
      if (line.isEmpty) continue;

      // Handle ORG directive
      if (line.toUpperCase().startsWith('ORG')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          currentAddress = _parseNumber(parts[1]);
        }
        continue;
      }

      // Handle END directive
      if (line.toUpperCase() == 'END') break;

      // Check for label
      if (line.contains(':')) {
        final labelName = line.split(':')[0].trim();
        labels[labelName.toUpperCase()] = currentAddress;
        
        // Check if there's an instruction after the label
        final afterLabel = line.split(':')[1].trim();
        if (afterLabel.isNotEmpty) {
          currentAddress += _getInstructionSize(afterLabel);
        }
      } else {
        currentAddress += _getInstructionSize(line);
      }
    }

    // Second pass: generate machine code
    currentAddress = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = _cleanLine(lines[i]);
      if (line.isEmpty) continue;

      // Handle ORG directive
      if (line.toUpperCase().startsWith('ORG')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          currentAddress = _parseNumber(parts[1]);
        }
        continue;
      }

      // Handle END directive
      if (line.toUpperCase() == 'END') break;

      // Process instruction
      String instruction = line;
      if (line.contains(':')) {
        instruction = line.split(':')[1].trim();
      }

      if (instruction.isNotEmpty) {
        try {
          final assembled = _assembleInstruction(instruction, currentAddress);
          if (assembled != null) {
            assembledCode.add(assembled);
            currentAddress = assembled.address + assembled.bytes.length;
          }
        } catch (e) {
          errors.add('Line ${i + 1}: $e');
        }
      }
    }

    return AssembleResult(
      success: errors.isEmpty,
      code: assembledCode,
      errors: errors,
    );
  }

  String _cleanLine(String line) {
    // Remove comments
    if (line.contains(';')) {
      line = line.split(';')[0];
    }
    return line.trim();
  }

  int _getInstructionSize(String instruction) {
    final normalized = _normalizeInstruction(instruction);
    
    // Check instruction pattern
    if (normalized.startsWith('LJMP') || normalized.startsWith('LCALL')) {
      return 3;
    } else if (normalized.startsWith('AJMP') || normalized.startsWith('ACALL')) {
      return 2;
    } else if (normalized.startsWith('SJMP') || normalized.startsWith('JZ') ||
               normalized.startsWith('JNZ') || normalized.startsWith('JC') ||
               normalized.startsWith('JNC') || normalized.startsWith('DJNZ')) {
      return 2;
    } else if (normalized.startsWith('JB') || normalized.startsWith('JNB') ||
               normalized.startsWith('JBC') || normalized.startsWith('CJNE')) {
      return 3;
    } else if (normalized.startsWith('MOV') && normalized.contains('DPTR')) {
      return 3;
    } else if (normalized.startsWith('MOV') && normalized.contains(',')) {
      final parts = normalized.split(',');
      if (parts.length == 2) {
        if (parts[1].contains('#') || parts[0].toUpperCase() == 'DIRECT') {
          return 2;
        } else if (parts[0].contains('DIRECT') && parts[1].contains('DIRECT')) {
          return 3;
        }
      }
      return 2;
    }
    
    return 1; // Default single-byte instruction
  }

  String _normalizeInstruction(String instruction) {
    return instruction.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  AssembledLine? _assembleInstruction(String instruction, int address) {
    final normalized = _normalizeInstruction(instruction);
    final parts = normalized.split(RegExp(r'[\s,]+'));
    final mnemonic = parts[0];

    List<int> bytes = [];

    // Handle different instruction types
    if (mnemonic == 'NOP' || mnemonic == 'RET' || mnemonic == 'RETI') {
      bytes.add(opcodes[mnemonic]!);
    } else if (mnemonic == 'MUL' || mnemonic == 'DIV') {
      // MUL AB and DIV AB - two part instructions
      if (parts.length < 2 || parts[1] != 'AB') {
        throw Exception('$mnemonic requires AB operand');
      }
      bytes.add(opcodes['$mnemonic AB']!);
    } else if (mnemonic == 'MOV') {
      bytes.addAll(_assembleMov(parts));
    } else if (mnemonic == 'LJMP' || mnemonic == 'LCALL') {
      bytes.addAll(_assembleAbsoluteJump(mnemonic, parts[1]));
    } else if (mnemonic == 'SJMP' || mnemonic == 'JZ' || mnemonic == 'JNZ' ||
               mnemonic == 'JC' || mnemonic == 'JNC') {
      bytes.addAll(_assembleRelativeJump(mnemonic, parts[1], address));
    } else if (mnemonic == 'DJNZ') {
      bytes.addAll(_assembleDjnz(parts, address));
    } else if (mnemonic == 'ACALL') {
      bytes.addAll(_assembleAcall(parts[1], address));
    } else if (mnemonic == 'SETB' || mnemonic == 'CLR') {
      bytes.addAll(_assembleBitOp(mnemonic, parts.length > 1 ? parts[1] : ''));
    } else if (mnemonic == 'INC' || mnemonic == 'DEC') {
      bytes.addAll(_assembleIncDec(mnemonic, parts[1]));
    } else if (mnemonic == 'ADD' || mnemonic == 'ADDC' || mnemonic == 'SUBB' ||
               mnemonic == 'ANL' || mnemonic == 'ORL' || mnemonic == 'XRL') {
      bytes.addAll(_assembleArithLogic(mnemonic, parts));
    } else {
      throw Exception('Unknown instruction: $mnemonic');
    }

    return AssembledLine(
      address: address,
      bytes: bytes,
      source: instruction,
    );
  }

  List<int> _assembleMov(List<String> parts) {
    if (parts.length < 3) throw Exception('MOV requires two operands');
    
    final dest = parts[1];
    final src = parts[2];

    if (dest == 'A') {
      if (src.startsWith('#')) {
        return [0x74, _parseNumber(src.substring(1))];
      } else if (_isRegister(src)) {
        return [0xE8 + _getRegisterNumber(src)];
      } else if (src.startsWith('@')) {
        return [0xE6 + _getIndirectRegister(src)];
      } else {
        return [0xE5, _getDirectAddress(src)];
      }
    } else if (_isRegister(dest)) {
      final regNum = _getRegisterNumber(dest);
      if (src == 'A') {
        return [0xF8 + regNum];
      } else if (src.startsWith('#')) {
        return [0x78 + regNum, _parseNumber(src.substring(1))];
      } else {
        return [0xA8 + regNum, _getDirectAddress(src)];
      }
    } else if (dest == 'DPTR') {
      if (src.startsWith('#')) {
        final value = _parseNumber(src.substring(1));
        return [0x90, (value >> 8) & 0xFF, value & 0xFF];
      }
    } else {
      // Direct addressing
      final destAddr = _getDirectAddress(dest);
      if (src == 'A') {
        return [0xF5, destAddr];
      } else if (src.startsWith('#')) {
        return [0x75, destAddr, _parseNumber(src.substring(1))];
      } else if (_isRegister(src)) {
        return [0x88 + _getRegisterNumber(src), destAddr];
      } else {
        return [0x85, _getDirectAddress(src), destAddr];
      }
    }

    throw Exception('Invalid MOV instruction');
  }

  List<int> _assembleAbsoluteJump(String mnemonic, String target) {
    final addr = _resolveLabel(target);
    final opcode = mnemonic == 'LJMP' ? 0x02 : 0x12;
    return [opcode, (addr >> 8) & 0xFF, addr & 0xFF];
  }

  List<int> _assembleRelativeJump(String mnemonic, String target, int currentAddr) {
    final targetAddr = _resolveLabel(target);
    final offset = targetAddr - (currentAddr + 2);
    
    if (offset < -128 || offset > 127) {
      throw Exception('Jump target out of range for relative jump');
    }
    
    int opcode = 0x80; // SJMP default
    if (mnemonic == 'JZ') opcode = 0x60;
    else if (mnemonic == 'JNZ') opcode = 0x70;
    else if (mnemonic == 'JC') opcode = 0x40;
    else if (mnemonic == 'JNC') opcode = 0x50;
    
    return [opcode, offset & 0xFF];
  }

  List<int> _assembleDjnz(List<String> parts, int currentAddr) {
    if (parts.length < 3) throw Exception('DJNZ requires two operands');
    
    final reg = parts[1];
    final target = parts[2];
    final targetAddr = _resolveLabel(target);
    final offset = targetAddr - (currentAddr + 2);
    
    if (_isRegister(reg)) {
      return [0xD8 + _getRegisterNumber(reg), offset & 0xFF];
    } else {
      return [0xD5, _getDirectAddress(reg), offset & 0xFF];
    }
  }

  List<int> _assembleAcall(String target, int currentAddr) {
    final addr = _resolveLabel(target);
    final page = (currentAddr + 2) & 0xF800;
    
    if ((addr & 0xF800) != page) {
      throw Exception('ACALL target must be within 2K page');
    }
    
    final addrOffset = addr & 0x07FF;
    final opcode = 0x11 | ((addrOffset >> 3) & 0xE0);
    return [opcode, addrOffset & 0xFF];
  }

  List<int> _assembleBitOp(String mnemonic, String operand) {
    if (operand.isEmpty || operand == 'A') {
      return [mnemonic == 'CLR' ? 0xE4 : 0x00];
    } else if (operand == 'C') {
      return [mnemonic == 'CLR' ? 0xC3 : 0xD3];
    } else {
      final bitAddr = _getBitAddress(operand);
      return [mnemonic == 'CLR' ? 0xC2 : 0xD2, bitAddr];
    }
  }

  List<int> _assembleIncDec(String mnemonic, String operand) {
    final baseOpcode = mnemonic == 'INC' ? 0x04 : 0x14;
    
    if (operand == 'A') {
      return [baseOpcode];
    } else if (operand == 'DPTR') {
      return [0xA3];
    } else if (_isRegister(operand)) {
      return [baseOpcode + 4 + _getRegisterNumber(operand)];
    } else if (operand.startsWith('@')) {
      return [baseOpcode + 2 + _getIndirectRegister(operand)];
    } else {
      return [baseOpcode + 1, _getDirectAddress(operand)];
    }
  }

  List<int> _assembleArithLogic(String mnemonic, List<String> parts) {
    if (parts.length < 3) throw Exception('$mnemonic requires two operands');
    
    final dest = parts[1];
    final src = parts[2];
    
    if (dest != 'A') throw Exception('Destination must be A for $mnemonic');
    
    int baseOpcode = 0x28;
    switch (mnemonic) {
      case 'ADD': baseOpcode = 0x28; break;
      case 'ADDC': baseOpcode = 0x38; break;
      case 'SUBB': baseOpcode = 0x98; break;
      case 'ANL': baseOpcode = 0x58; break;
      case 'ORL': baseOpcode = 0x48; break;
      case 'XRL': baseOpcode = 0x68; break;
    }
    
    if (_isRegister(src)) {
      return [baseOpcode + _getRegisterNumber(src)];
    } else if (src.startsWith('@')) {
      return [baseOpcode - 2 + _getIndirectRegister(src)];
    } else if (src.startsWith('#')) {
      return [baseOpcode - 4, _parseNumber(src.substring(1))];
    } else {
      return [baseOpcode - 3, _getDirectAddress(src)];
    }
  }

  bool _isRegister(String operand) {
    return RegExp(r'^R[0-7]$').hasMatch(operand.toUpperCase());
  }

  int _getRegisterNumber(String operand) {
    return int.parse(operand.substring(1));
  }

  int _getIndirectRegister(String operand) {
    final match = RegExp(r'@R([01])').firstMatch(operand.toUpperCase());
    if (match == null) throw Exception('Invalid indirect register: $operand');
    return int.parse(match.group(1)!);
  }

  int _getDirectAddress(String operand) {
    // Check if it's an SFR
    final sfrName = operand.toUpperCase();
    if (sfrAddresses.containsKey(sfrName)) {
      return sfrAddresses[sfrName]!;
    }
    // Otherwise parse as number
    return _parseNumber(operand);
  }

  int _getBitAddress(String operand) {
    // Handle port bit notation (e.g., P1.0)
    if (operand.contains('.')) {
      final parts = operand.split('.');
      final port = parts[0].toUpperCase();
      final bit = int.parse(parts[1]);
      
      if (sfrAddresses.containsKey(port)) {
        final baseAddr = sfrAddresses[port]!;
        return baseAddr + bit;
      }
    }
    
    return _parseNumber(operand);
  }

  int _resolveLabel(String label) {
    final upperLabel = label.toUpperCase();
    if (labels.containsKey(upperLabel)) {
      return labels[upperLabel]!;
    }
    // Try to parse as number
    return _parseNumber(label);
  }

  int _parseNumber(String value) {
    value = value.toUpperCase().trim();
    
    // Binary: 0b... or ...B
    if (value.startsWith('0B')) {
      return int.parse(value.substring(2), radix: 2);
    } else if (value.endsWith('B') && value.length > 1) {
      return int.parse(value.substring(0, value.length - 1), radix: 2);
    }
    
    // Hex: 0x... or ...H
    if (value.startsWith('0X')) {
      return int.parse(value.substring(2), radix: 16);
    } else if (value.endsWith('H')) {
      return int.parse(value.substring(0, value.length - 1), radix: 16);
    }
    
    // Decimal
    return int.parse(value);
  }
}

class AssembleResult {
  final bool success;
  final List<AssembledLine> code;
  final List<String> errors;

  AssembleResult({
    required this.success,
    required this.code,
    required this.errors,
  });
}

class AssembledLine {
  final int address;
  final List<int> bytes;
  final String source;

  AssembledLine({
    required this.address,
    required this.bytes,
    required this.source,
  });
}
