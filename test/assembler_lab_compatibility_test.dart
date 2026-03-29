import 'package:flutter_test/flutter_test.dart';
import 'package:simulator_8051/utils/assembler.dart';

void main() {
  group('Lab manual compatibility', () {
    final assembler = Assembler8051();

    final programs = <String, String>{
  'Experiment 1 register to register move': '''
ORG 00H
MOV R1, #12H
MOV A, R1
MOV R2, A
END
''',
  'Experiment 2 I-RAM location move': '''
ORG 00H
MOV 40H, #13H
MOV A, 40H
MOV 50H, A
END
''',
  'Experiment 3 E-RAM location move': '''
ORG 00H
MOV DPTR, #6200H
MOVX A, @DPTR
MOV DPTR, #6300H
MOVX @DPTR, A
END
''',
  'Experiment 4 E-RAM to I-RAM and reverse': '''
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
''',
  'Experiment 5 exchange data between registers': '''
ORG 00H
MOV R0, #44H
MOV R1, #55H
MOV A, R0
XCH A, R1
MOV R0, A
END
''',
  'Experiment 6 exchange data between I-RAM locations': '''
ORG 00H
MOV 40H, #88H
MOV 50H, #99H
MOV A, 40H
XCH A, 50H
MOV 40H, A
END
''',
  'Experiment 7 add two 8-bit numbers in I-RAM': '''
ORG 00H
MOV R0, #50H
MOV A, @R0
INC R0
ADD A, @R0
INC R0
MOV @R0, A
INC R0
JC TOP1
MOV A, #00H
MOV @R0, A
SJMP TOP2
TOP1: MOV A, #01H
MOV @R0, A
TOP2: SJMP TOP2
END
''',
  'Experiment 8 add two 8-bit numbers in E-RAM': '''
ORG 00H
MOV DPTR, #8300H
MOVX A, @DPTR
MOV R1, A
INC DPTR
MOVX A, @DPTR
ADD A, R1
INC DPTR
MOVX @DPTR, A
INC DPTR
JC TOP1
MOV A, #00H
MOVX @DPTR, A
SJMP TOP2
TOP1: MOV A, #01H
MOVX @DPTR, A
TOP2: SJMP TOP2
END
''',
  'Experiment 9a add 16-bit numbers in I-RAM': '''
ORG 00H
MOV R0, #40H
MOV R1, #50H
MOV A, @R0
ADD A, @R1
MOV 60H, A
INC R0
INC R1
MOV A, @R0
ADDC A, @R1
MOV 61H, A
JC TOP1
MOV A, #00H
MOV 62H, A
SJMP TOP2
TOP1: MOV A, #01H
MOV 62H, A
TOP2: SJMP TOP2
END
''',
  'Experiment 9b add 16-bit numbers in E-RAM': '''
ORG 00H
MOV DPTR, #8300H
MOV R0, #40H
MOV R2, #02H
TOP1: MOVX A, @DPTR
MOV @R0, A
INC DPTR
INC R0
DJNZ R2, TOP1
MOV R1, #50H
MOV R2, #02H
TOP2: MOVX A, @DPTR
MOV @R1, A
INC DPTR
INC R1
DJNZ R2, TOP2
MOV R0, #40H
MOV R1, #50H
MOV A, @R0
ADD A, @R1
MOVX @DPTR, A
INC DPTR
INC R0
INC R1
MOV A, @R0
ADDC A, @R1
MOVX @DPTR, A
INC DPTR
JC TOP3
MOV A, #00H
MOVX @DPTR, A
SJMP TOP4
TOP3: MOV A, #01H
MOVX @DPTR, A
TOP4: SJMP TOP4
END
''',
  'Experiment 10 subtract two register values': '''
ORG 00H
MOV R1, #34H
MOV R2, #28H
CLR C
MOV A, R1
SUBB A, R2
MOV 40H, A
END
''',
  'Experiment 11a subtract two I-RAM values': '''
ORG 00H
MOV R0, #50H
CLR C
MOV A, @R0
INC R0
SUBB A, @R0
INC R0
MOV @R0, A
END
''',
  'Experiment 11b subtract two E-RAM values': '''
ORG 00H
MOV DPTR, #8300H
MOVX A, @DPTR
MOV R1, A
INC DPTR
MOVX A, @DPTR
CLR C
SUBB A, R1
INC DPTR
MOVX @DPTR, A
END
''',
  'Experiment 12a multiply in I-RAM': '''
ORG 00H
MOV R0, #50H
MOV A, @R0
MOV B, A
INC R0
MOV A, @R0
MUL AB
INC R0
MOV @R0, A
INC R0
MOV A, B
MOV @R0, A
END
''',
  'Experiment 12b multiply in E-RAM': '''
ORG 00H
MOV DPTR, #8300H
MOVX A, @DPTR
MOV B, A
INC DPTR
MOVX A, @DPTR
MUL AB
INC DPTR
MOVX @DPTR, A
INC DPTR
MOV A, B
MOVX @DPTR, A
END
''',
  'Experiment 13a divide in I-RAM': '''
ORG 00H
MOV R0, #50H
MOV A, @R0
MOV B, A
INC R0
MOV A, @R0
DIV AB
INC R0
MOV @R0, A
INC R0
MOV A, B
MOV @R0, A
END
''',
  'Experiment 13b divide in E-RAM': '''
ORG 00H
MOV DPTR, #8300H
MOVX A, @DPTR
MOV B, A
INC DPTR
MOVX A, @DPTR
DIV AB
INC DPTR
MOVX @DPTR, A
INC DPTR
MOV A, B
MOVX @DPTR, A
END
''',
  'Experiment 14 mask higher nibble': '''
ORG 00H
MOV A, #54H
ANL A, #0FH
MOV R4, A
END
''',
  'Experiment 15 mask lower nibble': '''
ORG 00H
MOV A, #54H
ANL A, #0F0H
MOV R5, A
END
''',
  'Experiment 16 mask one bit': '''
ORG 00H
MOV A, #0C7H
ANL A, #0BFH
MOV R6, A
END
''',
  'Experiment 17 rotate left twice with carry set': '''
ORG 00H
MOV A, #54H
SETB C
RLC A
RLC A
MOV R5, A
END
''',
  'Experiment 18 rotate right twice with carry reset': '''
ORG 00H
MOV A, #54H
CLR C
RRC A
RRC A
MOV R5, A
END
''',
  'Experiment 19 ones and twos complement': '''
ORG 00H
MOV A, #64H
CPL A
MOV R5, A
INC A
MOV R6, A
END
''',
  'Experiment 20 block transfer I-RAM to E-RAM': '''
ORG 00H
MOV DPTR, #8500H
MOV R0, #40H
MOV R5, #0AH
TOP: MOV A, @R0
MOVX @DPTR, A
INC R0
INC DPTR
DJNZ R5, TOP
END
''',
  'Experiment 21 block transfer E-RAM to I-RAM': '''
ORG 00H
MOV DPTR, #8500H
MOV R0, #40H
MOV R5, #0AH
TOP: MOVX A, @DPTR
MOV @R0, A
INC R0
INC DPTR
DJNZ R5, TOP
END
''',
  'Experiment 22a block sum in I-RAM': '''
ORG 00H
MOV R0, #50H
MOV R4, #05H
MOV R5, #00H
MOV R6, #00H
CLR C
TOP2: MOV A, @R0
ADD A, R5
MOV R5, A
JNC TOP1
INC R6
TOP1: INC R0
DJNZ R4, TOP2
HERE: SJMP HERE
END
''',
  'Experiment 22b block sum in E-RAM': '''
ORG 00H
MOV DPTR, #8500H
MOV R4, #05H
MOV R0, #50H
TOP1: MOVX A, @DPTR
MOV @R0, A
INC DPTR
INC R0
DJNZ R4, TOP1
MOV R0, #50H
MOV R4, #05H
MOV R5, #00H
MOV R6, #00H
CLR C
TOP3: MOV A, @R0
ADD A, R5
MOV R5, A
JNC TOP2
INC R6
TOP2: INC R0
DJNZ R4, TOP3
HERE: SJMP HERE
END
''',
  'Experiment 23 number present in data block': '''
ORG 00H
MOV R0, #50H
MOV R7, #08H
MOV R5, #00H
MOV A, #12H
MOV B, A
UP: MOV A, @R0
CJNE A, B, L1
INC R5
L1: INC R0
DJNZ R7, UP
END
''',
  'Experiment 24 ascending sort pattern': '''
ORG 00H
MOV R5, #08H
L4: MOV R0, #41H
MOV R7, #07H
L3: MOV A, @R0
INC R0
MOV B, @R0
CJNE A, B, L1
SJMP L2
L1: JC L2
MOV @R0, A
DEC R0
MOV @R0, B
INC R0
L2: DJNZ R7, L3
DJNZ R5, L4
HERE: SJMP HERE
END
''',
  'Experiment 25 descending sort pattern': '''
ORG 00H
MOV R5, #08H
L4: MOV R0, #41H
MOV R7, #07H
L3: MOV A, @R0
INC R0
MOV B, @R0
CJNE A, B, L1
SJMP L2
L1: JNC L2
MOV @R0, A
DEC R0
MOV @R0, B
INC R0
L2: DJNZ R7, L3
DJNZ R5, L4
HERE: SJMP HERE
END
''',
  'Experiment 26 up-down hex counter': '''
ORG 00H
MOV A, #00H
BACK: ACALL DELAY
INC A
JNZ BACK
BACK1: ACALL DELAY
DEC A
JNZ BACK1
HERE: SJMP HERE
DELAY: MOV R2, #0FFH
L3: MOV R3, #0FFH
L2: MOV R4, #04FH
L1: DJNZ R4, L1
DJNZ R3, L2
DJNZ R2, L3
RET
END
''',
  'Experiment 27a delay using instructions': '''
ORG 00H
MOV R1, #0E5H
HERE: DJNZ R1, HERE
RET
END
''',
  'Experiment 27b delay using timer': '''
ORG 00H
MOV TMOD, #10H
MOV TL1, #00H
MOV TH1, #0EEH
SETB TR1
WAIT: JNB TF1, WAIT
CLR TR1
CLR TF1
END
''',
    };

    programs.forEach((name, program) {
  test(name, () {
    final result = assembler.assemble(program);
    expect(result.success, isTrue, reason: result.errors.join('\n'));
  });
    });
  });
}
