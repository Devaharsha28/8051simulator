import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/simulator_provider.dart';

class MemoryView extends StatefulWidget {
  const MemoryView({super.key});

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Tab bar
        Container(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.storage), text: 'Internal RAM'),
              Tab(icon: Icon(Icons.cloud_circle), text: 'External RAM'),
            ],
          ),
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _InternalRamView(),
              _ExternalRamView(),
            ],
          ),
        ),
      ],
    );
  }
}

// Internal RAM View
class _InternalRamView extends StatelessWidget {
  const _InternalRamView();

  @override
  Widget build(BuildContext context) {
    final simulator = context.watch<SimulatorProvider>();
    final ram = simulator.cpu.getRamCopy();
    final changedMemory = simulator.changedMemory;
    final theme = Theme.of(context);
    
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
                Icons.memory,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Internal RAM (256 bytes) - Click to edit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (changedMemory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Changed',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Memory Grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column headers
                _buildHeaderRow(context),
                const SizedBox(height: 8),
                
                // Memory rows
                ...List.generate(16, (row) {
                  return _buildMemoryRow(context, row, ram, changedMemory);
                }),
                
                const SizedBox(height: 16),
                
                // SFR Region Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '0x80-0xFF: SFR (Special Function Registers)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        ...List.generate(16, (col) {
          return Expanded(
            child: Center(
              child: Text(
                col.toRadixString(16).toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildMemoryRow(BuildContext context, int row, List<int> ram, Set<int> changedMemory) {
    final theme = Theme.of(context);
    final baseAddress = row * 16;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Row label (address)
          SizedBox(
            width: 60,
            child: Text(
              '0x${baseAddress.toRadixString(16).toUpperCase().padLeft(2, '0')}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          
          // Memory cells
          ...List.generate(16, (col) {
            final address = baseAddress + col;
            final value = ram[address];
            final isChanged = changedMemory.contains(address);
            final isSFR = address >= 0x80;
            
            return Expanded(
              child: _buildMemoryCell(context, address, value, isChanged, isSFR),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildMemoryCell(BuildContext context, int address, int value, bool isChanged, bool isSFR) {
    final theme = Theme.of(context);
    final hexValue = value.toRadixString(16).toUpperCase().padLeft(2, '0');
    
    Color backgroundColor;
    Color textColor;
    
    if (isChanged) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      textColor = theme.colorScheme.onTertiaryContainer;
    } else if (isSFR) {
      backgroundColor = theme.colorScheme.primaryContainer.withOpacity(0.2);
      textColor = theme.colorScheme.onSurface;
    } else {
      backgroundColor = Colors.transparent;
      textColor = theme.colorScheme.onSurface;
    }
    
    return InkWell(
      onTap: () => _editMemory(context, address, value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isChanged 
                ? theme.colorScheme.tertiary 
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            hexValue,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: isChanged ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
  
  void _editMemory(BuildContext context, int address, int currentValue) {
    final controller = TextEditingController(
      text: currentValue.toRadixString(16).toUpperCase().padLeft(2, '0'),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Memory 0x${address.toRadixString(16).toUpperCase().padLeft(2, '0')}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 2,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Hex Value (00-FF)',
            counterText: '',
            prefixText: '0x',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
            UpperCaseTextFormatter(),
          ],
          onSubmitted: (value) {
            _saveMemoryValue(context, address, value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _saveMemoryValue(context, address, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _saveMemoryValue(BuildContext context, int address, String hexValue) {
    try {
      final value = int.parse(hexValue, radix: 16);
      final simulator = context.read<SimulatorProvider>();
      simulator.cpu.writeRam(address, value);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid hex value: $hexValue'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// External RAM View
class _ExternalRamView extends StatefulWidget {
  const _ExternalRamView();

  @override
  State<_ExternalRamView> createState() => _ExternalRamViewState();
}

class _ExternalRamViewState extends State<_ExternalRamView> {
  int _currentPage = 0; // 256 bytes per page, 256 pages total
  final TextEditingController _pageController = TextEditingController(text: '0');
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final simulator = context.watch<SimulatorProvider>();
    final xram = simulator.cpu.getXramCopy();
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header with page selector
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
                Icons.cloud_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'External RAM (64KB) - Click to edit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0 ? () {
                  setState(() {
                    _currentPage--;
                    _pageController.text = _currentPage.toString();
                  });
                } : null,
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _pageController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    labelText: 'Page',
                  ),
                  onSubmitted: (value) {
                    final page = int.tryParse(value) ?? 0;
                    setState(() {
                      _currentPage = page.clamp(0, 255);
                      _pageController.text = _currentPage.toString();
                    });
                  },
                ),
              ),
              Text(' / 255', style: theme.textTheme.bodySmall),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < 255 ? () {
                  setState(() {
                    _currentPage++;
                    _pageController.text = _currentPage.toString();
                  });
                } : null,
              ),
            ],
          ),
        ),
        
        // Memory Grid for current page
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column headers
                _buildHeaderRow(context),
                const SizedBox(height: 8),
                
                // Memory rows for current page (256 bytes = 16 rows)
                ...List.generate(16, (row) {
                  return _buildMemoryRow(context, row, xram, _currentPage);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        ...List.generate(16, (col) {
          return Expanded(
            child: Center(
              child: Text(
                col.toRadixString(16).toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildMemoryRow(BuildContext context, int row, List<int> memory, int page) {
    final theme = Theme.of(context);
    final baseAddress = (page * 256) + (row * 16);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Row label (address)
          SizedBox(
            width: 70,
            child: Text(
              '0x${baseAddress.toRadixString(16).toUpperCase().padLeft(4, '0')}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          
          // Memory cells
          ...List.generate(16, (col) {
            final address = baseAddress + col;
            final value = memory[address];
            
            return Expanded(
              child: _buildMemoryCell(context, address, value),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildMemoryCell(BuildContext context, int address, int value) {
    final theme = Theme.of(context);
    final hexValue = value.toRadixString(16).toUpperCase().padLeft(2, '0');
    
    return InkWell(
      onTap: () => _editMemory(context, address, value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            hexValue,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
  
  void _editMemory(BuildContext context, int address, int currentValue) {
    final controller = TextEditingController(
      text: currentValue.toRadixString(16).toUpperCase().padLeft(2, '0'),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit External RAM 0x${address.toRadixString(16).toUpperCase().padLeft(4, '0')}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 2,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Hex Value (00-FF)',
            counterText: '',
            prefixText: '0x',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
            UpperCaseTextFormatter(),
          ],
          onSubmitted: (value) {
            _saveMemoryValue(context, address, value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _saveMemoryValue(context, address, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _saveMemoryValue(BuildContext context, int address, String hexValue) {
    try {
      final value = int.parse(hexValue, radix: 16);
      final simulator = context.read<SimulatorProvider>();
      simulator.cpu.writeXram(address, value);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid hex value: $hexValue'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
