import 'package:flutter_test/flutter_test.dart';
import 'package:simulator_8051/models/cpu_8051.dart';
import 'package:simulator_8051/utils/assembler.dart';

Map<int, int> _assembleToMemory(String source) {
  final assembler = Assembler8051();
  final result = assembler.assemble(source);
  expect(result.success, isTrue, reason: result.errors.join('\n'));

  final mem = <int, int>{};
  for (final line in result.code) {
    for (var i = 0; i < line.bytes.length; i++) {
      mem[(line.address + i) & 0xFFFF] = line.bytes[i] & 0xFF;
    }
  }
  return mem;
}

void _runSteps(Cpu8051 cpu, int steps) {
  for (var i = 0; i < steps; i++) {
    if (!cpu.step()) {
      break;
    }
  }
}

void main() {
  group('CPU runtime compatibility for lab programs', () {
    test('E-RAM to I-RAM and I-RAM to E-RAM transfer executes correctly', () {
      const program = '''
ORG 00H
MOV DPTR, #6200H
MOV R0, #40H
MOVX A, @DPTR
MOV @R0, A
MOV R1, #50H
MOV DPTR, #6300H
MOV A, @R1
MOVX @DPTR, A
END
''';

      final cpu = Cpu8051();
      cpu.loadProgram(_assembleToMemory(program), 'exp4_runtime');

      cpu.writeXram(0x6200, 0x66);
      cpu.writeRam(0x50, 0x77);

      _runSteps(cpu, 12);

      expect(cpu.readDirect(0x40), 0x66);
      expect(cpu.getXramCopy()[0x6300], 0x77);
    });

    test('Timer1 wait loop exits when TF1 is set', () {
      const program = '''
ORG 00H
MOV TMOD, #10H
MOV TL1, #00H
MOV TH1, #0EEH
SETB TR1
WAIT: JNB TF1, WAIT
CLR TR1
CLR TF1
END
''';

      final cpu = Cpu8051();
      cpu.loadProgram(_assembleToMemory(program), 'exp27b_runtime');

      _runSteps(cpu, 7000);

      final tcon = cpu.readDirect(0x88);
      final tr1 = (tcon & 0x40) != 0;
      final tf1 = (tcon & 0x80) != 0;

      expect(tr1, isFalse, reason: 'TR1 should be cleared after wait loop exits');
      expect(tf1, isFalse, reason: 'TF1 should be cleared by CLR TF1');
      expect(cpu.pc, greaterThanOrEqualTo(17));
    });
  });
}
