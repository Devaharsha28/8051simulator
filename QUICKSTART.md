# Quick Start Guide - 8051 Simulator

## ✅ Project Successfully Created!

Your Flutter 8051 Simulator is ready to use. Here's everything you need to know.

---

## 📁 Project Structure

```
8051simulator/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   └── cpu_8051.dart            # CPU emulation (1000+ lines)
│   ├── providers/
│   │   └── simulator_provider.dart  # State management
│   ├── screens/
│   │   └── home_screen.dart         # Main UI screen
│   ├── utils/
│   │   └── hex_parser.dart          # Intel HEX parser
│   └── widgets/
│       ├── disassembly_view.dart    # Code view
│       ├── memory_view.dart         # RAM display
│       └── registers_view.dart      # Register display
├── examples/
│   └── sample_program.hex           # Test program
├── pubspec.yaml                     # Dependencies
├── README.md                        # User documentation
└── DEVELOPMENT.md                   # Developer guide

✅ All files created successfully!
✅ Dependencies installed!
```

---

## 🚀 Running the App

### 1. For Android (Recommended for first run)

```bash
# Make sure an Android device is connected or emulator is running
flutter devices

# Run in debug mode
flutter run

# Or run in release mode (faster)
flutter run --release
```

### 2. For iOS (macOS only)

```bash
# Run on simulator
flutter run -d 'iPhone 15'

# Or run on physical device
flutter run
```

### 3. For Desktop (Quick testing)

```bash
# Linux
flutter run -d linux

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

---

## 🎯 How to Use the Simulator

### Step 1: Launch the App
Run `flutter run` and wait for the app to load.

### Step 2: Load a Program
1. Tap the **folder icon** in the top-right
2. Navigate to `8051simulator/examples/`
3. Select `sample_program.hex`
4. Program will load and reset to PC=0x0000

### Step 3: Execute Code

**Single Step Execution:**
- Tap "Step" button to execute one instruction
- Watch registers and memory update in real-time
- Switch tabs to see different views

**Continuous Execution:**
- Tap "Run" to start continuous execution
- Tap "Pause" to stop
- Adjust speed with the floating button (10-1000ms)

### Step 4: View State

**Code Tab:**
- See disassembled instructions
- Current PC is highlighted with a border and arrow
- Auto-scrolls to follow execution

**Registers Tab:**
- View all registers: A, B, PC, SP, DPTR
- See PSW flags (C, AC, F0, OV, P)
- Current register bank (R0-R7)

**Memory Tab:**
- Complete 256-byte RAM view
- Changed bytes highlighted in color
- SFR area (0x80-0xFF) visually distinguished

---

## 🧪 Testing the Simulator

### Create Your Own Test Program

1. Write 8051 assembly code
2. Assemble to Intel HEX format (use any 8051 assembler)
3. Place .hex file anywhere accessible
4. Load via the app

### Sample Program Included

The included `sample_program.hex` demonstrates:
- MOV operations
- Arithmetic (ADD, SUBB)
- Loops with DJNZ
- Memory access

---

## 🎨 UI Features

### Clean, Modern Design
- ✅ Material 3 design language
- ✅ Dark/light theme (follows system)
- ✅ Monospaced fonts (JetBrains Mono)
- ✅ Smooth animations
- ✅ Responsive layout

### Color Coding
- **Blue**: Current instruction, primary actions
- **Purple/Teal**: Changed memory locations
- **Light backgrounds**: SFR regions, containers
- **Chips/Badges**: Flags, status indicators

---

## 📱 Build for Release

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS App

```bash
flutter build ios --release
```

Then open Xcode to archive and distribute.

---

## 🐛 Troubleshooting

### "No devices found"
```bash
# For Android
flutter emulators
flutter emulators --launch <emulator_id>

# Or connect physical device with USB debugging enabled
```

### "pubspec.yaml error"
```bash
flutter clean
flutter pub get
```

### "Build failed"
```bash
# Clear cache and rebuild
flutter clean
flutter pub get
flutter run
```

### File picker not working
- On Android: Grant storage permissions when prompted
- On iOS: File access is automatic
- Try restarting the app

---

## 📚 Documentation

- **README.md**: User documentation, features, usage
- **DEVELOPMENT.md**: Architecture, adding instructions, testing
- **Code comments**: Inline documentation throughout

---

## 🎓 Educational Use

### Perfect For:
- ✅ Learning 8051 microcontroller architecture
- ✅ Understanding instruction execution
- ✅ Debugging assembly programs
- ✅ Visualizing register and memory changes
- ✅ Teaching computer architecture concepts

### Limitations (V1):
- ❌ No timers/counters
- ❌ No interrupts
- ❌ No serial communication
- ❌ No external RAM
- ❌ No cycle-accurate timing

These are intentional for simplicity. Future versions may add them.

---

## 🔧 Key Dependencies

- **provider**: State management
- **file_picker**: HEX file loading
- **google_fonts**: JetBrains Mono font
- **flutter_highlight**: Syntax support (ready for future use)

---

## 🎉 Next Steps

1. **Run the app**: `flutter run`
2. **Load sample program**: Use included `sample_program.hex`
3. **Step through code**: Watch execution in real-time
4. **Create your own programs**: Write and test 8051 assembly
5. **Customize UI**: Modify themes, colors, layouts
6. **Add features**: See DEVELOPMENT.md for ideas

---

## 💡 Tips

- **Speed Control**: Tap the floating button to adjust execution speed
- **Theme**: Simulator follows system dark/light mode
- **Reset Often**: Use reset button to restart execution
- **Memory View**: Scroll to see all 256 bytes
- **Landscape Mode**: Works great for side-by-side views

---

## 📞 Need Help?

- Check **DEVELOPMENT.md** for technical details
- Review inline code comments
- Consult 8051 instruction set reference
- Debug with Flutter DevTools: `flutter run --observatory-port=9999`

---

## ✨ Features Implemented

✅ **Full 8051 CPU emulation** (instruction-accurate)  
✅ **All common instructions** (MOV, ADD, JMP, CALL, etc.)  
✅ **Intel HEX file loading** with validation  
✅ **Step-by-step execution**  
✅ **Continuous run mode** with adjustable speed  
✅ **Register display** with flags  
✅ **Memory viewer** with change highlighting  
✅ **Disassembly view** with PC tracking  
✅ **Clean Material 3 UI**  
✅ **Dark/light themes**  
✅ **Reset functionality**  
✅ **Error handling**  

---

**Ready to start!** Run `flutter run` now! 🚀
