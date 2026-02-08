import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cpu_8051.dart';
import '../utils/hex_parser.dart';
import '../utils/assembler.dart';

/// State management for the 8051 simulator
class SimulatorProvider extends ChangeNotifier {
  final Cpu8051 _cpu = Cpu8051();
  
  bool _isRunning = false;
  Timer? _runTimer;
  
  /// Execution speed in milliseconds between steps
  int _executionDelay = 100;
  
  /// Track changed memory locations for highlighting
  final Set<int> _changedMemory = {};
  final Map<int, int> _previousRam = {};
  
  /// Last error message from assembly or execution
  String? _lastError;
  
  // Getters
  Cpu8051 get cpu => _cpu;
  bool get isRunning => _isRunning;
  int get executionDelay => _executionDelay;
  Set<int> get changedMemory => _changedMemory;
  String? get lastError => _lastError;
  
  String? get loadedFileName => _cpu.loadedFileName;
  bool get isProgramLoaded => _cpu.programMemory.isNotEmpty;
  
  SimulatorProvider() {
    // Initialize with reset state
    _cpu.reset();
  }
  
  /// Load a hex file from string content
  Future<void> loadHexFile(String content, String fileName) async {
    try {
      // Stop execution if running
      if (_isRunning) {
        stop();
      }
      
      // Parse hex file
      final hexData = HexParser.parseFor8051(content);
      
      // Load into CPU
      _cpu.loadProgram(hexData, fileName);
      
      // Clear change tracking
      _changedMemory.clear();
      _previousRam.clear();
      _lastError = null;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Assemble 8051 assembly code and load into CPU
  Future<bool> assembleAndLoad(String sourceCode) async {
    try {
      // Stop execution if running
      if (_isRunning) {
        stop();
      }
      
      // Assemble the code
      final assembler = Assembler8051();
      final result = assembler.assemble(sourceCode);
      
      if (!result.success) {
        _lastError = result.errors.join('\n');
        notifyListeners();
        return false;
      }
      
      // Convert assembled code to program memory format
      final Map<int, int> programData = {};
      for (final line in result.code) {
        for (int i = 0; i < line.bytes.length; i++) {
          programData[line.address + i] = line.bytes[i];
        }
      }
      
      // Load into CPU
      _cpu.loadProgram(programData, 'Assembled Code');
      
      // Clear change tracking
      _changedMemory.clear();
      _previousRam.clear();
      _lastError = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Reset the CPU to initial state
  void reset() {
    if (_isRunning) {
      stop();
    }
    
    _cpu.reset();
    _changedMemory.clear();
    _previousRam.clear();
    
    notifyListeners();
  }
  
  /// Execute one instruction
  void step() {
    if (!isProgramLoaded) return;
    
    // Save previous RAM state for change detection
    _updatePreviousRam();
    
    // Execute one instruction
    final success = _cpu.step();
    
    // Detect changes
    _detectMemoryChanges();
    
    if (!success) {
      // PC overflow or error
      stop();
    }
    
    notifyListeners();
  }
  
  /// Start continuous execution
  void run() {
    if (_isRunning || !isProgramLoaded) return;
    
    _isRunning = true;
    _runTimer = Timer.periodic(Duration(milliseconds: _executionDelay), (timer) {
      _updatePreviousRam();
      
      final success = _cpu.step();
      
      _detectMemoryChanges();
      
      if (!success) {
        stop();
      }
      
      notifyListeners();
    });
    
    notifyListeners();
  }
  
  /// Pause/stop execution
  void stop() {
    _isRunning = false;
    _runTimer?.cancel();
    _runTimer = null;
    notifyListeners();
  }
  
  /// Toggle run/pause
  void toggleRun() {
    if (_isRunning) {
      stop();
    } else {
      run();
    }
  }
  
  /// Set execution speed
  void setExecutionDelay(int delayMs) {
    _executionDelay = delayMs.clamp(10, 2000);
    
    // Restart timer if running
    if (_isRunning) {
      stop();
      run();
    }
    
    notifyListeners();
  }
  
  /// Get disassembly for display
  List<DisassemblyLine> getDisassembly({int maxLines = 100}) {
    final lines = <DisassemblyLine>[];
    final memory = _cpu.getProgramMemoryCopy();
    
    if (memory.isEmpty) return lines;
    
    // Get sorted addresses
    final addresses = memory.keys.toList()..sort();
    
    int currentAddr = 0;
    int lineCount = 0;
    
    while (currentAddr <= 0xFFFF && lineCount < maxLines) {
      // Skip if no code at this address
      if (!memory.containsKey(currentAddr)) {
        // Try to find next address with code
        final nextAddr = addresses.firstWhere(
          (addr) => addr > currentAddr,
          orElse: () => -1,
        );
        if (nextAddr == -1) break;
        currentAddr = nextAddr;
      }
      
      final opcode = memory[currentAddr] ?? 0;
      final instrInfo = _disassembleInstruction(currentAddr, opcode, memory);
      
      lines.add(DisassemblyLine(
        address: currentAddr,
        bytes: instrInfo.bytes,
        mnemonic: instrInfo.mnemonic,
        isCurrentPC: currentAddr == _cpu.pc,
      ));
      
      currentAddr += instrInfo.length;
      lineCount++;
    }
    
    return lines;
  }
  
  /// Save previous RAM state
  void _updatePreviousRam() {
    _previousRam.clear();
    for (int i = 0; i < 256; i++) {
      _previousRam[i] = _cpu.ram[i];
    }
  }
  
  /// Detect which memory locations changed
  void _detectMemoryChanges() {
    _changedMemory.clear();
    for (int i = 0; i < 256; i++) {
      if (_previousRam[i] != _cpu.ram[i]) {
        _changedMemory.add(i);
      }
    }
  }
  
  /// Disassemble a single instruction
  InstructionInfo _disassembleInstruction(int addr, int opcode, Map<int, int> memory) {
    int getByte(int offset) => memory[addr + offset] ?? 0;
    
    switch (opcode) {
      case 0x00: return InstructionInfo(1, [opcode], 'NOP');
      
      // AJMP
      case 0x01: case 0x21: case 0x41: case 0x61: case 0x81: case 0xA1: case 0xC1: case 0xE1:
        final b1 = getByte(1);
        final addr11 = ((opcode & 0xE0) << 3) | b1;
        return InstructionInfo(2, [opcode, b1], 'AJMP 0x${addr11.toRadixString(16).toUpperCase().padLeft(3, '0')}');
      
      case 0x02:
        final h = getByte(1), l = getByte(2);
        return InstructionInfo(3, [opcode, h, l], 'LJMP 0x${((h << 8) | l).toRadixString(16).toUpperCase().padLeft(4, '0')}');
      
      case 0x03: return InstructionInfo(1, [opcode], 'RR A');
      case 0x04: return InstructionInfo(1, [opcode], 'INC A');
      
      case 0x05:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'INC 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x06: return InstructionInfo(1, [opcode], 'INC @R0');
      case 0x07: return InstructionInfo(1, [opcode], 'INC @R1');
      
      case 0x08: case 0x09: case 0x0A: case 0x0B: case 0x0C: case 0x0D: case 0x0E: case 0x0F:
        return InstructionInfo(1, [opcode], 'INC R${opcode & 7}');
      
      case 0x10:
        final b = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, b, r], 'JBC 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      // ACALL
      case 0x11: case 0x31: case 0x51: case 0x71: case 0x91: case 0xB1: case 0xD1: case 0xF1:
        final b1 = getByte(1);
        final addr11 = ((opcode & 0xE0) << 3) | b1;
        return InstructionInfo(2, [opcode, b1], 'ACALL 0x${addr11.toRadixString(16).toUpperCase().padLeft(3, '0')}');
      
      case 0x12:
        final h = getByte(1), l = getByte(2);
        return InstructionInfo(3, [opcode, h, l], 'LCALL 0x${((h << 8) | l).toRadixString(16).toUpperCase().padLeft(4, '0')}');
      
      case 0x13: return InstructionInfo(1, [opcode], 'RRC A');
      case 0x14: return InstructionInfo(1, [opcode], 'DEC A');
      
      case 0x15:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'DEC 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x16: return InstructionInfo(1, [opcode], 'DEC @R0');
      case 0x17: return InstructionInfo(1, [opcode], 'DEC @R1');
      
      case 0x18: case 0x19: case 0x1A: case 0x1B: case 0x1C: case 0x1D: case 0x1E: case 0x1F:
        return InstructionInfo(1, [opcode], 'DEC R${opcode & 7}');
      
      case 0x20:
        final b = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, b, r], 'JB 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x22: return InstructionInfo(1, [opcode], 'RET');
      case 0x23: return InstructionInfo(1, [opcode], 'RL A');
      
      case 0x24:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'ADD A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x25:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'ADD A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x26: return InstructionInfo(1, [opcode], 'ADD A, @R0');
      case 0x27: return InstructionInfo(1, [opcode], 'ADD A, @R1');
      
      case 0x28: case 0x29: case 0x2A: case 0x2B: case 0x2C: case 0x2D: case 0x2E: case 0x2F:
        return InstructionInfo(1, [opcode], 'ADD A, R${opcode & 7}');
      
      case 0x30:
        final b = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, b, r], 'JNB 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x32: return InstructionInfo(1, [opcode], 'RETI');
      case 0x33: return InstructionInfo(1, [opcode], 'RLC A');
      
      case 0x34:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'ADDC A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x35:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'ADDC A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x36: return InstructionInfo(1, [opcode], 'ADDC A, @R0');
      case 0x37: return InstructionInfo(1, [opcode], 'ADDC A, @R1');
      
      case 0x38: case 0x39: case 0x3A: case 0x3B: case 0x3C: case 0x3D: case 0x3E: case 0x3F:
        return InstructionInfo(1, [opcode], 'ADDC A, R${opcode & 7}');
      
      case 0x40:
        final r = getByte(1);
        return InstructionInfo(2, [opcode, r], 'JC 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x42:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'ORL 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, A');
      
      case 0x43:
        final d = getByte(1), imm = getByte(2);
        return InstructionInfo(3, [opcode, d, imm], 'ORL 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x44:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'ORL A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x45:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'ORL A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x46: return InstructionInfo(1, [opcode], 'ORL A, @R0');
      case 0x47: return InstructionInfo(1, [opcode], 'ORL A, @R1');
      
      case 0x48: case 0x49: case 0x4A: case 0x4B: case 0x4C: case 0x4D: case 0x4E: case 0x4F:
        return InstructionInfo(1, [opcode], 'ORL A, R${opcode & 7}');
      
      case 0x50:
        final r = getByte(1);
        return InstructionInfo(2, [opcode, r], 'JNC 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x52:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'ANL 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, A');
      
      case 0x53:
        final d = getByte(1), imm = getByte(2);
        return InstructionInfo(3, [opcode, d, imm], 'ANL 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x54:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'ANL A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x55:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'ANL A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x56: return InstructionInfo(1, [opcode], 'ANL A, @R0');
      case 0x57: return InstructionInfo(1, [opcode], 'ANL A, @R1');
      
      case 0x58: case 0x59: case 0x5A: case 0x5B: case 0x5C: case 0x5D: case 0x5E: case 0x5F:
        return InstructionInfo(1, [opcode], 'ANL A, R${opcode & 7}');
      
      case 0x60:
        final r = getByte(1);
        return InstructionInfo(2, [opcode, r], 'JZ 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x62:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'XRL 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, A');
      
      case 0x63:
        final d = getByte(1), imm = getByte(2);
        return InstructionInfo(3, [opcode, d, imm], 'XRL 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x64:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'XRL A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x65:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'XRL A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x66: return InstructionInfo(1, [opcode], 'XRL A, @R0');
      case 0x67: return InstructionInfo(1, [opcode], 'XRL A, @R1');
      
      case 0x68: case 0x69: case 0x6A: case 0x6B: case 0x6C: case 0x6D: case 0x6E: case 0x6F:
        return InstructionInfo(1, [opcode], 'XRL A, R${opcode & 7}');
      
      case 0x70:
        final r = getByte(1);
        return InstructionInfo(2, [opcode, r], 'JNZ 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x72:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'ORL C, 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x73: return InstructionInfo(1, [opcode], 'JMP @A+DPTR');
      
      case 0x74:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'MOV A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x75:
        final d = getByte(1), imm = getByte(2);
        return InstructionInfo(3, [opcode, d, imm], 'MOV 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x76:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'MOV @R0, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x77:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'MOV @R1, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x78: case 0x79: case 0x7A: case 0x7B: case 0x7C: case 0x7D: case 0x7E: case 0x7F:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'MOV R${opcode & 7}, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x80:
        final r = getByte(1);
        return InstructionInfo(2, [opcode, r], 'SJMP 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x82:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'ANL C, 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x83: return InstructionInfo(1, [opcode], 'MOVC A, @A+PC');
      case 0x84: return InstructionInfo(1, [opcode], 'DIV AB');
      
      case 0x85:
        final s = getByte(1), d = getByte(2);
        return InstructionInfo(3, [opcode, s, d], 'MOV 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${s.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x86:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, @R0');
      
      case 0x87:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, @R1');
      
      case 0x88: case 0x89: case 0x8A: case 0x8B: case 0x8C: case 0x8D: case 0x8E: case 0x8F:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, R${opcode & 7}');
      
      case 0x90:
        final h = getByte(1), l = getByte(2);
        return InstructionInfo(3, [opcode, h, l], 'MOV DPTR, #0x${((h << 8) | l).toRadixString(16).toUpperCase().padLeft(4, '0')}');
      
      case 0x92:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'MOV 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}, C');
      
      case 0x93: return InstructionInfo(1, [opcode], 'MOVC A, @A+DPTR');
      
      case 0x94:
        final imm = getByte(1);
        return InstructionInfo(2, [opcode, imm], 'SUBB A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x95:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'SUBB A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0x96: return InstructionInfo(1, [opcode], 'SUBB A, @R0');
      case 0x97: return InstructionInfo(1, [opcode], 'SUBB A, @R1');
      
      case 0x98: case 0x99: case 0x9A: case 0x9B: case 0x9C: case 0x9D: case 0x9E: case 0x9F:
        return InstructionInfo(1, [opcode], 'SUBB A, R${opcode & 7}');
      
      case 0xA0:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'ORL C, /0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xA2:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'MOV C, 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xA3: return InstructionInfo(1, [opcode], 'INC DPTR');
      case 0xA4: return InstructionInfo(1, [opcode], 'MUL AB');
      case 0xA5: return InstructionInfo(1, [opcode], 'RESERVED');
      
      case 0xA6:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV @R0, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xA7:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV @R1, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xA8: case 0xA9: case 0xAA: case 0xAB: case 0xAC: case 0xAD: case 0xAE: case 0xAF:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV R${opcode & 7}, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB0:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'ANL C, /0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB2:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'CPL 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB3: return InstructionInfo(1, [opcode], 'CPL C');
      
      case 0xB4:
        final imm = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, imm, r], 'CJNE A, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB5:
        final d = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, d, r], 'CJNE A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB6:
        final imm = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, imm, r], 'CJNE @R0, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB7:
        final imm = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, imm, r], 'CJNE @R1, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xB8: case 0xB9: case 0xBA: case 0xBB: case 0xBC: case 0xBD: case 0xBE: case 0xBF:
        final imm = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, imm, r], 'CJNE R${opcode & 7}, #0x${imm.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xC0:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'PUSH 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xC2:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'CLR 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xC3: return InstructionInfo(1, [opcode], 'CLR C');
      case 0xC4: return InstructionInfo(1, [opcode], 'SWAP A');
      
      case 0xC5:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'XCH A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xC6: return InstructionInfo(1, [opcode], 'XCH A, @R0');
      case 0xC7: return InstructionInfo(1, [opcode], 'XCH A, @R1');
      
      case 0xC8: case 0xC9: case 0xCA: case 0xCB: case 0xCC: case 0xCD: case 0xCE: case 0xCF:
        return InstructionInfo(1, [opcode], 'XCH A, R${opcode & 7}');
      
      case 0xD0:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'POP 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xD2:
        final b = getByte(1);
        return InstructionInfo(2, [opcode, b], 'SETB 0x${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xD3: return InstructionInfo(1, [opcode], 'SETB C');
      case 0xD4: return InstructionInfo(1, [opcode], 'DA A');
      
      case 0xD5:
        final d = getByte(1), r = getByte(2);
        return InstructionInfo(3, [opcode, d, r], 'DJNZ 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xD6: return InstructionInfo(1, [opcode], 'XCHD A, @R0');
      case 0xD7: return InstructionInfo(1, [opcode], 'XCHD A, @R1');
      
      case 0xD8: case 0xD9: case 0xDA: case 0xDB: case 0xDC: case 0xDD: case 0xDE: case 0xDF:
        final r = getByte(1);
        return InstructionInfo(2, [opcode, r], 'DJNZ R${opcode & 7}, 0x${r.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xE0: return InstructionInfo(1, [opcode], 'MOVX A, @DPTR');
      case 0xE2: return InstructionInfo(1, [opcode], 'MOVX A, @R0');
      case 0xE3: return InstructionInfo(1, [opcode], 'MOVX A, @R1');
      case 0xE4: return InstructionInfo(1, [opcode], 'CLR A');
      
      case 0xE5:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV A, 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      
      case 0xE6: return InstructionInfo(1, [opcode], 'MOV A, @R0');
      case 0xE7: return InstructionInfo(1, [opcode], 'MOV A, @R1');
      
      case 0xE8: case 0xE9: case 0xEA: case 0xEB: case 0xEC: case 0xED: case 0xEE: case 0xEF:
        return InstructionInfo(1, [opcode], 'MOV A, R${opcode & 7}');
      
      case 0xF0: return InstructionInfo(1, [opcode], 'MOVX @DPTR, A');
      case 0xF2: return InstructionInfo(1, [opcode], 'MOVX @R0, A');
      case 0xF3: return InstructionInfo(1, [opcode], 'MOVX @R1, A');
      case 0xF4: return InstructionInfo(1, [opcode], 'CPL A');
      
      case 0xF5:
        final d = getByte(1);
        return InstructionInfo(2, [opcode, d], 'MOV 0x${d.toRadixString(16).toUpperCase().padLeft(2, '0')}, A');
      
      case 0xF6: return InstructionInfo(1, [opcode], 'MOV @R0, A');
      case 0xF7: return InstructionInfo(1, [opcode], 'MOV @R1, A');
      
      case 0xF8: case 0xF9: case 0xFA: case 0xFB: case 0xFC: case 0xFD: case 0xFE: case 0xFF:
        return InstructionInfo(1, [opcode], 'MOV R${opcode & 7}, A');
      
      default:
        return InstructionInfo(1, [opcode], 'UNKNOWN');
    }
  }
  
  @override
  void dispose() {
    _runTimer?.cancel();
    super.dispose();
  }
}

/// Information about a disassembled instruction
class InstructionInfo {
  final int length;
  final List<int> bytes;
  final String mnemonic;
  
  InstructionInfo(this.length, this.bytes, this.mnemonic);
}

/// Represents a line in the disassembly view
class DisassemblyLine {
  final int address;
  final List<int> bytes;
  final String mnemonic;
  final bool isCurrentPC;
  
  DisassemblyLine({
    required this.address,
    required this.bytes,
    required this.mnemonic,
    required this.isCurrentPC,
  });
  
  String get bytesHex => bytes.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
  String get addressHex => '0x${address.toRadixString(16).toUpperCase().padLeft(4, '0')}';
}
