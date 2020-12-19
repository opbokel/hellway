; move a happy face with GRP0CacheStuffer
;OPB game!
	processor 6502
	include vcs.h
	include macro.h
	org $F000
	
;contants
ScreenSize = 32;(192)
CarSize = 4
TrafficLineCount = 7
	
;memory	
Car0Y = $80
Car0Line = $81
GRP0Cache = $82
FrameCount0 = $83;
FrameCount1 = $84;
PF0Cache = $85
PF1Cache = $86
PF2Cache = $87
TrafficOffset0 = $88;
TrafficOffset1 = $89;
TrafficOffset2 = $8A;
TrafficOffset3 = $8B;
TrafficOffset4 = $8C;
TrafficOffset5 = $8D;
TrafficOffset6 = $8E; border

TrafficOffset7 = $8F; not used, probably will change background

Car0Speed = $90
Traffic0SpeedAc = $91
Traffic1SpeedAc = $92
Traffic2SpeedAc = $93
Traffic3SpeedAc = $94
Traffic4SpeedAc = $95
Traffic5SpeedAc = $96
Traffic6SpeedAc = $97

TmpVar0 = $98


TrafficCacheStart = $FF - ScreenSize + 1 ;$E0
TrafficCacheEnd = $FF

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
	LDA #30
	STA Car0Y	;Initial Y Position
		

	LDA #$ff
	STA $E1
	STA $E2
	STA $E3
	; STA $E4
	; STA $E5
	; STA $E6
	; STA $E7
	; LDA #$80
	; STA $E8
	; STA $E9
	; STA $EA
	; STA $EB
	
	; LDA #16
	; STA TrafficOffset0
	; STA TrafficOffset1
	; STA TrafficOffset2
	; STA TrafficOffset3
	; STA TrafficOffset4
	; STA TrafficOffset5
	; STA TrafficOffset6
	
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


; for up and down, we INC or DEC
; the Y Position

	LDA #%00010000	;Down?
	BIT SWCHA 
	BNE SkipMoveDown
	INC Car0Y
	; INC Car0Y
	; INC Car0Y
	; INC Car0Y
SkipMoveDown
	; LDA FrameCount0
	; BNE SkipMoveUp
	LDA #%00100000	;Up?
	BIT SWCHA 
	BNE SkipMoveUp
	DEC Car0Y
	; DEC Car0Y
	; DEC Car0Y
	; DEC Car0Y
SkipMoveUp

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
		
	; LDX #2 ;number of times will process the line update
; UpdateLines
	; CLC
	; LDA Traffic6SpeedAc
	; ADC Car0Speed
	; STA Traffic6SpeedAc
	; BCC SkipCar6LineUpdate
	; INC TrafficOffset6
	; DEX
	; BNE UpdateLines
; SkipCar6LineUpdate

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
CarWithLessSpeed
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
	; INC TrafficOffset0
	; DEC TrafficOffset2
	; DEC TrafficOffset3
	; DEC TrafficOffset3
	INC FrameCount0
	BNE SkipIncFC1 ;When it is zero again should increase the MSB
	INC FrameCount1
	;INC Car0Y
	; DEC TrafficOffset1
	; DEC TrafficOffset4
	; INC TrafficOffset5
SkipIncFC1
	
;moves the trafic, will be dinamic
	; INC TrafficOffset0
	; INC TrafficOffset1
	; INC TrafficOffset1
	;INC TrafficOffset2
	;INC TrafficOffset2
	; DEC TrafficOffset2
	; INC TrafficOffset3
	
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
	
DrawCar0 ;14 max
	LDX TrafficOffset0 ;3
	LDA TrafficCacheStart,X ;4
	BPL SkipCar0Draw ;2 if car 1 is on, it is always negative	
	LDA #%11000000 ;2
	STA PF1Cache	;3
SkipCar0Draw

