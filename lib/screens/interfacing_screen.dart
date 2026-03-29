import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/simulator_provider.dart';
import '../utils/web_file_download_stub.dart' if (dart.library.html) '../utils/web_file_download_web.dart' as web_download;

class InterfacingScreen extends StatefulWidget {
  const InterfacingScreen({super.key});

  @override
  State<InterfacingScreen> createState() => _InterfacingScreenState();
}

class _InterfacingScreenState extends State<InterfacingScreen> {
  final List<PlacedComponent> _placedComponents = [];
  final List<WireConnection> _connections = [];
  final GlobalKey _canvasKey = GlobalKey();
  late final List<ComponentTemplate> _catalog;
  PinRef? _selectedPin;
  String _circuitName = 'Untitled';
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _catalog = _buildCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simulator = context.watch<SimulatorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Interfacing Lab - $_circuitName${_hasUnsavedChanges ? ' *' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Circuit',
            onPressed: _clearCircuit,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load Circuit',
            onPressed: _loadCircuit,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Circuit',
            onPressed: _saveCircuit,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRunBar(theme, simulator),
          Expanded(
            child: Row(
              children: [
                _buildComponentsBar(theme),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DragTarget<ComponentTemplate>(
                        onAcceptWithDetails: (details) {
                          final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local = box.globalToLocal(details.offset);

                          final x = (local.dx - details.data.size.width / 2)
                              .clamp(0.0, constraints.maxWidth - details.data.size.width)
                              .toDouble();
                          final y = (local.dy - details.data.size.height / 2)
                              .clamp(0.0, constraints.maxHeight - details.data.size.height)
                              .toDouble();

                          setState(() {
                            _placedComponents.add(
                              PlacedComponent(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                template: details.data,
                                position: Offset(x, y),
                              ),
                            );
                            _hasUnsavedChanges = true;
                          });
                        },
                        builder: (context, _, __) {
                          return Container(
                            key: _canvasKey,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border(
                                left: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            child: Stack(
                              children: [
                                const Positioned.fill(child: _GridBackground()),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _WirePainter(
                                        connections: _connections,
                                        pinPositionFor: _pinPositionFor,
                                        selectedPin: _selectedPin,
                                      ),
                                    ),
                                  ),
                                ),
                                ..._placedComponents.map(
                                  (component) => Positioned(
                                    left: component.position.dx,
                                    top: component.position.dy,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          final maxX = constraints.maxWidth - component.template.size.width;
                                          final maxY = constraints.maxHeight - component.template.size.height;
                                          component.position = Offset(
                                            (component.position.dx + details.delta.dx).clamp(0.0, maxX),
                                            (component.position.dy + details.delta.dy).clamp(0.0, maxY),
                                          );
                                          _hasUnsavedChanges = true;
                                        });
                                      },
                                      onLongPress: () {
                                        setState(() {
                                          _connections.removeWhere(
                                            (wire) =>
                                                wire.a.componentId == component.id ||
                                                wire.b.componentId == component.id,
                                          );
                                          _placedComponents.removeWhere((c) => c.id == component.id);
                                          _hasUnsavedChanges = true;
                                        });
                                      },
                                      child: component.template.builder(
                                        component.template.size,
                                        (pinId) => _handlePinTap(
                                          PinRef(componentId: component.id, pinId: pinId),
                                        ),
                                        (pinId) => _pinLevelFor(component, pinId, simulator),
                                        (pinId) =>
                                            _selectedPin?.componentId == component.id &&
                                            _selectedPin?.pinId == pinId,
                                        _ledState(component, simulator),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_placedComponents.isEmpty)
                                  Center(
                                    child: Text(
                                      'Drag 8051 and LED to start.\nTap one pin, then another pin to connect.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunBar(ThemeData theme, SimulatorProvider simulator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: simulator.isProgramLoaded ? simulator.toggleRun : null,
            icon: Icon(simulator.isRunning ? Icons.pause : Icons.play_arrow),
            label: Text(simulator.isRunning ? 'Pause' : 'Run'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: simulator.isProgramLoaded && !simulator.isRunning ? simulator.step : null,
            icon: const Icon(Icons.skip_next),
            label: const Text('Step'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: simulator.isProgramLoaded ? simulator.reset : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              simulator.isProgramLoaded
                  ? 'Program flashed from Editor. PC: 0x${simulator.cpu.pc.toRadixString(16).toUpperCase().padLeft(4, '0')}'
                  : 'Flash/Assemble code in Editor first, then run here.',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_placedComponents.length} comps | ${_connections.length} wires',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsBar(ThemeData theme) {
    return Container(
      width: 240,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Components', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _catalog.length,
              itemBuilder: (context, i) {
                final component = _catalog[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Draggable<ComponentTemplate>(
                    data: component,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.9,
                        child: component.builder(
                          component.size,
                          (_) {},
                          (_) => false,
                          (_) => false,
                          false,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _ComponentCard(template: component),
                    ),
                    child: _ComponentCard(template: component),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              'Long-press component to delete.\nSave/load circuits as .json. * means unsaved changes.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  List<ComponentTemplate> _buildCatalog() {
    return [
      ComponentTemplate(
        type: '8051',
        name: '8051 MCU (DIP-40)',
        size: const Size(300, 390),
        builder: (size, onPinTap, pinLevelResolver, isSelected, ledOn) => _Mcu8051Component(
          size: size,
          onPinTap: onPinTap,
          pinLevelResolver: pinLevelResolver,
          isSelectedPin: isSelected,
        ),
        pinOffsetResolver: _mcu8051PinOffset,
      ),
      ComponentTemplate(
        type: 'led',
        name: 'LED',
        size: const Size(130, 90),
        builder: (size, onPinTap, pinLevelResolver, isSelected, ledOn) => _LedComponent(
          size: size,
          isOn: ledOn,
          onPinTap: onPinTap,
          isSelectedPin: isSelected,
        ),
        pinOffsetResolver: _ledPinOffset,
      ),
    ];
  }

  void _handlePinTap(PinRef pin) {
    setState(() {
      if (_selectedPin == null) {
        _selectedPin = pin;
        return;
      }

      if (_selectedPin == pin) {
        _selectedPin = null;
        return;
      }

      final existingIndex = _connections.indexWhere(
        (wire) => (wire.a == _selectedPin && wire.b == pin) || (wire.a == pin && wire.b == _selectedPin),
      );

      if (existingIndex >= 0) {
        _connections.removeAt(existingIndex);
      } else {
        _connections.add(WireConnection(a: _selectedPin!, b: pin));
      }

      _selectedPin = null;
      _hasUnsavedChanges = true;
    });
  }

  Offset _pinPositionFor(PinRef pin) {
    final component = _placedComponents.firstWhere(
      (c) => c.id == pin.componentId,
      orElse: () => PlacedComponent(id: '', template: ComponentTemplate.empty(), position: Offset.zero),
    );

    if (component.id.isEmpty) return Offset.zero;

    final local = component.template.pinOffsetResolver(component.template.size, pin.pinId);
    return component.position + local;
  }

  bool _pinLevelFor(PlacedComponent component, String pinId, SimulatorProvider simulator) {
    if (component.template.type != '8051') return false;

    final match = RegExp(r'^P([0-3])\.([0-7])$').firstMatch(pinId);
    if (match == null) return false;

    final port = int.parse(match.group(1)!);
    final bit = int.parse(match.group(2)!);
    final sfr = [0x80, 0x90, 0xA0, 0xB0][port];
    final value = simulator.cpu.readDirect(sfr);
    return ((value >> bit) & 0x01) == 1;
  }

  bool _ledState(PlacedComponent component, SimulatorProvider simulator) {
    if (component.template.type != 'led') return false;

    final ledAnode = PinRef(componentId: component.id, pinId: 'A');
    for (final wire in _connections) {
      PinRef? other;
      if (wire.a == ledAnode) other = wire.b;
      if (wire.b == ledAnode) other = wire.a;
      if (other == null) continue;

      final sourceComponent = _placedComponents.where((c) => c.id == other!.componentId).firstOrNull;
      if (sourceComponent == null) continue;
      if (_pinLevelFor(sourceComponent, other.pinId, simulator)) return true;
    }
    return false;
  }

  Future<void> _saveCircuit() async {
    try {
      final data = {
        'version': 1,
        'name': _circuitName,
        'components': _placedComponents
            .map(
              (c) => {
                'id': c.id,
                'type': c.template.type,
                'x': c.position.dx,
                'y': c.position.dy,
              },
            )
            .toList(),
        'connections': _connections
            .map(
              (w) => {
                'aComponent': w.a.componentId,
                'aPin': w.a.pinId,
                'bComponent': w.b.componentId,
                'bPin': w.b.pinId,
              },
            )
            .toList(),
      };

      final jsonText = const JsonEncoder.withIndent('  ').convert(data);
      final suggestedFileName = _suggestedFileName();

      if (kIsWeb) {
        final downloaded = await web_download.downloadTextFile(suggestedFileName, jsonText);
        if (!mounted) return;

        if (downloaded) {
          setState(() {
            _circuitName = suggestedFileName.replaceAll('.json', '');
            _hasUnsavedChanges = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Circuit saved: $suggestedFileName')),
          );
          return;
        }
      }

      final bytes = Uint8List.fromList(utf8.encode(jsonText));

      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Interfacing Circuit',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (saved == null) {
        if (kIsWeb) {
          setState(() {
            _hasUnsavedChanges = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              kIsWeb
                  ? 'Save triggered. Check browser downloads (path may be unavailable on web).'
                  : 'Save cancelled.',
            ),
          ),
        );
      } else {
        final fileName = _fileNameFromPath(saved);
        setState(() {
          _circuitName = fileName.replaceAll('.json', '');
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Circuit saved: $fileName')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save circuit: $e')),
      );
    }
  }

  Future<void> _loadCircuit() async {
    try {
      final proceed = await _confirmDiscardIfDirty();
      if (!proceed) return;

      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
        withReadStream: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      final bytes = await _readFileBytes(file);
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file bytes.')),
        );
        return;
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid circuit file format.');
      }

      final componentList = decoded['components'];
      final connectionList = decoded['connections'];
      if (componentList is! List || connectionList is! List) {
        throw const FormatException('Invalid circuit content.');
      }

      final restoredComponents = <PlacedComponent>[];
      for (final item in componentList) {
        if (item is! Map) continue;
        final type = (item['type'] ?? '').toString();
        final id = (item['id'] ?? '').toString();
        final x = (item['x'] as num?)?.toDouble() ?? 0;
        final y = (item['y'] as num?)?.toDouble() ?? 0;

        final template = _catalog.where((t) => t.type == type).firstOrNull;
        if (template == null || id.isEmpty) continue;

        restoredComponents.add(
          PlacedComponent(
            id: id,
            template: template,
            position: Offset(x, y),
          ),
        );
      }

      final restoredConnections = <WireConnection>[];
      final validIds = restoredComponents.map((e) => e.id).toSet();
      for (final item in connectionList) {
        if (item is! Map) continue;
        final aComponent = (item['aComponent'] ?? '').toString();
        final aPin = (item['aPin'] ?? '').toString();
        final bComponent = (item['bComponent'] ?? '').toString();
        final bPin = (item['bPin'] ?? '').toString();
        if (!validIds.contains(aComponent) || !validIds.contains(bComponent)) continue;
        if (aPin.isEmpty || bPin.isEmpty) continue;

        restoredConnections.add(
          WireConnection(
            a: PinRef(componentId: aComponent, pinId: aPin),
            b: PinRef(componentId: bComponent, pinId: bPin),
          ),
        );
      }

      setState(() {
        _selectedPin = null;
        _placedComponents
          ..clear()
          ..addAll(restoredComponents);
        _connections
          ..clear()
          ..addAll(restoredConnections);
        final loadedName = (decoded['name'] ?? file.name).toString().replaceAll('.json', '');
        _circuitName = loadedName.isEmpty ? 'Untitled' : loadedName;
        _hasUnsavedChanges = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Circuit loaded.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load circuit: $e')),
      );
    }
  }

  Future<void> _clearCircuit() async {
    final proceed = await _confirmDiscardIfDirty(orEmpty: _placedComponents.isNotEmpty || _connections.isNotEmpty);
    if (!proceed) return;

    setState(() {
      _selectedPin = null;
      _placedComponents.clear();
      _connections.clear();
      _circuitName = 'Untitled';
      _hasUnsavedChanges = false;
    });
  }

  Future<bool> _confirmDiscardIfDirty({bool orEmpty = false}) async {
    if (!_hasUnsavedChanges && !orEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard current circuit changes?'),
        content: const Text('Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<Uint8List?> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;

    final stream = file.readStream;
    if (stream == null) return null;

    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  String _fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    final name = parts.isEmpty ? path : parts.last;
    return name.isEmpty ? 'interfacing_circuit.json' : name;
  }

  String _suggestedFileName() {
    final trimmed = _circuitName.trim();
    final base = trimmed.isEmpty ? 'interfacing_circuit' : trimmed;
    return base.endsWith('.json') ? base : '$base.json';
  }

  static Offset _ledPinOffset(Size size, String pinId) {
    if (pinId == 'A') return Offset(0, size.height / 2);
    if (pinId == 'K') return Offset(size.width, size.height / 2);
    return Offset.zero;
  }

  static Offset _mcu8051PinOffset(Size size, String pinId) {
    const left = _Mcu8051Component.leftPins;
    const right = _Mcu8051Component.rightPins;

    final leftIndex = left.indexWhere((p) => p.pinId == pinId);
    final rightIndex = right.indexWhere((p) => p.pinId == pinId);

    const topOffset = 40.0;
    final usableHeight = (size.height - 52).clamp(1.0, 10000.0);
    final rowHeight = usableHeight / 20;

    if (leftIndex >= 0) {
      return Offset(12, topOffset + (leftIndex + 0.5) * rowHeight);
    }
    if (rightIndex >= 0) {
      return Offset(size.width - 12, topOffset + (rightIndex + 0.5) * rowHeight);
    }
    return Offset.zero;
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.template});

  final ComponentTemplate template;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewForType(template.type);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: preview.$2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(preview.$1, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                template.name,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _previewForType(String type) {
    switch (type) {
      case '8051':
        return (Icons.memory, const Color(0xFF1A1A1A));
      case 'led':
        return (Icons.lightbulb, Colors.red.shade400);
      default:
        return (Icons.widgets, Colors.blueGrey);
    }
  }
}

class _Mcu8051Component extends StatelessWidget {
  const _Mcu8051Component({
    required this.size,
    required this.onPinTap,
    required this.pinLevelResolver,
    required this.isSelectedPin,
  });

  final Size size;
  final ValueChanged<String> onPinTap;
  final bool Function(String pinId) pinLevelResolver;
  final bool Function(String pinId) isSelectedPin;

  static const List<PinSpec> leftPins = [
    PinSpec(pinId: 'P1.0', label: '1  P1.0'),
    PinSpec(pinId: 'P1.1', label: '2  P1.1'),
    PinSpec(pinId: 'P1.2', label: '3  P1.2'),
    PinSpec(pinId: 'P1.3', label: '4  P1.3'),
    PinSpec(pinId: 'P1.4', label: '5  P1.4'),
    PinSpec(pinId: 'P1.5', label: '6  P1.5'),
    PinSpec(pinId: 'P1.6', label: '7  P1.6'),
    PinSpec(pinId: 'P1.7', label: '8  P1.7'),
    PinSpec(pinId: 'RST', label: '9  RST', connectable: false),
    PinSpec(pinId: 'P3.0', label: '10 P3.0/RXD'),
    PinSpec(pinId: 'P3.1', label: '11 P3.1/TXD'),
    PinSpec(pinId: 'P3.2', label: '12 P3.2/INT0'),
    PinSpec(pinId: 'P3.3', label: '13 P3.3/INT1'),
    PinSpec(pinId: 'P3.4', label: '14 P3.4/T0'),
    PinSpec(pinId: 'P3.5', label: '15 P3.5/T1'),
    PinSpec(pinId: 'P3.6', label: '16 P3.6/WR'),
    PinSpec(pinId: 'P3.7', label: '17 P3.7/RD'),
    PinSpec(pinId: 'XTAL2', label: '18 XTAL2', connectable: false),
    PinSpec(pinId: 'XTAL1', label: '19 XTAL1', connectable: false),
    PinSpec(pinId: 'GND', label: '20 GND', connectable: false),
  ];

  static const List<PinSpec> rightPins = [
    PinSpec(pinId: 'VCC', label: '40 VCC', connectable: false),
    PinSpec(pinId: 'P0.0', label: '39 P0.0/AD0'),
    PinSpec(pinId: 'P0.1', label: '38 P0.1/AD1'),
    PinSpec(pinId: 'P0.2', label: '37 P0.2/AD2'),
    PinSpec(pinId: 'P0.3', label: '36 P0.3/AD3'),
    PinSpec(pinId: 'P0.4', label: '35 P0.4/AD4'),
    PinSpec(pinId: 'P0.5', label: '34 P0.5/AD5'),
    PinSpec(pinId: 'P0.6', label: '33 P0.6/AD6'),
    PinSpec(pinId: 'P0.7', label: '32 P0.7/AD7'),
    PinSpec(pinId: 'EA', label: '31 EA/VPP', connectable: false),
    PinSpec(pinId: 'ALE', label: '30 ALE/PROG', connectable: false),
    PinSpec(pinId: 'PSEN', label: '29 PSEN', connectable: false),
    PinSpec(pinId: 'P2.7', label: '28 P2.7/A15'),
    PinSpec(pinId: 'P2.6', label: '27 P2.6/A14'),
    PinSpec(pinId: 'P2.5', label: '26 P2.5/A13'),
    PinSpec(pinId: 'P2.4', label: '25 P2.4/A12'),
    PinSpec(pinId: 'P2.3', label: '24 P2.3/A11'),
    PinSpec(pinId: 'P2.2', label: '23 P2.2/A10'),
    PinSpec(pinId: 'P2.1', label: '22 P2.1/A9'),
    PinSpec(pinId: 'P2.0', label: '21 P2.0/A8'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            const Text(
              'AT89C51 / 8051',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _pinColumn(labels: leftPins, alignRight: false)),
                  const SizedBox(width: 10),
                  Expanded(child: _pinColumn(labels: rightPins, alignRight: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinColumn({required List<PinSpec> labels, required bool alignRight}) {
    return Column(
      children: labels
          .map(
            (pin) => Expanded(
              child: Row(
                mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (alignRight)
                    Expanded(
                      child: Text(
                        pin.label,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  GestureDetector(
                    onTap: pin.connectable ? () => onPinTap(pin.pinId) : null,
                    child: Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pin.connectable
                            ? (isSelectedPin(pin.pinId)
                                ? Colors.orange
                                : (pinLevelResolver(pin.pinId)
                                    ? Colors.greenAccent
                                    : Colors.grey.shade300))
                            : Colors.grey.shade700,
                        border: Border.all(color: Colors.black87, width: 0.5),
                      ),
                    ),
                  ),
                  if (!alignRight)
                    Expanded(
                      child: Text(
                        pin.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LedComponent extends StatelessWidget {
  const _LedComponent({
    required this.size,
    required this.isOn,
    required this.onPinTap,
    required this.isSelectedPin,
  });

  final Size size;
  final bool isOn;
  final ValueChanged<String> onPinTap;
  final bool Function(String pinId) isSelectedPin;

  @override
  Widget build(BuildContext context) {
    final glow = isOn ? Colors.redAccent : Colors.grey.shade500;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Row(
        children: [
          _pinDot('A', isSelectedPin('A')),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size.height * 0.55,
                  height: size.height * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glow,
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: isOn ? 0.7 : 0.25),
                        blurRadius: isOn ? 16 : 6,
                      ),
                    ],
                    border: Border.all(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(isOn ? 'LED ON' : 'LED OFF', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          _pinDot('K', isSelectedPin('K')),
        ],
      ),
    );
  }

  Widget _pinDot(String id, bool selected) {
    return GestureDetector(
      onTap: () => onPinTap(id),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? Colors.orange : Colors.grey.shade300,
          border: Border.all(color: Colors.black87, width: 0.8),
        ),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.6;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter({
    required this.connections,
    required this.pinPositionFor,
    required this.selectedPin,
  });

  final List<WireConnection> connections;
  final Offset Function(PinRef pin) pinPositionFor;
  final PinRef? selectedPin;

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final wire in connections) {
      final a = pinPositionFor(wire.a);
      final b = pinPositionFor(wire.b);
      if (a == Offset.zero || b == Offset.zero) continue;
      canvas.drawLine(a, b, wirePaint);
    }

    if (selectedPin != null) {
      final p = pinPositionFor(selectedPin!);
      final selPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 5, selPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WirePainter oldDelegate) {
    return oldDelegate.connections != connections || oldDelegate.selectedPin != selectedPin;
  }
}

class ComponentTemplate {
  ComponentTemplate({
    required this.type,
    required this.name,
    required this.size,
    required this.builder,
    required this.pinOffsetResolver,
  });

  factory ComponentTemplate.empty() {
    return ComponentTemplate(
      type: '',
      name: '',
      size: const Size(0, 0),
      builder: (_, __, ___, ____, _____) => const SizedBox.shrink(),
      pinOffsetResolver: (_, __) => Offset.zero,
    );
  }

  final String type;
  final String name;
  final Size size;
  final Widget Function(
    Size size,
    ValueChanged<String> onPinTap,
    bool Function(String pinId) pinLevelResolver,
    bool Function(String pinId) isSelectedPin,
    bool ledOn,
  ) builder;
  final Offset Function(Size size, String pinId) pinOffsetResolver;
}

class PlacedComponent {
  PlacedComponent({
    required this.id,
    required this.template,
    required this.position,
  });

  final String id;
  final ComponentTemplate template;
  Offset position;
}

class PinSpec {
  const PinSpec({required this.pinId, required this.label, this.connectable = true});

  final String pinId;
  final String label;
  final bool connectable;
}

class PinRef {
  const PinRef({required this.componentId, required this.pinId});

  final String componentId;
  final String pinId;

  @override
  bool operator ==(Object other) {
    return other is PinRef && other.componentId == componentId && other.pinId == pinId;
  }

  @override
  int get hashCode => Object.hash(componentId, pinId);
}

class WireConnection {
  const WireConnection({required this.a, required this.b});

  final PinRef a;
  final PinRef b;
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
