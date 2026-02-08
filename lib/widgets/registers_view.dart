import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/simulator_provider.dart';

class RegistersView extends StatelessWidget {
  const RegistersView({super.key});

  @override
  Widget build(BuildContext context) {
    final simulator = context.watch<SimulatorProvider>();
    final registers = simulator.cpu.getRegistersMap();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Registers Card
          _buildCard(
            context,
            'Main Registers',
            Column(
              children: [
                _buildRegisterRow(context, 'A', registers['A']),
                _buildRegisterRow(context, 'B', registers['B']),
                _buildRegisterRow(context, 'PC', registers['PC'], width: 4),
                _buildRegisterRow(context, 'SP', registers['SP']),
                _buildRegisterRow(context, 'DPTR', registers['DPTR'], width: 4),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // PSW Flags Card
          _buildCard(
            context,
            'PSW (Program Status Word)',
            Column(
              children: [
                _buildRegisterRow(context, 'PSW', registers['PSW']),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFlagChip(context, 'C', registers['C']),
                    _buildFlagChip(context, 'AC', registers['AC']),
                    _buildFlagChip(context, 'F0', registers['F0']),
                    _buildFlagChip(context, 'OV', registers['OV']),
                    _buildFlagChip(context, 'P', registers['P']),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRegisterRow(context, 'Bank', registers['Bank']),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Register Bank Card
          _buildCard(
            context,
            'Register Bank ${registers['Bank']} (R0-R7)',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildRegisterRow(context, 'R0', registers['R0'])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRegisterRow(context, 'R1', registers['R1'])),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildRegisterRow(context, 'R2', registers['R2'])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRegisterRow(context, 'R3', registers['R3'])),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildRegisterRow(context, 'R4', registers['R4'])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRegisterRow(context, 'R5', registers['R5'])),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildRegisterRow(context, 'R6', registers['R6'])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRegisterRow(context, 'R7', registers['R7'])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildRegisterRow(BuildContext context, String name, int? value, {int width = 2}) {
    final theme = Theme.of(context);
    final hexValue = value?.toRadixString(16).toUpperCase().padLeft(width, '0') ?? '--';
    final decValue = value?.toString() ?? '--';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0x$hexValue',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '($decValue)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlagChip(BuildContext context, String name, bool? value) {
    final theme = Theme.of(context);
    final isSet = value ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSet 
            ? theme.colorScheme.primaryContainer 
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSet 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSet 
                  ? theme.colorScheme.onPrimaryContainer 
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSet ? theme.colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: isSet 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: isSet
                ? Icon(
                    Icons.check,
                    size: 10,
                    color: theme.colorScheme.onPrimary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
