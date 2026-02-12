import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulator_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/example_programs.dart';
import '../widgets/disassembly_view.dart';
import '../widgets/registers_view.dart';
import '../widgets/memory_view.dart';
import 'editor_screen.dart';
import 'example_programs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<EditorScreenState> _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simulator = context.watch<SimulatorProvider>();
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('simulator8051'),
            Text(
              'Assembly Editor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Editor'),
            Tab(icon: Icon(Icons.code), text: 'Disassembly'),
            Tab(icon: Icon(Icons.memory), text: 'Registers'),
            Tab(icon: Icon(Icons.storage), text: 'Memory'),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          EditorScreen(key: _editorKey),
          const DisassemblyView(),
          const RegistersView(),
          const MemoryView(),
        ],
      ),
      floatingActionButton: simulator.isProgramLoaded && simulator.cpu.pc > 0
          ? FloatingActionButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Icon(Icons.edit_note),
              tooltip: 'Back to Editor',
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.memory,
                  size: 48,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  'simulator8051',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assembly Programming',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Creator Credit
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created by',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'd.devaharsha',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.code,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'github.com/Devaharsha28',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Settings section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                
                // Theme Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'SETTINGS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                ListTile(
                  leading: Icon(
                    themeProvider.themeMode == ThemeMode.light
                        ? Icons.light_mode
                        : themeProvider.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.brightness_auto,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(
                    themeProvider.themeMode == ThemeMode.light
                        ? 'Light Mode'
                        : themeProvider.themeMode == ThemeMode.dark
                            ? 'Dark Mode'
                            : 'System Default',
                  ),
                  onTap: () => _showThemeDialog(context),
                ),
                
                const Divider(height: 1),
                
                // Example Programs
                ListTile(
                  leading: const Icon(Icons.folder_special),
                  title: const Text('Example Programs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push<ExampleProgram>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExampleProgramsScreen(),
                      ),
                    );
                    if (result != null && mounted) {
                      _loadExampleProgram(context, result);
                    }
                  },
                ),
                
                const Divider(height: 1),
                
                // About
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          // Footer - Creator credit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Created by D.DevaHarsha',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _loadExampleProgram(BuildContext context, ExampleProgram program) {
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(program.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Load this program into the editor?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Load the code into editor
              _editorKey.currentState?.loadCode(program.code);
              
              // Switch to editor tab
              _tabController.animateTo(0);
              
              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loaded: ${program.name}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  void _showProgramDialog(BuildContext context, ExampleProgram program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(program.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Click \"Load\" to load this program into the editor.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _editorKey.currentState?.loadCode(program.code);
              _tabController.animateTo(0);
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('simulator8051'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write 8051 assembly code and run it directly.'),
            SizedBox(height: 16),
            Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Real-time assembly compilation'),
            Text('• Step-by-step execution'),
            Text('• Register and memory inspection'),
            Text('• Variable execution speed'),
            SizedBox(height: 16),
            Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Write your ASM code in the Editor tab'),
            Text('2. Click Run to execute'),
            Text('3. Use Step for single instruction execution'),
            Text('4. View other tabs to inspect state'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
