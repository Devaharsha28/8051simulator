# 8051 Simulator - Development Guide

## Architecture Overview

### Core Components

#### 1. CPU Emulation (`models/cpu_8051.dart`)
The heart of the simulator implementing the 8051 microcontroller:

- **Memory Model**:
  - 256 bytes internal RAM (0x00-0xFF)
  - 64KB program memory (code space)
  - Special Function Registers (SFRs) mapped to 0x80-0xFF

- **Registers**:
  - A (Accumulator) at 0xE0
  - B at 0xF0
  - PSW (Program Status Word) at 0xD0
  - SP (Stack Pointer) at 0x81
  - DPTR (Data Pointer) at 0x82-0x83
  - PC (Program Counter) - 16-bit
  - Register banks R0-R7 (4 banks selectable via PSW)

- **Instruction Execution**:
  - `step()`: Executes one instruction
  - `fetch()`: Reads next byte from program memory and increments PC
  - `executeInstruction()`: Decodes and executes opcode
  - Individual helper methods for complex instructions

#### 2. State Management (`providers/simulator_provider.dart`)
Uses Flutter Provider pattern for reactive state updates:

- **Main Functions**:
  - `loadHexFile()`: Parses and loads Intel HEX
  - `reset()`: Resets CPU to initial state
  - `step()`: Single instruction execution
  - `run()`/`stop()`: Continuous execution control
  - `getDisassembly()`: Generates human-readable instruction listing

- **Change Detection**:
  - Tracks memory changes between steps
  - Highlights modified RAM locations in UI

#### 3. Intel HEX Parser (`utils/hex_parser.dart`)
Parses standard Intel HEX format:

- Supports record types: 00 (data), 01 (EOF), 02, 04 (extended addressing)
- Validates checksums
- Returns address-to-byte mapping
- Throws `FormatException` on invalid input

### UI Architecture

#### Material 3 Design
The app uses Material 3 with:
- Adaptive color schemes (light/dark)
- Rounded corners (12px border radius)
- Elevated cards with subtle borders
- Consistent spacing (multiples of 4/8)

#### Screen Layout (`screens/home_screen.dart`)
```
AppBar (file name + actions)
  ├─ Load button
  ├─ Reset button
  └─ Tab bar (Code | Registers | Memory)

Body (TabBarView)
  ├─ DisassemblyView
  ├─ RegistersView
  └─ MemoryView

BottomNavigationBar (controls)
  ├─ Step button
  └─ Run/Pause button (primary)

FloatingActionButton
  └─ Speed control
```

#### Widget Details

**DisassemblyView**:
- Auto-scrolls to current PC
- Highlights executing instruction with border
- Shows address, hex bytes, and mnemonic
- Monospaced font (JetBrains Mono)

**RegistersView**:
- Grouped cards: Main Registers, PSW Flags, Register Bank
- Hex and decimal display for values
- Visual flag indicators (chips with checkmarks)
- Shows current register bank (0-3)

**MemoryView**:
- 16×16 grid showing all 256 bytes
- Column/row headers for addressing
- Highlights changed bytes with colored background
- Distinguishes SFR area (0x80-0xFF)

## Instruction Implementation Guide

### Adding New Instructions

1. **Identify opcode** from 8051 instruction set reference
2. **Add case** in `executeInstruction()` switch statement
3. **Implement helper** method if complex (e.g., `_doAdd()`)
4. **Update flags** (C, AC, OV, P) as per specification
5. **Add disassembly** in `SimulatorProvider._disassembleInstruction()`

Example pattern for arithmetic:
```dart
void _doAdd(int val) {
  final result = regA + val;
  flagAC = ((regA & 0x0F) + (val & 0x0F)) > 0x0F;
  flagC = result > 0xFF;
  flagOV = ((regA & 0x80) == (val & 0x80)) && 
           ((regA & 0x80) != (result & 0x80));
  regA = result & 0xFF;
}
```

### Flag Update Rules

- **Carry (C)**: Set on unsigned overflow
- **Auxiliary Carry (AC)**: Set on lower nibble overflow
- **Overflow (OV)**: Set on signed overflow
- **Parity (P)**: Auto-updated after every instruction

## Testing Strategies

### Unit Testing (Recommended)
Create tests for:
- Individual instructions
- Flag updates
- Memory access (direct/indirect)
- Branch logic
- Stack operations

### Integration Testing
Test scenarios:
1. Load valid/invalid HEX files
2. Step through sample programs
3. Continuous execution
4. Memory/register state changes
5. UI responsiveness

### Sample Test Programs
Create simple .hex files to test:
- Arithmetic operations
- Loops (DJNZ, JNZ)
- Subroutines (CALL/RET)
- Bit operations
- Memory moves

## Performance Considerations

### Current Optimizations
- Instruction decoding uses switch (O(1) lookup)
- Memory stored as List<int> (cache-friendly)
- Program memory uses Map for sparse storage
- Change detection uses Set for O(1) lookup

### Potential Improvements
- Pre-parse entire program on load
- Cache disassembly results
- Virtualize large memory displays
- Debounce UI updates during fast execution

## Future Enhancement Ideas

### V2 Features
- **Breakpoints**: Stop at specific addresses
- **Watch expressions**: Monitor memory locations
- **Timers**: Timer 0/1 simulation
- **Interrupts**: Basic interrupt handling
- **Serial**: UART simulation with virtual terminal
- **Ports**: Visual I/O port displays

### Advanced Features
- Save/restore CPU state
- Execution history/replay
- Cycle-accurate timing
- Assembler (write code in-app)
- Educational tutorials
- Hardware peripherals (LCD, keypad simulation)

## Code Style Guidelines

- Use descriptive variable names
- Prefer `final` over `var` where possible
- Keep methods focused and small
- Comment complex logic
- Use monospaced fonts for code/hex display
- Follow Material 3 design patterns
- Maintain consistent padding/spacing

## Debugging Tips

### Common Issues

**PC not advancing**:
- Check instruction length in fetch()
- Verify jump/branch calculations

**Wrong register values**:
- Check register bank calculation
- Verify direct vs. indirect addressing

**Flag issues**:
- Ensure updateParity() called after instruction
- Check signed vs. unsigned comparisons

**UI not updating**:
- Verify notifyListeners() called
- Check context.watch vs. context.read

### Debug Tools
- Use Flutter DevTools for performance
- Print CPU state after each step (debug mode)
- Add assertions for invariants
- Use breakpoints in IDE for complex logic

## Building and Deployment

### Android
```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Debug
flutter run

# Release
flutter build ios --release
```

### Required Permissions
- **Android**: `READ_EXTERNAL_STORAGE` (handled by file_picker)
- **iOS**: File access (handled by file_picker)

## Resources

- 8051 Instruction Set Reference
- Intel HEX Format Specification
- Flutter Documentation: https://flutter.dev
- Material 3 Guidelines: https://m3.material.io

## Contact & Contribution

For educational use. Contributions welcome for:
- Bug fixes
- Additional instructions
- UI improvements
- Documentation
- Test programs

---

**Happy coding!** 🎓
