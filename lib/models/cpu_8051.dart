/// 8051 Microcontroller CPU Emulator
/// Instruction-accurate (not cycle-accurate) implementation for educational use
class Cpu8051 {
  // ============================================================================
  // Memory and Registers
  // ============================================================================
  
  /// Internal RAM: 256 bytes (00-7F direct, 80-FF SFR area)
  final List<int> ram = List.filled(256, 0);
  
  /// External RAM: 64KB (accessed via MOVX instructions)
  final List<int> xram = List.filled(65536, 0);
  
  /// Program memory (code): 64KB max
  final Map<int, int> programMemory = {};
  
  /// Special Function Registers (mapped to 0x80-0xFF in RAM)
  int get regA => ram[0xE0]; // Accumulator
  set regA(int val) => ram[0xE0] = val & 0xFF;
  
  int get regB => ram[0xF0]; // B register
  set regB(int val) => ram[0xF0] = val & 0xFF;
  
  int get regPSW => ram[0xD0]; // Program Status Word
  set regPSW(int val) => ram[0xD0] = val & 0xFF;
  
  int get regSP => ram[0x81]; // Stack Pointer
  set regSP(int val) => ram[0x81] = val & 0xFF;
  
  int get regDPL => ram[0x82]; // Data Pointer Low
  set regDPL(int val) => ram[0x82] = val & 0xFF;
  
  int get regDPH => ram[0x83]; // Data Pointer High
  set regDPH(int val) => ram[0x83] = val & 0xFF;
  
  int get dptr => (regDPH << 8) | regDPL;
  set dptr(int val) {
    regDPH = (val >> 8) & 0xFF;
    regDPL = val & 0xFF;
  }
  
  /// Program Counter
  int pc = 0;
  
  /// Loaded program name
  String? loadedFileName;
  
  // ============================================================================
  // PSW Flags (bit positions in PSW register)
  // ============================================================================
  
  bool get flagC => (regPSW & 0x80) != 0; // Carry
  set flagC(bool val) => regPSW = val ? (regPSW | 0x80) : (regPSW & 0x7F);
  
  bool get flagAC => (regPSW & 0x40) != 0; // Auxiliary Carry
  set flagAC(bool val) => regPSW = val ? (regPSW | 0x40) : (regPSW & 0xBF);
  
  bool get flagF0 => (regPSW & 0x20) != 0; // User flag 0
  set flagF0(bool val) => regPSW = val ? (regPSW | 0x20) : (regPSW & 0xDF);
  
  int get regBank => (regPSW >> 3) & 0x03; // Register bank select (RS1, RS0)
  set regBank(int val) => regPSW = (regPSW & 0xE7) | ((val & 0x03) << 3);
  
  bool get flagOV => (regPSW & 0x04) != 0; // Overflow
  set flagOV(bool val) => regPSW = val ? (regPSW | 0x04) : (regPSW & 0xFB);
  
  bool get flagP => (regPSW & 0x01) != 0; // Parity
  
  /// Update parity flag based on accumulator
  void updateParity() {
    int bits = regA;
    int count = 0;
    for (int i = 0; i < 8; i++) {
      if ((bits & (1 << i)) != 0) count++;
    }
    regPSW = (count & 1) != 0 ? (regPSW | 0x01) : (regPSW & 0xFE);
  }
  
  // ============================================================================
  // Register Bank Access (R0-R7 based on current bank)
  // ============================================================================
  
  int getRn(int n) {
    final baseAddr = regBank * 8;
    return ram[baseAddr + (n & 0x07)];
  }
  
  void setRn(int n, int val) {
    final baseAddr = regBank * 8;
    ram[baseAddr + (n & 0x07)] = val & 0xFF;
  }
  
  // ============================================================================
  // Memory Access Helpers
  // ============================================================================
  
  /// Read from direct address (internal RAM or SFR)
  int readDirect(int addr) {
    return ram[addr & 0xFF];
  }
  
  /// Write to direct address (internal RAM or SFR)
  void writeDirect(int addr, int val) {
    ram[addr & 0xFF] = val & 0xFF;
  }
  
