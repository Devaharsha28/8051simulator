class ExampleProgram {
  final String name;
  final String description;
  final String code;

  ExampleProgram({
    required this.name,
    required this.description,
    required this.code,
  });
}

class ExamplePrograms {
  static List<ExampleProgram> getAll() {
    return [
      ExampleProgram(
        name: 'LED Blink',
        description: 'Simple LED blinking on P1.0',
        code: '''
; LED Blink Program
; Blinks an LED connected to P1.0

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
''',
      ),
      ExampleProgram(
        name: 'Counter 0-9',
        description: 'Count from 0 to 9 on P1',
        code: '''
; Counter Program
; Counts from 0 to 9 on Port 1

ORG 0000H
    LJMP START

ORG 0030H
START:
    MOV R0, #00H       ; Initialize counter to 0

LOOP:
    MOV P1, R0         ; Output counter to Port 1
    ACALL DELAY        ; Delay
    INC R0             ; Increment counter
    CJNE R0, #0AH, LOOP ; Compare with 10, loop if not equal
    MOV R0, #00H       ; Reset counter to 0
    SJMP LOOP          ; Continue

DELAY:
    MOV R2, #0FFH
D1: MOV R3, #0FFH
D2: DJNZ R3, D2
    DJNZ R2, D1
    RET

END
''',
      ),
      ExampleProgram(
        name: 'Addition',
        description: 'Add two numbers and store result',
        code: '''
; Addition Program
; Add two 8-bit numbers

ORG 0000H
    LJMP MAIN

ORG 0030H
MAIN:
    MOV A, #25H        ; Load first number (37 decimal)
    MOV R0, #1AH       ; Load second number (26 decimal)
    ADD A, R0          ; Add R0 to A
    MOV R1, A          ; Store result in R1
    
    ; Result is now in R1 (63 decimal = 3FH)
DONE:
    SJMP DONE          ; Infinite loop

END
''',
      ),
      ExampleProgram(
        name: 'Array Sum',
        description: 'Calculate sum of array elements',
        code: '''
; Array Sum Program
; Sum 5 numbers stored in internal RAM

ORG 0000H
    LJMP START

ORG 0030H
START:
    ; Store array values in RAM (30H-34H)
    MOV 30H, #10H      ; 16
    MOV 31H, #20H      ; 32
    MOV 32H, #30H      ; 48
    MOV 33H, #15H      ; 21
    MOV 34H, #0AH      ; 10
    
    ; Initialize
    MOV R0, #30H       ; Pointer to array start
    MOV R2, #05H       ; Counter (5 elements)
    MOV A, #00H        ; Clear accumulator
    
SUM_LOOP:
    ADD A, @R0         ; Add array element to A
    INC R0             ; Move to next element
    DJNZ R2, SUM_LOOP  ; Decrement counter and loop
    
    MOV R7, A          ; Store final sum in R7
    ; Result in R7 = 127 (7FH)

DONE:
    SJMP DONE

END
''',
      ),
      ExampleProgram(
        name: 'Multiplication',
        description: 'Multiply two 8-bit numbers',
        code: '''
; Multiplication Program
; Multiply two 8-bit numbers

ORG 0000H
    LJMP MAIN

ORG 0030H
MAIN:
    MOV A, #0CH        ; First number (12)
    MOV B, #05H        ; Second number (5)
    MUL AB             ; Multiply A and B
    ; Result: A = low byte, B = high byte
    MOV R0, A          ; Store low byte in R0 (60 = 3CH)
    MOV R1, B          ; Store high byte in R1 (0)

DONE:
    SJMP DONE

END
''',
      ),
      ExampleProgram(
        name: 'Traffic Light',
        description: 'Simulate traffic light sequence',
        code: '''
; Traffic Light Controller
; Simulates traffic light on P1
; P1.0 = Red, P1.1 = Yellow, P1.2 = Green

ORG 0000H
    LJMP START

ORG 0030H
START:
    MOV P1, #00H       ; Initialize all lights off

TRAFFIC_LOOP:
    ; Green light
    MOV P1, #04H       ; P1.2 = 1 (Green on)
    ACALL LONG_DELAY
    
    ; Yellow light
    MOV P1, #02H       ; P1.1 = 1 (Yellow on)
    ACALL SHORT_DELAY
    
    ; Red light
    MOV P1, #01H       ; P1.0 = 1 (Red on)
    ACALL LONG_DELAY
    
    SJMP TRAFFIC_LOOP  ; Repeat sequence

LONG_DELAY:
    MOV R4, #05H       ; Long delay (5x)
LD1: ACALL SHORT_DELAY
    DJNZ R4, LD1
    RET

SHORT_DELAY:
    MOV R2, #0FFH
SD1: MOV R3, #0FFH
SD2: DJNZ R3, SD2
    DJNZ R2, SD1
    RET

END
''',
      ),
      ExampleProgram(
        name: 'Find Maximum',
        description: 'Find largest number in array',
        code: '''
; Find Maximum Program
; Find the largest number in an array

ORG 0000H
    LJMP START

ORG 0030H
START:
    ; Store array values
    MOV 40H, #15H      ; 21
    MOV 41H, #3AH      ; 58
    MOV 42H, #22H      ; 34
    MOV 43H, #4FH      ; 79 (maximum)
    MOV 44H, #1CH      ; 28
    
    ; Initialize
    MOV R0, #40H       ; Pointer to array
    MOV A, @R0         ; Load first element as max
    MOV R2, #04H       ; Remaining elements
    INC R0             ; Move to next element
    
FIND_MAX:
    MOV R3, A          ; Save current max
    MOV A, @R0         ; Load next element
    CLR C              ; Clear carry
    SUBB A, R3         ; Compare with current max
    JC NOT_MAX         ; If carry, current is smaller
    MOV A, @R0         ; Load the larger value
NOT_MAX:
    MOV A, R3          ; Restore max if needed
    MOV A, @R0
    SUBB A, R3
    JNC UPDATE_MAX
    MOV A, R3
    SJMP NEXT
UPDATE_MAX:
    MOV A, @R0
NEXT:
    INC R0             ; Next element
    DJNZ R2, FIND_MAX  ; Continue loop
    
    MOV R7, A          ; Store maximum in R7

DONE:
    SJMP DONE

END
''',
      ),
      ExampleProgram(
        name: 'Binary to BCD',
        description: 'Convert binary number to BCD',
        code: '''
; Binary to BCD Conversion
; Convert 8-bit binary to BCD

ORG 0000H
    LJMP START

ORG 0030H
START:
    MOV A, #9FH        ; Binary number (159 decimal)
    MOV B, #0AH        ; Divisor (10)
    
    DIV AB             ; A = quotient, B = remainder
    MOV R0, B          ; Store ones digit in R0
    
    MOV B, #0AH        ; Divisor (10) again
    DIV AB             ; A = quotient, B = remainder  
    MOV R1, B          ; Store tens digit in R1
    MOV R2, A          ; Store hundreds digit in R2
    
    ; Result: R2=1, R1=5, R2=9 (159 in BCD)

DONE:
    SJMP DONE

END
''',
      ),
    ];
  }
}
