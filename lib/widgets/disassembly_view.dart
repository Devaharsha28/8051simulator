import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/simulator_provider.dart';

class DisassemblyView extends StatefulWidget {
  const DisassemblyView({super.key});

  @override
  State<DisassemblyView> createState() => _DisassemblyViewState();
}

class _DisassemblyViewState extends State<DisassemblyView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final simulator = context.watch<SimulatorProvider>();
    final disassembly = simulator.getDisassembly(maxLines: 200);
    final theme = Theme.of(context);
    
    // Auto-scroll to current PC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPC(disassembly);
    });
    
    if (disassembly.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code_off,
              size: 64,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No program loaded',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Load a .hex file to start',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.code,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Disassembly',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${disassembly.length} instructions',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Toolbar - compact and IDE-like
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFF3F3F3),
            border: Border(
              bottom: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF333333)
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Run/Pause button - primary action
              IconButton.filled(
                onPressed: simulator.isProgramLoaded ? simulator.toggleRun : null,
                icon: Icon(
                  simulator.isRunning ? Icons.pause : Icons.play_arrow,
                  size: 24,
                ),
                tooltip: simulator.isRunning ? 'Pause' : 'Run',
                style: IconButton.styleFrom(
                  backgroundColor: simulator.isRunning 
                      ? const Color(0xFF666666)
                      : (theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                  foregroundColor: simulator.isRunning
                      ? Colors.white
                      : (theme.brightness == Brightness.dark ? Colors.black : Colors.white),
                ),
              ),
              const SizedBox(width: 4),
              // Step button
              IconButton(
                onPressed: simulator.isProgramLoaded && !simulator.isRunning
                    ? simulator.step
                    : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Step',
              ),
              // Reset button
              IconButton(
                onPressed: simulator.isProgramLoaded
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
                  isDense: true,
                  underline: const SizedBox.shrink(),
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
              ],
              const Spacer(),
              // PC Status chip
              if (simulator.isProgramLoaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PC: ${simulator.cpu.pc.toRadixString(16).toUpperCase().padLeft(4, '0')}H',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Disassembly list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: disassembly.length,
            itemBuilder: (context, index) {
              final line = disassembly[index];
              return _buildDisassemblyLine(context, line);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDisassemblyLine(BuildContext context, DisassemblyLine line) {
    final theme = Theme.of(context);
    final isCurrentPC = line.isCurrentPC;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      decoration: BoxDecoration(
        color: isCurrentPC 
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentPC
            ? Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // Future: could add breakpoint functionality here
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Current PC indicator
                SizedBox(
                  width: 24,
                  child: isCurrentPC
                      ? Icon(
                          Icons.arrow_right,
                          color: theme.colorScheme.primary,
                          size: 20,
                        )
                      : null,
                ),
                
                // Address
                SizedBox(
                  width: 80,
                  child: Text(
                    line.addressHex,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCurrentPC 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ),
                
                // Bytes
                SizedBox(
                  width: 100,
                  child: Text(
                    line.bytesHex,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                
                // Mnemonic
                Expanded(
                  child: Text(
                    line.mnemonic,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: isCurrentPC ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrentPC
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _scrollToCurrentPC(List<DisassemblyLine> disassembly) {
    final currentIndex = disassembly.indexWhere((line) => line.isCurrentPC);
    
    if (currentIndex != -1 && _scrollController.hasClients) {
      final position = currentIndex * 52.0; // Approximate item height
      final maxScroll = _scrollController.position.maxScrollExtent;
      final viewportHeight = _scrollController.position.viewportDimension;
      
      // Center the current instruction in view
      final targetScroll = (position - viewportHeight / 2).clamp(0.0, maxScroll);
      
      if ((targetScroll - _scrollController.offset).abs() > viewportHeight) {
        // Jump if too far
        _scrollController.jumpTo(targetScroll);
      } else {
        // Smooth scroll if nearby
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }
}
