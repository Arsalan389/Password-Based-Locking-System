;21BEC0615 ARSALAN MALLICK
;22BEC0941 JIYA GIDWANI
ORG 0000H
	MOV R6,#0 ;Used to store count value for printing messages
	MOV R5,#3 ;number of attempts
	MOV A,#0  ;Initialize with 0 value
;--------------------------------------
;Main loop running the initialization and all subroutines
MAIN:
	ACALL LCD_INIT        ;Initialize LCD
	MOV DPTR,#INITIAL_MSG ; Move Startup message to RAM
	ACALL SEND_DATA		  
	ACALL D1			  ;Delay
	ACALL LINE2			  
	ACALL READ_KEY		  
	ACALL D1			  ;Delay
	ACALL LCD_CLR
	MOV DPTR,#CHECK_MSG	  ; Move checking message when code is entered
	ACALL SEND_DATA       
	ACALL D2
	ACALL CHECK_PASS      
	SJMP MAIN			  ;Loop
	
;--------------------------------------
;Subroutine to Initialize the LCD on startup
LCD_INIT: 
	MOV DPTR,#MYDATA	;Move the control messages to DPTR
	C1: CLR A			
	MOVC A,@A+DPTR		;Move control messages to accumulator
	JZ DAT				;Jump to return once all control messages are sent
	ACALL COMNWRT
	ACALL D1			;Delay
	INC DPTR			
	SJMP C1
	DAT:RET

;--------------------------------------
;Subroutine to Send Data to LCD
SEND_DATA:
	CLR A
	MOVC A,@A+DPTR		;Move data message to accumulator
	JZ AGAIN			;Jump to return once all data messages are sent
	ACALL DATAWRT
	ACALL D1			;Delay
	INC DPTR
	SJMP SEND_DATA
	AGAIN:RET
	
;--------------------------------------
;Subroutine to Read a key
READ_KEY:
	MOV R0,#5				;Length of input code/count of number of digits
	MOV R1,#160				;Register location to store code
	ROTATE:ACALL KEY_SCAN	;Call subroutine to scan for keypad inputs
	MOV @R1,A				;Move key input to address in R1
	ACALL DATAWRT			;Send to LCD
	ACALL D2				;Delay
	ACALL D2				;Delay
	INC R1					;Increment to next address
	DJNZ R0,ROTATE			;Loop till 5 digits are entered
	RET

;--------------------------------------
;Subroutine to check entered code with stored code
CHECK_PASS:
	MOV R0,#5		
	MOV R1,#160
	MOV DPTR,#PASSWORD	;Move stored code location from ROM to RAM
	RPT:CLR A
	MOVC A,@A+DPTR		;Move code digits to DPTR
	XRL A,@R1			;Peform XOR between two codes,if output is 0 then code is right
	JNZ FAIL			;jump to Fail, if code is wrong
	INC R1				;increment password counter
	INC DPTR			
	DJNZ R0,RPT			;Repeat till all 5 digits are analyzed
	ACALL SUCCESS		
	RET
	
;--------------------------------------
;Subroutine to display success message and performing unlock action
SUCCESS:
	ACALL LCD_CLR
	ACALL D2	
	MOV DPTR,#TEXT_S1	;Display first message 'ACCESS GRANTED'
	ACALL SEND_DATA
	ACALL D2
	ACALL LINE2
	MOV DPTR,#TEXT_S2	; Display second message 'OPENING DOOR'
	ACALL SEND_DATA
	ACALL D1
	CLR P2.3			; Step motor to 90 degree
	CLR P2.4		
	ACALL D3
	ACALL LCD_CLR			
	MOV DPTR,#TEXT_S3	; Display auto locking message 'CLOSING DOOR'
	ACALL SEND_DATA	
	ACALL D2
	SETB P2.3			;Step motor to 0 degree(original position)
	CLR P2.5
	ACALL D3
	SETB P2.3			;Lock motor at original position
	SETB P2.4
	SETB P2.5
	SETB P2.6
	MOV R5,#3			;Restore total attempt value
	RET
	
;--------------------------------------
;Subroutine to display Fail message 
FAIL: ACALL LCD_CLR
	  MOV DPTR,#TEXT_F1 ;Display message 'WRONG CODE'
	  ACALL SEND_DATA
	  ACALL D2
	  ACALL LINE2		
	  MOV DPTR,#TEXT_F2	;Display message 'ACCESS DENIED'
	  ACALL SEND_DATA
	  ACALL D2
	  ACALL LINE2
	  MOV DPTR,#TEXT_F2	
	  ACALL SEND_DATA
	  ACALL D2
	  DJNZ R5,LOOP		;Check if attempts are remaining
	  ACALL LOCK		;If attempts are not remaining disable keypad
	  LOOP: ACALL ATTEMPT ;If attempts left, retake input
	  LJMP MAIN

;--------------------------------------

