.MODEL SMALL
.STACK 100H
.DATA
	NL EQU 0AH
	CR EQU 0DH
	tmpa1_1 DW ?
	tmpb1_1 DW ?
	tmpd1_1 DW ?
	tmpe1_1 DW ?
	tmpexpr1_1 DW ?
	tmpexpr1_1_1 DW ?
	tmpexpr1_1_2 DW ?
	tmplogic_expr1_1 DW ?
	tmplogic_expr1_1_2 DW ?
	tmprel_expr1_1 DW ?
	tmprel_expr21_1 DW ?
	tmpsimple_expr1_1 DW ?
	tmpterm1_1 DW ?
	tmpun_expr1_1 DW ?
	tmpc1_1 DW 3 DUP<?>
	address DW ?
	printData DW 0
.CODE 
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	MOV AX, 12
	MOV BX, 4
	IMUL BX
	MOV tmpterm1_1, AX
	MOV AX, tmpterm1_1
	MOV BX, 2
	IMUL BX
	MOV tmpterm1_1, AX
	MOV AX, tmpterm1_1
	MOV tmpe1_1, AX
	MOV AX, tmpe1_1
	PUSH AX
	CALL PRINTF
	MOV AX, 5
	MOV tmpd1_1, AX
	MOV AX, 2
	ADD AX, 3
	MOV tmpsimple_expr1_1, AX
	MOV AX, tmpsimple_expr1_1
	MOV tmpexpr1_1, AX
	MOV AX, 4
	MOV BX, tmpexpr1_1
	IMUL BX
	MOV tmpterm1_1, AX
	MOV AX, tmpterm1_1
	CWD
	MOV BX, 3
	IDIV BX
	MOV tmpterm1_1, DX
	MOV AX, tmpterm1_1
	MOV tmpa1_1, AX
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	MOV AX, 1
	CMP AX, 5
	JL LB0
	MOV AX, 0
	MOV tmprel_expr1_1, AX
	JMP LB1
	LB0:
	MOV AX, 1
	MOV tmprel_expr1_1, AX
	LB1:
	MOV AX, tmprel_expr1_1
	MOV tmpb1_1, AX
	MOV AX, tmpb1_1
	PUSH AX
	CALL PRINTF
	MOV AX, 2
	CMP AX, 3
	JGE LB2
	MOV AX, 0
	MOV tmprel_expr21_1, AX
	JMP LB3
	LB2:
	MOV AX, 1
	MOV tmprel_expr21_1, AX
	LB3:
	MOV AX, 2
	CMP AX, 4
	JNE LB4
	MOV AX, 0
	MOV tmprel_expr1_1, AX
	JMP LB5
	LB4:
	MOV AX, 1
	MOV tmprel_expr1_1, AX
	LB5:
	MOV AX, tmprel_expr21_1
	CMP AX, 0
	JE LB6
	MOV AX, tmprel_expr1_1
	CMP AX, 0
	JE LB6
	MOV AX, 1
	MOV tmplogic_expr1_1, AX
	JMP LB7
	LB6:
	MOV AX, 0
	MOV tmplogic_expr1_1, AX
	LB7:
	MOV AX, tmplogic_expr1_1
	MOV tmpb1_1, AX
	MOV AX, tmpb1_1
	PUSH AX
	CALL PRINTF
	MOV AX, tmpb1_1
	CMP AX, 0
	JE LB8
	MOV AX, 0
	JMP LB9
	LB8: 
	MOV AX, 1
	LB9:
	MOV tmpun_expr1_1, AX
	MOV AX, tmpun_expr1_1
	MOV tmpb1_1, AX
	MOV AX, tmpb1_1
	PUSH AX
	CALL PRINTF
	DEC tmpd1_1
	MOV AX, tmpd1_1
	MOV tmpexpr1_1, AX
	MOV AX, tmpd1_1
	PUSH AX
	CALL PRINTF
	INC tmpd1_1
	MOV AX, tmpd1_1
	MOV tmpexpr1_1, AX
	MOV AX, tmpd1_1
	PUSH AX
	CALL PRINTF
	MOV AX, tmpd1_1
	ADD AX, 10
	MOV tmpsimple_expr1_1, AX
	MOV AX, 2
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, tmpsimple_expr1_1
	MOV tmpc1_1[BX], AX
	MOV tmpexpr1_1, AX
	MOV AX, 2
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, tmpc1_1[BX]
	MOV tmpa1_1, AX
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	MOV AX, 0
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, 2
	MOV tmpc1_1[BX], AX
	MOV tmpexpr1_1, AX
	MOV AX, tmpa1_1
	CMP AX, 0
	JE LB10
	MOV AX, tmpb1_1
	CMP AX, 0
	JE LB10
	MOV AX, 1
	MOV tmplogic_expr1_1, AX
	JMP LB11
	LB10:
	MOV AX, 0
	MOV tmplogic_expr1_1, AX
	LB11:
	MOV AX, tmplogic_expr1_1
	MOV tmpexpr1_1, AX
	MOV AX, tmpexpr1_1
	CMP AX, 0
	JE LB12
	MOV AX, 0
	MOV tmpexpr1_1_1, AX
	MOV BX, tmpexpr1_1_1
	ADD BX,BX
	INC tmpc1_1[BX]
	MOV AX, tmpc1_1
	MOV tmpexpr1_1_1, AX
	MOV AX, 1
	MOV tmpexpr1_1_1, AX
	MOV BX, tmpexpr1_1_1
	ADD BX,BX
	MOV AX, 8
	MOV tmpc1_1[BX], AX
	MOV tmpexpr1_1_1, AX
	JMP LB13
	LB12:
	MOV AX, 0
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, 1
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, tmpc1_1[BX]
	MOV tmpc1_1[BX], AX
	MOV tmpexpr1_1, AX
	LB13:
	MOV AX, 0
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, tmpc1_1[BX]
	MOV tmpa1_1, AX
	MOV AX, 1
	MOV tmpexpr1_1, AX
	MOV BX, tmpexpr1_1
	ADD BX,BX
	MOV AX, tmpc1_1[BX]
	MOV tmpb1_1, AX
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	MOV AX, tmpb1_1
	PUSH AX
	CALL PRINTF
	MOV AX, tmpa1_1
	CMP AX, 0
	JNE LB14
	MOV AX, 0
	CMP AX, 1
	JE LB14
	MOV AX, 0
	MOV tmplogic_expr1_1, AX
	JMP LB15
	LB14:
	MOV AX, 1
	MOV tmplogic_expr1_1, AX
	LB15:
	MOV AX, tmplogic_expr1_1
	MOV tmpexpr1_1, AX
	MOV AX, tmpexpr1_1
	CMP AX, 0
	JE LB26
	MOV AX, 1
	MOV tmpexpr1_1_2, AX
	MOV BX, tmpexpr1_1_2
	ADD BX,BX
	MOV AX, 2
	CMP AX, 0
	JE LB16
	MOV AX, tmpc1_1
	CMP AX, 0
	JE LB16
	MOV AX, 1
	MOV tmplogic_expr1_1_2, AX
	JMP LB17
	LB16:
	MOV AX, 0
	MOV tmplogic_expr1_1_2, AX
	LB17:
	MOV AX, tmplogic_expr1_1_2
	MOV tmpexpr1_1_2, AX
	MOV AX, 1
	MOV tmpexpr1_1_2, AX
	MOV BX, tmpexpr1_1_2
	ADD BX,BX
	MOV AX, tmpc1_1
	CMP AX, 0
	JE LB18
	MOV AX, tmpa1_1
	CMP AX, 0
	JE LB18
	MOV AX, 1
	MOV tmplogic_expr1_1_2, AX
	JMP LB19
	LB18:
	MOV AX, 0
	MOV tmplogic_expr1_1_2, AX
	LB19:
	MOV AX, tmplogic_expr1_1_2
	MOV tmpexpr1_1_2, AX
	MOV AX, tmpexpr1_1_2
	CMP AX, 0
	JNE LB20
	MOV AX, tmpexpr1_1_2
	CMP AX, 1
	JE LB20
	MOV AX, 0
	MOV tmplogic_expr1_1_2, AX
	JMP LB21
	LB20:
	MOV AX, 1
	MOV tmplogic_expr1_1_2, AX
	LB21:
	MOV AX, tmplogic_expr1_1_2
	MOV tmpexpr1_1_2, AX
	MOV AX, tmpexpr1_1_2
	CMP AX, 0
	JE LB22
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	LB22:
	MOV AX, 50
	CMP AX, 0
	JE LB23
	MOV AX, 0
	CMP AX, 0
	JE LB23
	MOV AX, 1
	MOV tmplogic_expr1_1_2, AX
	JMP LB24
	LB23:
	MOV AX, 0
	MOV tmplogic_expr1_1_2, AX
	LB24:
	MOV AX, tmplogic_expr1_1_2
	MOV tmpexpr1_1_2, AX
	MOV AX, tmpexpr1_1_2
	CMP AX, 0
	JE LB25
	MOV AX, tmpa1_1
	PUSH AX
	CALL PRINTF
	LB25:
	LB26:

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
