.MODEL SMALL
.STACK 100H
.DATA
	NL EQU 0AH
	CR EQU 0DH
	tmpa1_1 DW ?
	tmpb1_1 DW ?
	tmpi1_1 DW ?
	tmpj1_1 DW ?
	tmprel_expr1_1 DW ?
	tmprel_expr1_1_2 DW ?
	tmprel_expr21_1 DW ?
	tmpterm1_1_2_1 DW ?
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
	JE @EXITCOND
	DEC tmpa1_1
	INC tmpb1_1
	JMP LB2
	@EXITCOND:
	DEC tmpa1_1
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
	MOV AX, 1
	MOV tmpi1_1, AX
	LB12:
	MOV AX, tmpi1_1
	CMP AX, 4
	JLE LB6
	MOV AX, 0
	MOV tmprel_expr21_1, AX
	JMP LB7
	LB6:
	MOV AX, 1
	MOV tmprel_expr21_1, AX
	LB7:
	MOV AX, tmprel_expr21_1
	CMP AX, 0
	JE LB13
	MOV AX, 1
	MOV tmpj1_1, AX
	LB10:
	MOV AX, tmpj1_1
	CMP AX, 4
	JLE LB8
	MOV AX, 0
	MOV tmprel_expr1_1_2, AX
	JMP LB9
	LB8:
	MOV AX, 1
	MOV tmprel_expr1_1_2, AX
	LB9:
	MOV AX, tmprel_expr1_1_2
	CMP AX, 0
	JE LB11
	MOV AX, tmpi1_1
	MOV BX, tmpj1_1
	IMUL BX
	MOV tmpterm1_1_2_1, AX
	MOV AX, tmpterm1_1_2_1
	MOV tmpa1_1, AX
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	INC tmpj1_1
	JMP LB10
	LB11:
	INC tmpi1_1
	JMP LB12
	LB13:

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