DrawCar1 ;19 max
	LDX TrafficOffset1 ;3
	LDA TrafficCacheStart,X ;4
	AND #%01000000 ;2
	BEQ SkipCar1Draw ;2
	LDA PF1Cache ;3
	ORA #%00011000 ;2
	STA PF1Cache ;3
SkipCar1Draw

	STA WSYNC ;71

DrawCar2 ;19
	LDX TrafficOffset2 ;3
	LDA TrafficCacheStart,X ;4
	AND #%001000000 ;2
	BEQ SkipCar2Draw ;2
	LDA PF1Cache ;3
	ORA #%00000011 ;2
	STA PF1Cache ;3	
SkipCar2Draw

DrawCar3 ;16
	LDX TrafficOffset3 ;3
	LDA TrafficCacheStart,X ;4
	AND #%00010000 ;2
	BEQ SkipCar3Draw ;2
	LDA #%00000110 ;2(MSB first) it was two easy...
	STA PF2Cache ;3	
SkipCar3Draw


DrawCar4 ;19
	LDX TrafficOffset4
	LDA TrafficCacheStart,X
	AND #%00001000
	BEQ SkipCar4Draw
	LDA PF2Cache
	ORA #%00110000 ;(MSB first) it was two easy...
	STA PF2Cache	
SkipCar4Draw

DrawCar5 ;19
	LDX TrafficOffset5
	LDA TrafficCacheStart,X
	AND #%00000100
	BEQ SkipCar5Draw
	LDA PF2Cache
	ORA #%10000000 ;(MSB first) it was two easy...
	STA PF2Cache	
SkipCar5Draw

	STA WSYNC ;73
	
	;12 max cicle pointer
	DEC TrafficOffset0 ;5/2
	BPL SkipTrafficOffset0Reset ; 2/2
	LDA #ScreenSize - 1 ; 2/2
	STA TrafficOffset0 ;3/2
SkipTrafficOffset0Reset
	
	;12
	DEC TrafficOffset1
	BPL SkipTrafficOffset1Reset
	LDA #ScreenSize - 1
	STA TrafficOffset1
SkipTrafficOffset1Reset	

	DEC TrafficOffset2
	BPL SkipTrafficOffset2Reset
	LDA #ScreenSize - 1
	STA TrafficOffset2
SkipTrafficOffset2Reset

	DEC TrafficOffset3
	BPL SkipTrafficOffset3Reset
	LDA #ScreenSize - 1
	STA TrafficOffset3
SkipTrafficOffset3Reset

	DEC TrafficOffset4 ;5
	BPL SkipTrafficOffset4Reset ;2
	LDA #ScreenSize - 1 ;2
	STA TrafficOffset4 ;3
SkipTrafficOffset4Reset

	DEC TrafficOffset5
	BPL SkipTrafficOffset5Reset
	LDA #ScreenSize - 1
	STA TrafficOffset5	
SkipTrafficOffset5Reset


	STA WSYNC ;75
	
DrawCar6 ;16
	; LDX TrafficOffset6 ;3
	; LDA TrafficCacheStart,X ;4
	; AND #%00000010 ;2
	; BEQ SkipCar6Draw ;2
	; LDA #%01110000 ;2(MSB first) it was two easy...
	; STA PF0Cache ;3	
	LDA TrafficOffset6 ;3
	ASL ;2
	ASL ;2
	ASL ;2
	;ASL ;2
	AND #%01110000 ;2
	STA PF0Cache ;3
SkipCar6Draw
	
	;12
	DEC TrafficOffset6
	BPL SkipTrafficOffset6Reset
	LDA #ScreenSize - 1
	STA TrafficOffset6	
SkipTrafficOffset6Reset;--
	

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
	
	STA WSYNC ;3

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
	.byte #40 ;car 0
	.byte #80 
	.byte #120
	.byte #160
	.byte #190
	.byte #220 ;car 5
	.byte #0 ;car 6 border

	org $FFFC
	.word Start
	.word Start