  /// Read from indirect address (@Ri, uses lower 128 bytes)
  int readIndirect(int addr) {
    return ram[addr & 0x7F];
  }
  
  /// Write to indirect address (@Ri, uses lower 128 bytes)
  void writeIndirect(int addr, int val) {
    ram[addr & 0x7F] = val & 0xFF;
  }
  
  /// Read from program memory
  int readProgram(int addr) {
    return programMemory[addr & 0xFFFF] ?? 0;
  }
  
  /// Fetch next byte from program memory and increment PC
  int fetch() {
    final byte = readProgram(pc);
    pc = (pc + 1) & 0xFFFF;
    return byte;
  }
  
  // ============================================================================
  // Bit Operations
  // ============================================================================
  
  /// Read bit from bit-addressable area
  bool readBit(int bitAddr) {
    if (bitAddr < 0x80) {
      // Bit-addressable RAM: 0x20-0x2F (bits 0x00-0x7F)
      final byteAddr = 0x20 + (bitAddr >> 3);
      final bitPos = bitAddr & 0x07;
      return (ram[byteAddr] & (1 << bitPos)) != 0;
    } else {
      // SFR bits: 0x80-0xFF (only SFRs divisible by 8)
      final byteAddr = bitAddr & 0xF8;
      final bitPos = bitAddr & 0x07;
      return (ram[byteAddr] & (1 << bitPos)) != 0;
    }
  }
  
  /// Write bit to bit-addressable area
  void writeBit(int bitAddr, bool val) {
    if (bitAddr < 0x80) {
      final byteAddr = 0x20 + (bitAddr >> 3);
      final bitPos = bitAddr & 0x07;
      if (val) {
        ram[byteAddr] |= (1 << bitPos);
      } else {
        ram[byteAddr] &= ~(1 << bitPos);
      }
    } else {
      final byteAddr = bitAddr & 0xF8;
      final bitPos = bitAddr & 0x07;
      if (val) {
        ram[byteAddr] |= (1 << bitPos);
      } else {
        ram[byteAddr] &= ~(1 << bitPos);
      }
    }
  }
  
  // ============================================================================
  // CPU Control
  // ============================================================================
  
  /// Reset CPU to initial state
  void reset() {
    // Clear RAM
    for (int i = 0; i < 256; i++) {
      ram[i] = 0;
    }
    
    // Clear external RAM
    for (int i = 0; i < 65536; i++) {
      xram[i] = 0;
    }
    
    // Initialize SFRs to reset values
    regSP = 0x07; // Stack starts at 0x08
    regPSW = 0x00;
    regA = 0x00;
    regB = 0x00;
    dptr = 0x0000;
    pc = 0x0000;
    
    // Port registers (not fully implemented, but set to 0xFF)
    ram[0x80] = 0xFF; // P0
    ram[0x90] = 0xFF; // P1
    ram[0xA0] = 0xFF; // P2
    ram[0xB0] = 0xFF; // P3
  }
  
  /// Load program from hex memory map
  void loadProgram(Map<int, int> hexData, String fileName) {
    programMemory.clear();
    programMemory.addAll(hexData);
    loadedFileName = fileName;
    reset();
  }
  
  /// Execute one instruction and return true if successful
  bool step() {
    if (pc >= 0x10000) return false; // PC overflow
    
    final opcode = fetch();
    executeInstruction(opcode);
    return true;
  }
  
  // ============================================================================
  // Instruction Execution
  // ============================================================================
  
