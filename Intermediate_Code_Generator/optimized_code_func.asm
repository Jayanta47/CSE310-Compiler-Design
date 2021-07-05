.MODEL SMALL
.STACK 100H
.DATA
	NL EQU 0AH
	CR EQU 0DH
	tmpa1_1 DW ?
	tmpa1_2 DW ?
	tmpa1_3 DW ?
	tmpb1_2 DW ?
	tmpb1_3 DW ?
	tmpfactor1_2 DW ?
	tmpfactor1_3 DW ?
	tmpsimple_expr1_2 DW ?
	tmpterm1_1 DW ?
	tmpx1_2 DW ?
	address DW ?
	printData DW 0
.CODE 
f PROC
	POP address
	POP tmpa1_1
	MOV AX, 2
	MOV BX, tmpa1_1
	IMUL BX
	MOV tmpterm1_1, AX
	PUSH tmpterm1_1
	JMP @RETURN
	MOV AX, 9
	MOV tmpa1_1, AX
f ENDP
g PROC
	POP address
	POP tmpb1_2
	POP tmpa1_2
	PUSH AX
	PUSH BX
	PUSH address
	PUSH tmpa1_2
	CALL f
	POP tmpfactor1_2
	POP address
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	ADD AX, tmpa1_2
	MOV tmpsimple_expr1_2, AX
	ADD AX, tmpb1_2
	MOV tmpsimple_expr1_2, AX
	MOV tmpx1_2, AX
	PUSH tmpx1_2
	JMP @RETURN
g ENDP
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	MOV AX, 1
	MOV tmpa1_3, AX
	MOV AX, 2
	MOV tmpb1_3, AX
	PUSH AX
	PUSH BX
	PUSH tmpa1_3
	PUSH tmpb1_3
	CALL g
	POP tmpfactor1_3
	POP BX
	POP AX
	MOV AX, tmpfactor1_3
	MOV tmpa1_3, AX
	PUSH AX
	CALL PRINTF
	JMP @EXITLABEL

	@EXITLABEL:
	MOV AH, 4CH
	INT 21H
	@RETURN:
	PUSH address
	RET
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

