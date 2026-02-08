# 8051 Microcontroller Simulator

A clean, minimal, and functional 8051 microcontroller simulator built with Flutter for educational use.

## Features

- **Full 8051 Emulation**
  - Internal RAM: 256 bytes (direct addressing 00-7F, SFR area 80-FF)
  - Registers: A, B, PSW (with all flags), DPTR, SP, PC, R0-R7
  - Instruction-accurate emulation (not cycle-accurate)
  - Comprehensive instruction set support

- **Intel HEX File Support**
  - Load .hex files using the file picker
  - Automatic parsing and validation
  - Error handling for invalid files

- **Execution Control**
  - Step-by-step execution
  - Run/Pause continuous execution
  - Adjustable execution speed (10-1000ms)
  - Reset functionality

- **Visual Debugging**
  - **Code Tab**: Disassembly view with current PC highlighting
  - **Registers Tab**: All registers and PSW flags with hex/decimal display
  - **Memory Tab**: Complete 256-byte RAM view with change highlighting

- **Clean, Modern UI**
  - Material 3 design
  - Dark and light theme support
  - Monospaced fonts (JetBrains Mono) for code display
  - Responsive layout for portrait and landscape

## Project Structure

```
lib/
├── main.dart                      # App entry point with theming
├── models/
│   └── cpu_8051.dart              # Core CPU emulation logic
├── providers/
│   └── simulator_provider.dart    # State management with Provider
├── screens/
│   └── home_screen.dart           # Main app screen with tabs
├── utils/
│   └── hex_parser.dart            # Intel HEX file parser
└── widgets/
    ├── disassembly_view.dart      # Code disassembly display
    ├── memory_view.dart           # RAM memory viewer
    └── registers_view.dart        # Register display
```

## Getting Started

### Prerequisites

- Flutter SDK 3.2.0 or higher
- Dart 3.2.0 or higher

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Usage

1. **Load a Program**: Tap the folder icon to load an Intel HEX file
2. **Step Through**: Use the "Step" button to execute one instruction at a time
3. **Run Continuously**: Press "Run" to execute continuously (adjustable speed)
4. **View State**: Switch between Code, Registers, and Memory tabs
5. **Reset**: Use the reset button to restart from the beginning

## Supported Instructions

The simulator supports most common 8051 instructions including:

- **Data Transfer**: MOV, PUSH, POP, XCH, XCHD
- **Arithmetic**: ADD, ADDC, SUBB, INC, DEC, MUL, DIV, DA
- **Logic**: ANL, ORL, XRL, CLR, CPL, SWAP
- **Boolean**: SETB, CLR, CPL (bit operations)
- **Branching**: JMP, SJMP, LJMP, AJMP, JZ, JNZ, JC, JNC, JB, JNB, JBC, CJNE, DJNZ
- **Subroutines**: LCALL, ACALL, RET, RETI
- **Rotate**: RL, RLC, RR, RRC

## V1 Limitations (By Design)

The following features are intentionally excluded from v1 for simplicity:

- Timers/Counters
- Interrupts (hardware)
- Serial communication
- External RAM
- Port I/O functionality
- Cycle-accurate timing
- Breakpoints

These may be added in future versions based on user needs.

## Sample Programs

A sample HEX file is included in the `examples/` directory for testing:
- `blink_simulation.hex` - Simple program demonstrating basic operations

## Dependencies

- `provider: ^6.1.1` - State management
- `file_picker: ^8.0.0+1` - File selection
- `google_fonts: ^6.1.0` - Typography (JetBrains Mono)
- `flutter_highlight: ^0.7.0` - Syntax highlighting support

## Contributing

This is an educational project. Contributions, bug reports, and feature requests are welcome!

## License

This project is open source and available for educational purposes.

## Acknowledgments

Built with Flutter for cross-platform compatibility and ease of use in academic settings.