  void executeInstruction(int opcode) {
    switch (opcode) {
      // NOP
      case 0x00:
        break;
      
      // AJMP addr11 (opcodes 0x01, 0x21, 0x41, 0x61, 0x81, 0xA1, 0xC1, 0xE1)
      case 0x01:
      case 0x21:
      case 0x41:
      case 0x61:
      case 0x81:
      case 0xA1:
      case 0xC1:
      case 0xE1:
        _ajmp(opcode);
        break;
      
      // LJMP addr16
      case 0x02:
        _ljmp();
        break;
      
      // RR A
      case 0x03:
        regA = ((regA >> 1) | (regA << 7)) & 0xFF;
        break;
      
      // INC A
      case 0x04:
        regA = (regA + 1) & 0xFF;
        break;
      
      // INC direct
      case 0x05:
        final addr = fetch();
        writeDirect(addr, (readDirect(addr) + 1) & 0xFF);
        break;
      
      // INC @R0, INC @R1
      case 0x06:
      case 0x07:
        final ri = getRn(opcode & 1);
        writeIndirect(ri, (readIndirect(ri) + 1) & 0xFF);
        break;
      
      // INC R0-R7
      case 0x08:
      case 0x09:
      case 0x0A:
      case 0x0B:
      case 0x0C:
      case 0x0D:
      case 0x0E:
      case 0x0F:
        final rn = opcode & 0x07;
        setRn(rn, (getRn(rn) + 1) & 0xFF);
        break;
      
      // JBC bit, rel
      case 0x10:
        _jbc();
        break;
      
      // ACALL addr11 (opcodes 0x11, 0x31, 0x51, 0x71, 0x91, 0xB1, 0xD1, 0xF1)
      case 0x11:
      case 0x31:
      case 0x51:
      case 0x71:
      case 0x91:
      case 0xB1:
      case 0xD1:
      case 0xF1:
        _acall(opcode);
        break;
      
      // LCALL addr16
      case 0x12:
        _lcall();
        break;
      
      // RRC A
      case 0x13:
        final c = flagC ? 1 : 0;
        flagC = (regA & 0x01) != 0;
        regA = ((regA >> 1) | (c << 7)) & 0xFF;
        break;
      
      // DEC A
      case 0x14:
        regA = (regA - 1) & 0xFF;
        break;
      
      // DEC direct
      case 0x15:
        final addr = fetch();
        writeDirect(addr, (readDirect(addr) - 1) & 0xFF);
        break;
      
      // DEC @R0, DEC @R1
      case 0x16:
      case 0x17:
        final ri = getRn(opcode & 1);
        writeIndirect(ri, (readIndirect(ri) - 1) & 0xFF);
        break;
      
      // DEC R0-R7
      case 0x18:
      case 0x19:
      case 0x1A:
      case 0x1B:
      case 0x1C:
      case 0x1D:
      case 0x1E:
      case 0x1F:
        final rn = opcode & 0x07;
        setRn(rn, (getRn(rn) - 1) & 0xFF);
        break;
      
      // JB bit, rel
      case 0x20:
        _jb();
        break;
      
      // RET
      case 0x22:
        _ret();
        break;
      
      // RL A
      case 0x23:
        regA = ((regA << 1) | (regA >> 7)) & 0xFF;
        break;
      
      // ADD A, #imm
      case 0x24:
        _addImm();
        break;
      
      // ADD A, direct
      case 0x25:
        _addDirect();
        break;
      
      // ADD A, @R0, ADD A, @R1
      case 0x26:
      case 0x27:
        _addIndirect(opcode & 1);
        break;
      
      // ADD A, R0-R7
      case 0x28:
      case 0x29:
      case 0x2A:
      case 0x2B:
      case 0x2C:
      case 0x2D:
      case 0x2E:
      case 0x2F:
        _addRn(opcode & 0x07);
        break;
      
      // JNB bit, rel
      case 0x30:
        _jnb();
        break;
      
      // RETI
      case 0x32:
        _ret(); // Same as RET for now (no interrupt handling)
        break;
      
      // RLC A
      case 0x33:
        final c = flagC ? 1 : 0;
        flagC = (regA & 0x80) != 0;
        regA = ((regA << 1) | c) & 0xFF;
        break;
      
      // ADDC A, #imm
      case 0x34:
        _addcImm();
        break;
      
      // ADDC A, direct
      case 0x35:
        _addcDirect();
        break;
      
      // ADDC A, @R0, ADDC A, @R1
      case 0x36:
      case 0x37:
        _addcIndirect(opcode & 1);
        break;
      
      // ADDC A, R0-R7
      case 0x38:
      case 0x39:
      case 0x3A:
      case 0x3B:
      case 0x3C:
      case 0x3D:
      case 0x3E:
      case 0x3F:
        _addcRn(opcode & 0x07);
        break;
      
      // JC rel
      case 0x40:
        _jc();
        break;
      
      // ORL direct, A
      case 0x42:
        final addr = fetch();
        writeDirect(addr, readDirect(addr) | regA);
        break;
      
      // ORL direct, #imm
      case 0x43:
        final addr = fetch();
        final imm = fetch();
        writeDirect(addr, readDirect(addr) | imm);
        break;
      
      // ORL A, #imm
      case 0x44:
        regA |= fetch();
        break;
      
      // ORL A, direct
      case 0x45:
        regA |= readDirect(fetch());
        break;
      
      // ORL A, @R0, ORL A, @R1
      case 0x46:
      case 0x47:
        regA |= readIndirect(getRn(opcode & 1));
        break;
      
      // ORL A, R0-R7
      case 0x48:
      case 0x49:
      case 0x4A:
      case 0x4B:
      case 0x4C:
      case 0x4D:
      case 0x4E:
      case 0x4F:
        regA |= getRn(opcode & 0x07);
        break;
      
      // JNC rel
      case 0x50:
        _jnc();
        break;
      
      // ANL direct, A
      case 0x52:
        final addr = fetch();
        writeDirect(addr, readDirect(addr) & regA);
        break;
      
      // ANL direct, #imm
      case 0x53:
        final addr = fetch();
        final imm = fetch();
        writeDirect(addr, readDirect(addr) & imm);
        break;
      
      // ANL A, #imm
      case 0x54:
        regA &= fetch();
        break;
      
      // ANL A, direct
      case 0x55:
        regA &= readDirect(fetch());
        break;
      
      // ANL A, @R0, ANL A, @R1
      case 0x56:
      case 0x57:
        regA &= readIndirect(getRn(opcode & 1));
        break;
      
      // ANL A, R0-R7
      case 0x58:
      case 0x59:
      case 0x5A:
      case 0x5B:
      case 0x5C:
      case 0x5D:
      case 0x5E:
      case 0x5F:
        regA &= getRn(opcode & 0x07);
        break;
      
      // JZ rel
      case 0x60:
        _jz();
        break;
      
      // XRL direct, A
      case 0x62:
        final addr = fetch();
        writeDirect(addr, readDirect(addr) ^ regA);
        break;
      
      // XRL direct, #imm
      case 0x63:
        final addr = fetch();
        final imm = fetch();
        writeDirect(addr, readDirect(addr) ^ imm);
        break;
      
      // XRL A, #imm
      case 0x64:
        regA ^= fetch();
        break;
      
      // XRL A, direct
      case 0x65:
        regA ^= readDirect(fetch());
        break;
      
      // XRL A, @R0, XRL A, @R1
      case 0x66:
      case 0x67:
        regA ^= readIndirect(getRn(opcode & 1));
        break;
      
      // XRL A, R0-R7
      case 0x68:
      case 0x69:
      case 0x6A:
      case 0x6B:
      case 0x6C:
      case 0x6D:
      case 0x6E:
      case 0x6F:
        regA ^= getRn(opcode & 0x07);
        break;
      
      // JNZ rel
      case 0x70:
        _jnz();
        break;
      
      // ORL C, bit
      case 0x72:
        flagC = flagC | readBit(fetch());
        break;
      
      // JMP @A+DPTR
      case 0x73:
        pc = (regA + dptr) & 0xFFFF;
        break;
      
      // MOV A, #imm
      case 0x74:
        regA = fetch();
        break;
      
      // MOV direct, #imm
      case 0x75:
        final addr = fetch();
        final imm = fetch();
        writeDirect(addr, imm);
        break;
      
      // MOV @R0, #imm, MOV @R1, #imm
      case 0x76:
      case 0x77:
        final ri = getRn(opcode & 1);
        writeIndirect(ri, fetch());
        break;
      
      // MOV R0-R7, #imm
      case 0x78:
      case 0x79:
      case 0x7A:
      case 0x7B:
      case 0x7C:
      case 0x7D:
      case 0x7E:
      case 0x7F:
        setRn(opcode & 0x07, fetch());
        break;
      
      // SJMP rel
      case 0x80:
        _sjmp();
        break;
      
      // ANL C, bit
      case 0x82:
        flagC = flagC & readBit(fetch());
        break;
      
      // MOVC A, @A+PC
      case 0x83:
        regA = readProgram((regA + pc) & 0xFFFF);
        break;
      
      // DIV AB
      case 0x84:
        _div();
        break;
      
      // MOV direct, direct
      case 0x85:
        final src = fetch();
        final dst = fetch();
        writeDirect(dst, readDirect(src));
        break;
      
      // MOV direct, @R0, MOV direct, @R1
      case 0x86:
      case 0x87:
        final addr = fetch();
        writeDirect(addr, readIndirect(getRn(opcode & 1)));
        break;
      
      // MOV direct, R0-R7
      case 0x88:
      case 0x89:
      case 0x8A:
      case 0x8B:
      case 0x8C:
      case 0x8D:
      case 0x8E:
      case 0x8F:
        final addr = fetch();
        writeDirect(addr, getRn(opcode & 0x07));
        break;
      
      // MOV DPTR, #imm16
      case 0x90:
        final high = fetch();
        final low = fetch();
        dptr = (high << 8) | low;
        break;
      
      // MOV bit, C
      case 0x92:
        writeBit(fetch(), flagC);
        break;
      
      // MOVC A, @A+DPTR
      case 0x93:
        regA = readProgram((regA + dptr) & 0xFFFF);
        break;
      
      // SUBB A, #imm
      case 0x94:
        _subbImm();
        break;
      
      // SUBB A, direct
      case 0x95:
        _subbDirect();
        break;
      
      // SUBB A, @R0, SUBB A, @R1
      case 0x96:
      case 0x97:
        _subbIndirect(opcode & 1);
        break;
      
      // SUBB A, R0-R7
      case 0x98:
      case 0x99:
      case 0x9A:
      case 0x9B:
      case 0x9C:
      case 0x9D:
      case 0x9E:
      case 0x9F:
        _subbRn(opcode & 0x07);
        break;
      
      // ORL C, /bit
      case 0xA0:
        flagC = flagC | (!readBit(fetch()));
        break;
      
      // MOV C, bit
      case 0xA2:
        flagC = readBit(fetch());
        break;
      
      // INC DPTR
      case 0xA3:
        dptr = (dptr + 1) & 0xFFFF;
        break;
      
      // MUL AB
      case 0xA4:
        _mul();
        break;
      
      // Reserved (treat as NOP)
      case 0xA5:
        break;
      
      // MOV @R0, direct, MOV @R1, direct
      case 0xA6:
      case 0xA7:
        final addr = fetch();
        writeIndirect(getRn(opcode & 1), readDirect(addr));
        break;
      
      // MOV R0-R7, direct
      case 0xA8:
      case 0xA9:
      case 0xAA:
      case 0xAB:
      case 0xAC:
      case 0xAD:
      case 0xAE:
      case 0xAF:
        final addr = fetch();
        setRn(opcode & 0x07, readDirect(addr));
        break;
      
      // ANL C, /bit
      case 0xB0:
        flagC = flagC & (!readBit(fetch()));
        break;
      
      // CPL bit
      case 0xB2:
        final bitAddr = fetch();
        writeBit(bitAddr, !readBit(bitAddr));
        break;
      
      // CPL C
      case 0xB3:
        flagC = !flagC;
        break;
      
      // CJNE A, #imm, rel
      case 0xB4:
        _cjneAImm();
        break;
      
      // CJNE A, direct, rel
      case 0xB5:
        _cjneADirect();
        break;
      
      // CJNE @R0, #imm, rel, CJNE @R1, #imm, rel
      case 0xB6:
      case 0xB7:
        _cjneIndirect(opcode & 1);
        break;
      
      // CJNE R0-R7, #imm, rel
      case 0xB8:
      case 0xB9:
      case 0xBA:
      case 0xBB:
      case 0xBC:
      case 0xBD:
      case 0xBE:
      case 0xBF:
        _cjneRn(opcode & 0x07);
        break;
      
      // PUSH direct
      case 0xC0:
        _push(readDirect(fetch()));
        break;
      
      // CLR bit
      case 0xC2:
        writeBit(fetch(), false);
        break;
      
      // CLR C
      case 0xC3:
        flagC = false;
        break;
      
      // SWAP A
      case 0xC4:
        regA = ((regA << 4) | (regA >> 4)) & 0xFF;
        break;
      
      // XCH A, direct
      case 0xC5:
        final addr = fetch();
        final temp = regA;
        regA = readDirect(addr);
        writeDirect(addr, temp);
        break;
      
      // XCH A, @R0, XCH A, @R1
      case 0xC6:
      case 0xC7:
        final ri = getRn(opcode & 1);
        final temp = regA;
        regA = readIndirect(ri);
        writeIndirect(ri, temp);
        break;
      
      // XCH A, R0-R7
      case 0xC8:
      case 0xC9:
      case 0xCA:
      case 0xCB:
      case 0xCC:
      case 0xCD:
      case 0xCE:
      case 0xCF:
        final rn = opcode & 0x07;
        final temp = regA;
        regA = getRn(rn);
        setRn(rn, temp);
        break;
      
      // POP direct
      case 0xD0:
        writeDirect(fetch(), _pop());
        break;
      
      // SETB bit
      case 0xD2:
        writeBit(fetch(), true);
        break;
      
      // SETB C
      case 0xD3:
        flagC = true;
        break;
      
      // DA A (Decimal Adjust)
      case 0xD4:
        _da();
        break;
      
      // DJNZ direct, rel
      case 0xD5:
        _djnzDirect();
        break;
      
      // XCHD A, @R0, XCHD A, @R1
      case 0xD6:
      case 0xD7:
        final ri = getRn(opcode & 1);
        final temp = regA & 0x0F;
        regA = (regA & 0xF0) | (readIndirect(ri) & 0x0F);
        writeIndirect(ri, (readIndirect(ri) & 0xF0) | temp);
        break;
      
      // DJNZ R0-R7, rel
      case 0xD8:
      case 0xD9:
      case 0xDA:
      case 0xDB:
      case 0xDC:
      case 0xDD:
      case 0xDE:
      case 0xDF:
        _djnzRn(opcode & 0x07);
        break;
      
      // MOVX A, @DPTR
      case 0xE0:
        regA = 0; // External memory not implemented
        break;
      
      // MOVX A, @R0, MOVX A, @R1
      case 0xE2:
      case 0xE3:
        regA = 0; // External memory not implemented
        break;
      
      // CLR A
      case 0xE4:
        regA = 0;
        break;
      
      // MOV A, direct
      case 0xE5:
        regA = readDirect(fetch());
        break;
      
      // MOV A, @R0, MOV A, @R1
      case 0xE6:
      case 0xE7:
        regA = readIndirect(getRn(opcode & 1));
        break;
      
      // MOV A, R0-R7
      case 0xE8:
      case 0xE9:
      case 0xEA:
      case 0xEB:
      case 0xEC:
      case 0xED:
      case 0xEE:
      case 0xEF:
        regA = getRn(opcode & 0x07);
        break;
      
      // MOVX @DPTR, A
      case 0xF0:
        // External memory not implemented
        break;
      
      // MOVX @R0, A, MOVX @R1, A
      case 0xF2:
      case 0xF3:
        // External memory not implemented
        break;
      
      // CPL A
      case 0xF4:
        regA = (~regA) & 0xFF;
        break;
      
      // MOV direct, A
      case 0xF5:
        writeDirect(fetch(), regA);
        break;
      
      // MOV @R0, A, MOV @R1, A
      case 0xF6:
      case 0xF7:
        writeIndirect(getRn(opcode & 1), regA);
        break;
      
      // MOV R0-R7, A
      case 0xF8:
      case 0xF9:
      case 0xFA:
      case 0xFB:
      case 0xFC:
      case 0xFD:
      case 0xFE:
      case 0xFF:
        setRn(opcode & 0x07, regA);
        break;
      
      default:
        // Unknown opcode - treat as NOP
        break;
    }
    
    // Update parity after instruction
    updateParity();
  }
  
