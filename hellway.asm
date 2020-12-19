; move a happy face with GRP0CacheStuffer
;OPB game!
	processor 6502
	include vcs.h
	include macro.h
	org $F000
	
;contants
ScreenSize = 64;(192)
CarSize = 4
TrafficLineCount = 1
	
;memory	
Car0Y = $80
Car0Line = $81
GRP0Cache = $82
FrameCount0 = $83;
FrameCount1 = $84;
PF0Cache = $85
PF1Cache = $86
PF2Cache = $87
TrafficOffset0 = $88; Border
Car0Speed = $89
Traffic0SpeedAc = $90


;generic start up stuff...
Start
	SEI	
	CLD 	
	LDX #$FF	
	TXS	
	LDA #0		
ClearMem 
	STA 0,X		
	DEX		
	BNE ClearMem	
	
	LDA #$00   ;start with a black background
	STA COLUBK	
	LDA #$1C   ;lets go for bright yellow, for the car
	STA COLUP0
;Setting some variables...
	LDA #8
	STA Car0Y	;Initial Y Position
		
	
	;Traffic colour
	LDA $32 
	STA COLUPF  
	
	;mirror the playfield
	LDA #%00000001
	STA CTRLPF 
	
;VSYNC time
MainLoop
	LDA #2
	STA VSYNC	
	STA WSYNC	
	STA WSYNC
		;Cool, can put code here! It removed the black line on top 
	STA HMOVE 
	STA WSYNC	
	LDA #43	
	STA TIM64T	
	LDA #0
	STA VSYNC 	


; for left and right, we're gonna 
; set the horizontal speed, and then do
; a single HMOVE.  We'll use X to hold the
; horizontal speed, then store it in the 
; appropriate register

;assum horiz speed will be zero
	LDX #0	
	
	LDA #%01000000	;Left?
	BIT SWCHA 
	BNE SkipMoveLeft
	LDX #$10	;a 1 in the left nibble means go left
SkipMoveLeft
	
	LDA #%10000000	;Right?
	BIT SWCHA 
	BNE SkipMoveRight
	LDX #$F0	;a -1 in the left nibble means go right...
SkipMoveRight

	STX HMP0	;set the move for player 0, not the missile like last time...

IncreaseCar0Speed	
	LDA INPT4
	BMI SkipIncreaseCar0Speed ;not pressed the fire button in negative in bit 7
	INC Car0Speed;
SkipIncreaseCar0Speed
		

	LDY #2
RepeatUpdateLines ;to be able to rum more than one line at a time
	LDX #TrafficLineCount
UpdateLines
	LDA Car0Speed
	CMP TrafficSpeeds-1,X
	BCC CarWithLessSpeed ;See 6502 specs, jump if the car is slower than traffic
CarWithMoreSpeed
	SEC
	SBC TrafficSpeeds-1,X
	CLC
	ADC Traffic0SpeedAc-1,X
	STA Traffic0SpeedAc-1,X
	BCC PrepareNextUpdateLoop
	INC TrafficOffset0-1,X	
	JMP PrepareNextUpdateLoop
CarWithLessSpeed ; Not sure if this still can happen
	LDA TrafficSpeeds-1,X
	SEC
	SBC Car0Speed
	CLC
	ADC Traffic0SpeedAc-1,X
	STA Traffic0SpeedAc-1,X
	BCC PrepareNextUpdateLoop
	DEC TrafficOffset0-1,X
PrepareNextUpdateLoop
	DEX
	BNE UpdateLines
	DEY 
	BNE RepeatUpdateLines
		
CountFrame	
	INC FrameCount0
	BNE SkipIncFC1 ;When it is zero again should increase the MSB
	INC FrameCount1
SkipIncFC1
	
	
;keep rotating on 0 - screensize - 1

	LDX #TrafficLineCount
KeepTrafficPointerInRange
	LDA TrafficOffset0 - 1,X ;4
	AND #ScreenSize - 1 ;2
	STA TrafficOffset0 - 1,X
	DEX
	BNE KeepTrafficPointerInRange
	
TestCollision;
; see if car0 and playfield collide, and change the background color if so
	LDA #%10000000
	BIT CXP0FB		
	BEQ NoCollision	;skip if not hitting...
	LDA FrameCount0	;must be a hit! Change rand color bg
	STA COLUBK	;and store as the bgcolor
NoCollision
	STA CXCLR	;reset the collision detection for next frame
	; LDA #0		 ;zero out the buffer
	; STA PlayerBuffer ;just in case
	
; After here we are going to update the screen, No more heavy code
WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd	
	
	LDY #ScreenSize - 1 ;#63 ;  	
	STA WSYNC	
	
	STA VBLANK  		
	
;main scanline loop...
ScanLoop 
	STA WSYNC ;10 from the end of the scan loop
			
DrawCache ;24
	
	LDA GRP0Cache ;3 ;buffer was set during last scanline
	STA GRP0      ;3   ;put it as graphics now

	LDA PF0Cache  ;3
	STA PF0		  ;3
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2      ;3
	

ClearCache ;11
	LDA #$0 ;2 ;Clear cache
	STA PF1Cache ;3
	STA PF2Cache ; 3
	STA PF0Cache ; 3
	


	STA WSYNC ;73


	;STA WSYNC ;75
	
DrawCar0 ;16 Border
	LDA TrafficOffset0 ;3
	ASL ;2
	ASL ;2
	ASL ;2
	;ASL ;2
	AND #%01110000 ;2
	STA PF0Cache ;3
SkipCar6Draw
	
	;12
	DEC TrafficOffset0
	BPL SkipTrafficOffset0Reset
	LDA #ScreenSize - 1
	STA TrafficOffset0	
SkipTrafficOffset0Reset;--
	

BeginDrawCar0Block ;21 to EndDrawCar0Block 21 to finish player (never check if start enable if already on, this is the wrse path)
	LDX Car0Line	;3 check the visible player line...
	BEQ FinishPlayer ;2	skip the drawing if its zero...
IsPlayerOn	
	LDA CarSprite-1,X ;5	;otherwise, load the correct line from CarSprite
				;section below... it's off by 1 though, since at zero
				;we stop drawing
	STA GRP0Cache ;3	;put that line as player graphic for the next line
	DEC Car0Line ;5	;and decrement the line count
	JMP SkipActivatePlayer ;3 save some cpu time
FinishPlayer

CheckActivatePlayer ;10 max
	CPY Car0Y ;3
	BNE SkipActivatePlayer ;2
	LDA #CarSize ;2
	STA Car0Line ;3
SkipActivatePlayer ;EndDrawCar0Block
	
	STA WSYNC ;49
	
	;STA WSYNC ;3

WhileScanLoop	
	DEY	;2
	BMI FinishScanLoop ;2 or 3 ;two big Breach	
	JMP ScanLoop ;3
FinishScanLoop
	
PrepareOverscan
	LDA #2		
	STA WSYNC  	
	STA VBLANK 	
	
	LDA #37
	STA TIM64T	
	;LDA #0
	;STA VSYNC 		

;Do more logic

OverScanWait
	LDA INTIM	
	BNE OverScanWait	
	JMP  MainLoop      

CarSprite 
	.byte #%00000000
	.byte #%10111101
	.byte #%00111100
	.byte #%10111101
	;.byte #%00111100
	;.byte #%00111100
	
TrafficSpeeds ;maybe move to ram for dynamic changes and speed of 0 page access
	.byte #0 ; Border

	org $FFFC
	.word Start
	.word Start