ATTEMPT: ACALL LCD_CLR
		 MOV DPTR,#ATTEMPT_TEXT ;Display message to reattempt
		 ACALL SEND_DATA
		 ACALL D2
		 MOV A,#48				;ASCII value of '0'	
		 ADD A,R5				;Add number of attempts left
		 DA A					;Decimal adjust for ASCII Value 
		 ACALL DATAWRT			;Send ASCII value of pending attempts to LCD
		 ACALL D1
		 ACALL D2
		 ACALL D2
		 RET

;--------------------------------------
;Subroutine to check for which key is pressed
KEY_SCAN: MOV P1,#0FFH
		  CLR P1.0
		  JB P1.4, NEXT1
		  MOV A,#55
		  RET
;Rows are cleared in order, and then columns pins are checked if they are pulled low. If low then key is pressed.		  
		  NEXT1: JB P1.5,NEXT2
				 MOV A,#56		; ASCII Value of '8'
				 RET
		
		  NEXT2: JB P1.6,NEXT3	
				 MOV A,#57		;ASCII Value of '9'
				 RET
				 
		  NEXT3: SETB P1.0
				 CLR P1.1
				 JB P1.4,NEXT4
				 MOV A,#52		;ASCII Value of '4'
				 RET
		  
		  NEXT4: JB P1.5,NEXT5
				 MOV A,#53		;ASCII Value of '5'
				 RET
		  
		  NEXT5: JB P1.6,NEXT6
				 MOV A,#54		;ASCII Value of '6'
				 RET
				 
		  NEXT6: SETB P1.1
				 CLR P1.2
				 JB P1.4,NEXT7
				 MOV A,#49		;ASCII Value of '1'
				 RET
				 
		  NEXT7: JB P1.5,NEXT8
				 MOV A,#50		;ASCII Value of '2'
				 RET
				 
		  NEXT8: JB P1.6,NEXT9
				 MOV A,#51		;ASCII Value of '3'
				 RET
				 
		  NEXT9: SETB P1.2
				 CLR P1.3
				 JB P1.5,NEXT10
				 MOV A,#48		;ASCII Value of '0'
				 RET
				 
		 NEXT10: JB P1.6,NEXT11
				 MOV A,#61		;ASCII Value of '=', for future use 
				 RET
				 
		 NEXT11: LJMP KEY_SCAN		;if no key is pressed jump back to KEY_SCAN

;--------------------------------------
;Subroutines to write data to LCD
COMNWRT: MOV P3,A
		 CLR P2.0
		 CLR P2.1
		 SETB P2.2
		 ACALL D1
		 CLR P2.2
		 RET
		 
DATAWRT: MOV P3,A
		 SETB P2.0
		 CLR P2.1
		 SETB P2.2
		 ACALL D1
		 CLR P2.2
		 RET

;--------------------------------------
;Subroutine to shift to Line 2 of LCD
LINE2: MOV A,#0C0H
	   ACALL COMNWRT
	   RET
	   
;--------------------------------------
;Subroutine for disabling keypad inputs, when 0 attempts are there
;Approximate Delay=1 minute
LOCK: ACALL LCD_CLR
	  MOV DPTR,#LOCK_TEXT
	  ACALL SEND_DATA
	  ACALL D2
D4: MOV R3,#0xFF
D4_OUTER:MOV R4,#0xFF
D4_INNER1:MOV R7,#0xFF 
D4_INNER:DJNZ R7, D4_INNER
		 DJNZ R4,D4_INNER1
		 DJNZ R3,D4_OUTER
		 MOV R5,#3
		 RET
		 
;--------------------------------------
;Delay 1
D1: MOV R3,#65
H2: MOV R2,#255
H: DJNZ R4,H
DJNZ R3,H2
RET

;--------------------------------------
;Delay 2
D2: MOV R3,#250
	MOV TMOD,#01
BACK2: MOV TH0,#0FCH
	   MOV TL0,#018H
	   SETB TR0
H5: JNB TF0,H5
	CLR TR0
	CLR TF0
	DJNZ R3,BACK2
	RET

;--------------------------------------
;Delay 3
D3: MOV TMOD,#10H
	MOV R3,#70
	AGAIN1: MOV TL1,#00H
	MOV TH1,#00H
	SETB TR1
	BACK: JNB TF1,BACK
	CLR TR1
	CLR TF1
	DJNZ R2,AGAIN1
	RET
	
;--------------------------------------
;Subroutine to clear LCD
LCD_CLR: MOV A,#01H
ACALL COMNWRT
RET

;--------------------------------------

ORG 500H
	MYDATA: DB 38H,0EH,01,06,80H,0
	INITIAL_MSG: DB "ENTER CODE:XXXXX"
	CHECK_MSG: DB "CHECKING CODE..."
	PASSWORD: DB '38934'		;lock code
	TEXT_F1: DB "WRONG CODE",0
	TEXT_F2: DB "ACCESS DENIED",0
	TEXT_S1: DB "ACCESS GRANTED",0
	TEXT_S2: DB "OPENING DOOR",0
	TEXT_S3: DB "CLOSING DOOR",0	
	ATTEMPT_TEXT: DB "ATTEMPTS LEFT:0",0
	LOCK_TEXT: DB "TRY IN 1 MIN",0
	
END
	
