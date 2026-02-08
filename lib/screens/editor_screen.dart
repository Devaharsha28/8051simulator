import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulator_provider.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => EditorScreenState();
}

class EditorScreenState extends State<EditorScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;
  bool _isAssembling = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    // Load default example code
    _controller.text = _getDefaultCode();
    _controller.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
    });
    // Auto-assemble the default code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _assembleAndLoad();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Load code from external source (e.g., example programs)
  void loadCode(String code) {
    setState(() {
      _controller.text = code;
      _errorMessage = null;
      _hasUnsavedChanges = true;
    });
    // Auto-assemble the loaded code
    _assembleAndLoad();
  }

  String _getDefaultCode() {
    return '''
; 8051 Assembly Program Example
; This program blinks an LED on P1.0

ORG 0000H              ; Reset vector
    LJMP MAIN          ; Jump to main program

ORG 0030H              ; Main program starts here
MAIN:
    MOV P1, #00H       ; Initialize Port 1

LOOP:
    SETB P1.0          ; Turn on LED (P1.0 = 1)
    ACALL DELAY        ; Call delay routine
    CLR P1.0           ; Turn off LED (P1.0 = 0)
    ACALL DELAY        ; Call delay routine
    SJMP LOOP          ; Repeat forever

DELAY:
    MOV R0, #0FFH      ; Outer loop counter
D1: MOV R1, #0FFH      ; Inner loop counter
D2: DJNZ R1, D2        ; Decrement R1, jump if not zero
    DJNZ R0, D1        ; Decrement R0, jump if not zero
    RET                ; Return from subroutine

END
''';
  }

  void _assembleAndLoad({bool silent = false}) async {
    setState(() {
      _isAssembling = true;
      _errorMessage = null;
    });

    try {
      final simulator = context.read<SimulatorProvider>();
      final code = _controller.text;
      
      // Assemble the code
      final success = await simulator.assembleAndLoad(code);
      
      if (!success) {
        setState(() {
          _errorMessage = simulator.lastError ?? 'Failed to assemble code';
        });
      } else {
        setState(() {
          _hasUnsavedChanges = false;
        });
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ready to run!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAssembling = false;
      });
    }
  }

  void _runProgram() {
    final simulator = context.read<SimulatorProvider>();
    if (_hasUnsavedChanges || !simulator.isProgramLoaded) {
      // Auto-assemble before running
      _assembleAndLoad(silent: true);
      // Wait a bit for assembly to complete, then run
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && simulator.isProgramLoaded && !simulator.isRunning) {
          simulator.run();
        }
      });
    } else {
      simulator.toggleRun();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simulator = context.watch<SimulatorProvider>();
    
    return Column(
      children: [
        // Toolbar - compact and IDE-like
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2D2D30)
              : const Color(0xFFF3F3F3),
          child: Row(
            children: [
              // Run/Pause button - primary action
              IconButton.filled(
                onPressed: _isAssembling ? null : _runProgram,
                icon: _isAssembling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        simulator.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 24,
                      ),
                tooltip: _isAssembling 
                    ? 'Assembling...' 
                    : (simulator.isRunning ? 'Pause' : 'Run'),
                style: IconButton.styleFrom(
                  backgroundColor: simulator.isRunning 
                      ? theme.colorScheme.error 
                      : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              // Step button
              IconButton(
                onPressed: simulator.isProgramLoaded && !simulator.isRunning && !_isAssembling
                    ? () {
                        if (_hasUnsavedChanges) {
                          _assembleAndLoad(silent: true);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) simulator.step();
                          });
                        } else {
                          simulator.step();
                        }
                      }
                    : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Step',
              ),
              // Reset button
              IconButton(
                onPressed: simulator.isProgramLoaded && !_isAssembling
                    ? simulator.reset
                    : null,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset CPU',
              ),
              const VerticalDivider(width: 16),
              // Speed control - compact
              if (simulator.isProgramLoaded) ...[
                const Icon(Icons.speed, size: 18),
                const SizedBox(width: 4),
                DropdownButton<int>(
                  value: simulator.executionDelay,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10ms')),
                    DropdownMenuItem(value: 50, child: Text('50ms')),
                    DropdownMenuItem(value: 100, child: Text('100ms')),
                    DropdownMenuItem(value: 250, child: Text('250ms')),
                    DropdownMenuItem(value: 500, child: Text('500ms')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      simulator.setExecutionDelay(value);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              // Status indicator
              if (simulator.isProgramLoaded)
                Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  label: Text(
                    'PC: 0x${simulator.cpu.pc.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 8),
              // Example code button
              IconButton(
                onPressed: () {
                  _controller.text = _getDefaultCode();
                  setState(() {
                    _errorMessage = null;
                    _hasUnsavedChanges = true;
                  });
                },
                icon: const Icon(Icons.code),
                tooltip: 'Load Example',
              ),
            ],
          ),
        ),
        
        // Error message
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: theme.colorScheme.onErrorContainer,
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        
        // Code editor
        Expanded(
          child: Container(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFFAFAFA),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 14,
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFFD4D4D4)
                    : const Color(0xFF000000),
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '; Write your 8051 assembly code here...\n; Supported: All 111 standard 8051 instructions\n; Example: MOV, ADD, SUBB, INC, DEC, ANL, ORL, XRL\n;          SJMP, LJMP, ACALL, LCALL, RET, DJNZ, CJNE, etc.',
                hintStyle: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
