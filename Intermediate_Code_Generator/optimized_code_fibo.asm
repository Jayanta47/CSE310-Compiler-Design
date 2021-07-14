.MODEL SMALL
.STACK 100H
.DATA
	NL EQU 0AH
	CR EQU 0DH
	tmpa1_2 DW ?
	tmpfactor1_1 DW ?
	tmpfactor1_2 DW ?
	tmpn1_1 DW ?
	tmprel_expr1_1 DW ?
	tmprel_expr21_1 DW ?
	tmpretVal_2_1_1 DW ?
	tmpsimple_expr1_1 DW ?
	address DW ?
	printData DW 0
.CODE 
fibo PROC
	POP address
	POP tmpn1_1
	MOV AX, tmpn1_1
	CMP AX, 0
	JLE LB0
	MOV AX, 0
	MOV tmprel_expr1_1, AX
	JMP LB1
	LB0:
	MOV AX, 1
	MOV tmprel_expr1_1, AX
	LB1:
	MOV AX, tmprel_expr1_1
	CMP AX, 0
	JE LB2
	PUSH 0
	JMP @RETURN
	LB2:
	MOV AX, tmpn1_1
	CMP AX, 1
	JE LB3
	MOV AX, 0
	MOV tmprel_expr21_1, AX
	JMP LB4
	LB3:
	MOV AX, 1
	MOV tmprel_expr21_1, AX
	LB4:
	MOV AX, tmprel_expr21_1
	CMP AX, 0
	JE LB5
	PUSH 1
	JMP @RETURN
	LB5:
	MOV AX, tmpn1_1
	SUB AX, 1
	MOV tmpsimple_expr1_1, AX
	PUSH tmpn1_1
	PUSH AX
	PUSH BX
	PUSH address
	PUSH tmpsimple_expr1_1
	CALL fibo
	POP tmpfactor1_1
	POP address
	POP BX
	POP AX
	POP tmpn1_1
	MOV AX, tmpn1_1
	SUB AX, 2
	MOV tmpsimple_expr1_1, AX
	PUSH tmpfactor1_1
	PUSH tmpn1_1
	PUSH AX
	PUSH BX
	PUSH address
	PUSH tmpsimple_expr1_1
	CALL fibo
	POP tmpretVal_2_1_1
	POP address
	POP BX
	POP AX
	POP tmpn1_1
	POP tmpfactor1_1
	MOV AX, tmpfactor1_1
	ADD AX, tmpretVal_2_1_1
	MOV tmpsimple_expr1_1, AX
	PUSH tmpsimple_expr1_1
	JMP @RETURN
fibo ENDP
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH AX
	PUSH BX
	PUSH 0
	CALL fibo
	POP tmpfactor1_2
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	MOV tmpa1_2, AX
	PUSH AX
	CALL PRINTF
	PUSH AX
	PUSH BX
	PUSH 1
	CALL fibo
	POP tmpfactor1_2
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	MOV tmpa1_2, AX
	PUSH AX
	CALL PRINTF
	PUSH AX
	PUSH BX
	PUSH 2
	CALL fibo
	POP tmpfactor1_2
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	MOV tmpa1_2, AX
	PUSH AX
	CALL PRINTF
	PUSH AX
	PUSH BX
	PUSH 5
	CALL fibo
	POP tmpfactor1_2
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	MOV tmpa1_2, AX
	PUSH AX
	CALL PRINTF
	PUSH AX
	PUSH BX
	PUSH 6
	CALL fibo
	POP tmpfactor1_2
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	MOV tmpa1_2, AX
	PUSH AX
	CALL PRINTF
	PUSH AX
	PUSH BX
	PUSH 8
	CALL fibo
	POP tmpfactor1_2
	POP BX
	POP AX
	MOV AX, tmpfactor1_2
	MOV tmpa1_2, AX
	PUSH AX
	CALL PRINTF

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

