.MODEL SMALL

.STACK 100H

.DATA
	tmpa1_1 DW ?
	tmpb1_1 DW ?
	tmpexpr1_1 DW ?
	tmpfactor1_1 DW ?
	tmplogic_expr1_1 DW ?
	tmprel_expr1_1 DW ?
	tmpsimple_expr1_1 DW ?
	tmpterm1_1 DW ?
	tmpc1_1 DW 3 DUP<?>
	address DW ?
	printData DW 0
.CODE 
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	MOV AX, 2
	ADD AX, 3
	MOV tmpsimple_expr1_1, AX
	MOV AX, 1
	MOV BX, tmpsimple_expr1_1
	IMUL BX
	MOV tmpterm1_1, AX
	MOV AX, tmpterm1_1
	CWD
	MOV BX, 3
IDIV BX
	MOV tmpterm1_1, DX
	MOV AX, 1*(2+3)%3
	MOV tmpa1_1, AX
	MOV AX, 1
	CMP AX, 5
	JL LB0
	MOV AX, 0
	JMP LB1
	LB0:
	MOV AX, 1
	LB1:
	MOV AX, 1<5
	MOV tmpb1_1, AX
	MOV BX, 0
	ADD BX,BX
	MOV AX, 2
	MOV tmpc1_1[BX], AX
	MOV tmpexpr1_1, AX
	MOV AX, tmpa1_1
	CMP AX, 0
	JE LB2
	MOV AX, tmpb1_1
	CMP AX, 0
	JE LB2
	MOV AX, 1
	MOV tmplogic_expr1_1, AX
	JMP LB3
	LB2:
	MOV AX, 0
	MOV tmplogic_expr1_1, AX
	LB3:
	MOV AX, tmplogic_expr1_1
	CMP AX, 0
	JE LB4
	MOV BX, 0
	ADD BX,BX
	INC tmpc1_1[BX]
	MOV AX, tmpc1_1[BX]
	MOV tmpfactor1_1, AX
	JMP LB5
	LB4:
	MOV BX, 0
	ADD BX,BX
	MOV BX, 1
	ADD BX,BX
	MOV AX, c[0]
	MOV tmpc1_1[BX], AX
	MOV tmpexpr1_1, AX
	LB5:
	MOV AX, tmpa1_1
	MOV printData, AX
	CALL PRINTF
	MOV AX, tmpb1_1
	MOV printData, AX
	CALL PRINTF

	MOV AH, 4CH
	INT 21H
PRINTF PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
XOR CX, CX
MOV BX, 10D
MOV AX, printData
CMP AX, 0H
JGE @REPEAT
MOV DL, '-'
PUSH AX
MOV AH, 02H
INT 21H
POP AX
NEG AX
@REPEAT:
XOR DX, DX
DIV BX
PUSH DX
INC CX
OR AX, AX
JNE @REPEAT
MOV AH, 02H
@PRINT:
POP DX
OR DL, 30H
INT 21H
LOOP @PRINT
POP DX
POP CX
POP BX
POP AX
RET
OUTDEC ENDP
END MAIN
