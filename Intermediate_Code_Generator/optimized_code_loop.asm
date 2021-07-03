.MODEL SMALL
.STACK 100H
.DATA
	NL EQU 0AH
	CR EQU 0DH
	tmpa1_1 DW ?
	tmpb1_1 DW ?
	tmpi1_1 DW ?
	tmprel_expr1_1 DW ?
	address DW ?
	printData DW 0
.CODE 
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	MOV AX, 0
	MOV tmpb1_1, AX
	MOV AX, 0
	MOV tmpi1_1, AX
	LB4:
	MOV AX, tmpi1_1
	CMP AX, 4
	JL LB0
	MOV AX, 0
	MOV tmprel_expr1_1, AX
	JMP LB1
	LB0:
	MOV AX, 1
	MOV tmprel_expr1_1, AX
	LB1:
	MOV AX, tmprel_expr1_1
	CMP AX, 0
	JE LB5
	MOV AX, 3
	MOV tmpa1_1, AX
	LB2:
	MOV AX, tmpa1_1
	CMP AX, 0
	JE LB3
	DEC tmpa1_1
	INC tmpb1_1
	JMP LB2
LB3:
	INC tmpi1_1
	JMP LB4
	LB5:
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	MOV AX, tmpb1_1
	PUSH AX
	CALL PRINTF
	MOV AX, tmpi1_1
	PUSH AX
	CALL PRINTF

	MOV AH, 4CH
	INT 21H
MOV AX, ABCD
PRINTF PROC
	POP address
	POP printData
	PUSH address
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
	MOV AH, 02H
	MOV DX, NL
	INT 21H
	MOV DX, CR
	INT 21H
	POP DX
	POP CX
	POP BX
	POP AX
	RET
	PRINTF ENDP
END MAIN