  // ============================================================================
  // Instruction Helpers
  // ============================================================================
  
  void _push(int val) {
    regSP = (regSP + 1) & 0xFF;
    ram[regSP] = val & 0xFF;
  }
  
  int _pop() {
    final val = ram[regSP];
    regSP = (regSP - 1) & 0xFF;
    return val;
  }
  
  void _sjmp() {
    final offset = fetch();
    final rel = offset > 127 ? offset - 256 : offset;
    pc = (pc + rel) & 0xFFFF;
  }
  
  void _ljmp() {
    final high = fetch();
    final low = fetch();
    pc = (high << 8) | low;
  }
  
  void _ajmp(int opcode) {
    final addr11Low = fetch();
    final addr11 = ((opcode & 0xE0) << 3) | addr11Low;
    pc = (pc & 0xF800) | addr11;
  }
  
  void _lcall() {
    final high = fetch();
    final low = fetch();
    _push(pc & 0xFF);
    _push((pc >> 8) & 0xFF);
    pc = (high << 8) | low;
  }
  
  void _acall(int opcode) {
    final addr11Low = fetch();
    final addr11 = ((opcode & 0xE0) << 3) | addr11Low;
    _push(pc & 0xFF);
    _push((pc >> 8) & 0xFF);
    pc = (pc & 0xF800) | addr11;
  }
  
  void _ret() {
    final high = _pop();
    final low = _pop();
    pc = (high << 8) | low;
  }
  
  void _jc() {
    final offset = fetch();
    if (flagC) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _jnc() {
    final offset = fetch();
    if (!flagC) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _jz() {
    final offset = fetch();
    if (regA == 0) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _jnz() {
    final offset = fetch();
    if (regA != 0) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _jb() {
    final bitAddr = fetch();
    final offset = fetch();
    if (readBit(bitAddr)) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _jnb() {
    final bitAddr = fetch();
    final offset = fetch();
    if (!readBit(bitAddr)) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _jbc() {
    final bitAddr = fetch();
    final offset = fetch();
    if (readBit(bitAddr)) {
      writeBit(bitAddr, false);
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _addImm() {
    final imm = fetch();
    _doAdd(imm);
  }
  
  void _addDirect() {
    final val = readDirect(fetch());
    _doAdd(val);
  }
  
  void _addIndirect(int ri) {
    final val = readIndirect(getRn(ri));
    _doAdd(val);
  }
  
  void _addRn(int rn) {
    _doAdd(getRn(rn));
  }
  
  void _doAdd(int val) {
    final result = regA + val;
    flagAC = ((regA & 0x0F) + (val & 0x0F)) > 0x0F;
    flagC = result > 0xFF;
    flagOV = ((regA & 0x80) == (val & 0x80)) && ((regA & 0x80) != (result & 0x80));
    regA = result & 0xFF;
  }
  
  void _addcImm() {
    final imm = fetch();
    _doAddc(imm);
  }
  
  void _addcDirect() {
    final val = readDirect(fetch());
    _doAddc(val);
  }
  
  void _addcIndirect(int ri) {
    final val = readIndirect(getRn(ri));
    _doAddc(val);
  }
  
  void _addcRn(int rn) {
    _doAddc(getRn(rn));
  }
  
  void _doAddc(int val) {
    final c = flagC ? 1 : 0;
    final result = regA + val + c;
    flagAC = ((regA & 0x0F) + (val & 0x0F) + c) > 0x0F;
    flagC = result > 0xFF;
    flagOV = ((regA & 0x80) == (val & 0x80)) && ((regA & 0x80) != (result & 0x80));
    regA = result & 0xFF;
  }
  
  void _subbImm() {
    final imm = fetch();
    _doSubb(imm);
  }
  
  void _subbDirect() {
    final val = readDirect(fetch());
    _doSubb(val);
  }
  
  void _subbIndirect(int ri) {
    final val = readIndirect(getRn(ri));
    _doSubb(val);
  }
  
  void _subbRn(int rn) {
    _doSubb(getRn(rn));
  }
  
  void _doSubb(int val) {
    final c = flagC ? 1 : 0;
    final result = regA - val - c;
    flagAC = ((regA & 0x0F) < ((val & 0x0F) + c));
    flagC = result < 0;
    flagOV = ((regA & 0x80) != (val & 0x80)) && ((regA & 0x80) != (result & 0x80));
    regA = result & 0xFF;
  }
  
  void _mul() {
    final result = regA * regB;
    regA = result & 0xFF;
    regB = (result >> 8) & 0xFF;
    flagC = false;
    flagOV = regB != 0;
  }
  
  void _div() {
    if (regB == 0) {
      flagOV = true;
      flagC = false;
      return;
    }
    final quotient = regA ~/ regB;
    final remainder = regA % regB;
    regA = quotient & 0xFF;
    regB = remainder & 0xFF;
    flagC = false;
    flagOV = false;
  }
  
  void _da() {
    int correction = 0;
    if (flagAC || (regA & 0x0F) > 9) {
      correction += 0x06;
    }
    if (flagC || (regA > 0x99)) {
      correction += 0x60;
      flagC = true;
    }
    regA = (regA + correction) & 0xFF;
  }
  
  void _cjneAImm() {
    final imm = fetch();
    final offset = fetch();
    flagC = regA < imm;
    if (regA != imm) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _cjneADirect() {
    final val = readDirect(fetch());
    final offset = fetch();
    flagC = regA < val;
    if (regA != val) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _cjneIndirect(int ri) {
    final val = readIndirect(getRn(ri));
    final imm = fetch();
    final offset = fetch();
    flagC = val < imm;
    if (val != imm) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _cjneRn(int rn) {
    final val = getRn(rn);
    final imm = fetch();
    final offset = fetch();
    flagC = val < imm;
    if (val != imm) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _djnzDirect() {
    final addr = fetch();
    final offset = fetch();
    final val = (readDirect(addr) - 1) & 0xFF;
    writeDirect(addr, val);
    if (val != 0) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  void _djnzRn(int rn) {
    final offset = fetch();
    final val = (getRn(rn) - 1) & 0xFF;
    setRn(rn, val);
    if (val != 0) {
      final rel = offset > 127 ? offset - 256 : offset;
      pc = (pc + rel) & 0xFFFF;
    }
  }
  
  // ============================================================================
  // Public API for UI
  // ============================================================================
  
  Map<String, dynamic> getRegistersMap() {
    return {
      'A': regA,
      'B': regB,
      'PSW': regPSW,
      'SP': regSP,
      'DPTR': dptr,
      'DPH': regDPH,
      'DPL': regDPL,
      'PC': pc,
      'R0': getRn(0),
      'R1': getRn(1),
      'R2': getRn(2),
      'R3': getRn(3),
      'R4': getRn(4),
      'R5': getRn(5),
      'R6': getRn(6),
      'R7': getRn(7),
      'Bank': regBank,
      'C': flagC,
      'AC': flagAC,
      'F0': flagF0,
      'OV': flagOV,
      'P': flagP,
    };
  }
  
  List<int> getRamCopy() {
    return List.from(ram);
  }
  
  List<int> getXramCopy() {
    return List.from(xram);
  }
  
  void writeRam(int address, int value) {
    if (address >= 0 && address < 256) {
      ram[address] = value & 0xFF;
    }
  }
  
  void writeXram(int address, int value) {
    if (address >= 0 && address < 65536) {
      xram[address] = value & 0xFF;
    }
  }
  
  Map<int, int> getProgramMemoryCopy() {
    return Map.from(programMemory);
  }
}
