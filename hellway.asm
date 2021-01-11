; Hellway! 
; Thanks to AtariAge and all available online docs 
	processor 6502
	include vcs.h
	include macro.h
	org $F000
	
;contants
SCREEN_SIZE = 64;(VSy)
SCORE_SIZE = 5

CAR_SIZE = 7
TRAFFIC_LINE_COUNT = 7
CAR_0_Y = 10
;16 bit precision
;640 max speed!
CAR_MAX_SPEED_H = $02
CAR_MAX_SPEED_L = $80
CAR_MIN_SPEED_H = 0
CAR_MIN_SPEED_L = 0
BACKGROUND_COLOR = $00 ;Black
PLAYER_1_COLOR = $1C ;Yellow
PLAYER_2_COLOR = $85 ;Blue
ACCELERATE_SPEED = 1
BREAK_SPEED = 4
;For now, will use in aal rows until figure out if make it dynamic or not.
TRAFFIC_1_MASK = #%11111000
TRAFFIC_1_CHANCE = #$20

TRAFFIC_COLOR = $34
SCORE_BACKGROUND_COLOR = $81
SCORE_FONT_COLOR = $0F
	
;memory	
Car0Line = $80

GRP0Cache = $81
PF0Cache = $82
PF1Cache = $83
PF2Cache = $84

FrameCount0 = $86;
FrameCount1 = $87;

Car0SpeedL = $88
Car0SpeedH = $89

TrafficOffset0 = $90; Border $91 $92 (24 bit) $93 is cache
TrafficOffset1 = $94; Traffic 1 $94 $95 (24 bit) $96 is cache
TrafficOffset2 = $98; Traffic 1 $99 $9A (24 bit) $9B is cache
TrafficOffset3 = $9C; Traffic 1 $9D $9E (24 bit) $9F is cache
TrafficOffset4 = $A0; Traffic 1 $A1 $A2 (24 bit) $A3 is cache
TrafficOffset5 = $A4; Traffic 1 $A5 $A6 (24 bit) $A7 is cache
TrafficOffset6 = $A8; Traffic 1 $A9 $A0 (24 bit) $AA is cache

;Temporary variables, multiple uses
Tmp0=$B0
Tmp1=$B1
Tmp2=$B2

GameStatus = $C0 ; Flags, D7 = running, expect more flags

ScoreD0 = $D0
ScoreD1 = $D1
ScoreD2 = $D2
ScoreD3 = $D3
ScoreD4 = $D4
ScoreD5 = $D5
ScoreD6 = $D6
ScoreD7 = $D7
ScoreD8 = $D8
ScoreD9 = $D9

;generic start up stuff, put zero in all...
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
	
;Setting some variables...

	LDA #PLAYER_1_COLOR
	STA COLUP0

	LDA #PLAYER_2_COLOR
	STA COLUP1

	;Loop ?
	LDA #$20
	STA TrafficOffset1 + 2
	LDA #$40
	STA TrafficOffset2 + 2	;Initial Y Position
	LDA #$60
	STA TrafficOffset3 + 2	;Initial Y Position
	LDA #$80
	STA TrafficOffset4 + 2	;Initial Y Position
	LDA #$A0
	STA TrafficOffset5 + 2	;Initial Y Position
	LDA #$C0
	STA TrafficOffset6 + 2	;Initial Y Position

	LDA TrafficSpeeds + 6 * 2 ; Same as the line he is in.
	STA Car0SpeedL	
	
	
;VSYNC time
MainLoop
	LDA #2
	STA VSYNC	
	STA WSYNC	
	STA WSYNC
;Cool, can put code here! It removed the black line on top
;Make Objects move in the X axys
	STA HMOVE  ;2
;This must be done after a WSync, otherwise it is impossible to predict the X position
	LDA GameStatus ;3
	EOR #%10000000 ;2 game running, we get 0 and not reset the position.
	BEQ DoNotSetPlayerX ;3
	;Do something better with this 32 cycles
	SLEEP 33; Maybe fine position with hmove...
	STA RESP0 ;3

DoNotSetPlayerX

	STA WSYNC	
	LDA #43 ; We start the drawing cycle after 36 lines, because drawing is delayed by one line. 
	STA TIM64T	
	LDA #0
	STA VSYNC 	

;Read Fire Button before, will make it start the game for now.
	LDA INPT4
	BMI SkipGameStart ;not pressed the fire button in negative in bit 7
	LDA GameStatus
	ORA #%10000000
	STA GameStatus
SkipGameStart
	
CountFrame	
	INC FrameCount0 ; Used to alternate lines
	BNE SkipIncFC1 ;When it is zero again should increase the MSB
	INC FrameCount1 ; Still not used
SkipIncFC1

;Does not update the game if not running
	LDA GameStatus ;3
	EOR #%10000000 ;2 game is running...
	BEQ ContinueWithGameLogic ;3 Cannot branch more than 128 bytes, so we have to use JMP
	JMP SkipUpdateLogic

ContinueWithGameLogic

; for left and right, we're gonna 
; set the horizontal speed, and then do
; a single HMOVE.  We'll use X to hold the
; horizontal speed, then store it in the 
; appropriate register

;assum horiz speed will be zero

;Begin read dpad
	LDX #0	

	LDA #%01000000	;Left
	BIT SWCHA 
	BNE SkipMoveLeft
	LDX #$10	;a 1 in the left nibble means go left
SkipMoveLeft
	
	LDA #%10000000	;Right
	BIT SWCHA 
	BNE SkipMoveRight
	LDX #$F0	;a -1 in the left nibble means go right...
SkipMoveRight

	STX HMP0	;set the move for player 0, not the missile like last time...


;Acelerates / breaks the car
	LDA #%00010000	;UP in controller
	BIT SWCHA 
	BNE SkipAccelerate

;Adds speed
	CLC
	LDA Car0SpeedL
	ADC #ACCELERATE_SPEED
	STA Car0SpeedL
	LDA Car0SpeedH
	ADC #0
	STA Car0SpeedH

;Checks if already max
	CMP #CAR_MAX_SPEED_H
	BCC SkipAccelerate ; less than my max speed
	BNE ResetToMaxSpeed ; Not equal, so if I am less, and not equal, I am more!
	;High bit is max, compare the low
	LDA Car0SpeedL
	CMP #CAR_MAX_SPEED_L
	BCC SkipAccelerate ; High bit is max, but low bit is not
	;BEQ SkipAccelerate ; Optimize best case, but not worse case

ResetToMaxSpeed ; Speed is more, or is already max
	LDA #CAR_MAX_SPEED_H
	STA Car0SpeedH
	LDA #CAR_MAX_SPEED_L
	STA Car0SpeedL

SkipAccelerate

Break
	LDA #%00100000	;Down in controller
	BIT SWCHA 
	BNE SkipBreak

;Decrease speed
	SEC
	LDA Car0SpeedL
	SBC #BREAK_SPEED
	STA Car0SpeedL
	LDA Car0SpeedH
	SBC #0
	STA Car0SpeedH

;Checks if is min speed
	BMI ResetMinSpeed; Overflow d7 is set
	CMP #CAR_MIN_SPEED_H
	BEQ CompareLBreakSpeed; is the same as minimun, compare other byte.
	BCS SkipBreak; Greater than min, we are ok! 

CompareLBreakSpeed	
	LDA Car0SpeedL
	CMP #CAR_MIN_SPEED_L	
	BCC ResetMinSpeed ; Less than memory
	JMP SkipBreak ; We are greather than min speed in the low byte.

ResetMinSpeed
	LDA #CAR_MIN_SPEED_H
	STA Car0SpeedH
	LDA #CAR_MIN_SPEED_L
	STA Car0SpeedL
SkipBreak

;Updates all offsets 24 bits
	LDX #0 ; Memory Offset 24 bit
	LDY #0 ; Line Speeds 16 bits
UpdateOffsets; Car sped - traffic speed = how much to change offet (signed)
	SEC
	LDA Car0SpeedL
	SBC TrafficSpeeds,Y
	STA Tmp0
	INY
	LDA Car0SpeedH
	SBC TrafficSpeeds,Y
	STA Tmp1
	LDA #0; Hard to figure out, makes the 2 complement result work correctly, since we use this 16 bit signed result in a 24 bit operation
	SBC #0
	STA Tmp2


;Adds the result
	CLC
	LDA Tmp0
	ADC TrafficOffset0,X
	STA TrafficOffset0,X
	INX
	LDA Tmp1
	ADC TrafficOffset0,X
	STA TrafficOffset0,X
	INX
	LDA Tmp2 ; Carry
	ADC TrafficOffset0,X
	STA TrafficOffset0,X
	INX
	SEC
	ADC #0 ;Increment by one
	STA TrafficOffset0,X ; cache of the other possible value for the MSB in the frame, make drawing faster.


PrepareNextUpdateLoop
	INY
	INX
	CPX #TRAFFIC_LINE_COUNT * 4;
	BNE UpdateOffsets
	
TestCollision;
; see if car0 and playfield collide, and change the background color if so
	LDA #%10000000
	BIT CXP0FB		
	BEQ NoCollision	;skip if not hitting...
	LDA FrameCount0	;must be a hit! Change rand color bg
	STA COLUBK	;and store as the bgcolor
NoCollision
	STA CXCLR	;reset the collision detection for next frame

SkipUpdateLogic	
	
	;DELETE THIS!
	LDA #<N1 + #SCORE_SIZE -1
	STA ScoreD0
	STA ScoreD1
	STA ScoreD2
	STA ScoreD3
	STA ScoreD4

	LDA #<N2 + #SCORE_SIZE -1
	STA ScoreD5
	STA ScoreD6
	STA ScoreD7
	STA ScoreD8
	STA ScoreD9
	;END DELETE THIS

	LDA #SCORE_BACKGROUND_COLOR
	STA COLUBK
	LDA #SCORE_FONT_COLOR
	STA COLUPF  
	JSR ClearPF
	LDA #%00000010 ; Score mode
	STA CTRLPF
	LDY #SCORE_SIZE -1

	LDA FrameCount0 ;3
	AND #%00000001 ;2
	BEQ RightScoreOn ; Half of the screen with the correct colors.
LeftScoreOn
	LDA #SCORE_FONT_COLOR
	STA COLUP1
	LDA #SCORE_BACKGROUND_COLOR
	STA COLUP0
	JMP WaitForVblankEnd
RightScoreOn
	LDA #SCORE_FONT_COLOR
	STA COLUP0
	LDA #SCORE_BACKGROUND_COLOR
	STA COLUP1


; After here we are going to update the screen, No more heavy code
WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd ;Is there a better way?	
	STA WSYNC ; Seems wastefull, can I live killing vblank midline?
	STA VBLANK 		

ScoreLoop
	STA WSYNC

	LDA PF0Cache  ;3 Move to a macro?
	STA PF0		  ;3
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2 ;3

	STY Tmp0; Keep Y Value, will be use to alternate text left and right
	LDX #0 ; LeftScoreOffset

	LDA FrameCount0 ;3
	AND #%00000001 ;2
	BEQ DrawScore
RightScoreOffset
	LDX #5 ; Points to D5 6 7...

DrawScore
	LDY ScoreD0,X ; 3
	LDA Font,Y	;4
	STA PF0Cache ;3
	DEC ScoreD0,X ;5 Can only DEC with X
	;14

	LDY ScoreD1,X ; 3
	LDA Font,Y	;4
	ASL ;2
	ASL ;2
	ASL ;2
	ASL ;2
	STA PF1Cache ;3
	DEC ScoreD1,X ;5
	;23

	LDY ScoreD2,X ; 3
	LDA Font,Y	;4
	AND #%00001111
	ORA PF1Cache ;3
	STA PF1Cache ;3
	DEC ScoreD2,X ;5
	;18

	LDY ScoreD3,X ; 3
	LDA Font,Y	;4
	AND #%11110000
	STA PF2Cache ;3
	DEC ScoreD3,X ;5
	;15

	LDY ScoreD4,X ; 3
	LDA Font,Y	;4
	LSR ;2
	LSR ;2
	LSR ;2
	LSR ;2
	ORA PF2Cache ;3
	STA PF2Cache ;3
	DEC ScoreD4,X ;5
	;26

	LDY Tmp0 ; Restore the current line
	DEY
	BPL ScoreLoop

	;STA WSYNC

	JSR LoadPF
	STA WSYNC
	STA WSYNC ; Do stuff?
	STA WSYNC

	LDA #PLAYER_1_COLOR
	STA COLUP0
	JSR ClearPF

PrepareForTraffic
	LDA #%00000001
	STA CTRLPF
		;19 cycles worse case before the VSync 

	JSR ClearPF ;30
	;Traffic colour
	LDA #TRAFFIC_COLOR
	STA COLUPF  	

	LDY #SCREEN_SIZE - 5 ;2 #63 ; (Score)

	LDA #BACKGROUND_COLOR ;2 Make it in the very end, so we have one mor nice blue line
	STA COLUBK ;3

;main scanline loop...
ScanLoop 
	STA WSYNC ;?? from the end of the scan loop, sync the final line

;Start of next line!			
DrawCache ;24 Is the last line going to the top of the next frame?

	LDA PF0Cache  ;3
	STA PF0		  ;3

	LDA GRP0Cache ;3 ;buffer was set during last scanline
	STA GRP0      ;3   ;put it as graphics now
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2      ;3

DrawTraffic0; 16 max, 14 min, traffic 0 is the border
	TYA ;2
	CLC ;2
	ADC TrafficOffset0 + 1 ; 3
	AND #%00000100 ;2 Every 4 game lines, draw the border
	BEQ EraseTraffic0; 2
	LDA #%01110000; 2
	JMP StoreTraffic0 ;3
EraseTraffic0
	LDA #0; 2
StoreTraffic0
	STA PF0Cache ;3
SkipDrawTraffic0

BeginDrawCar0Block ;20 is the max, since if draw, does not check active
	LDX Car0Line	;3 check the visible player line...
	BEQ FinishDrawCar0 ;2	skip the drawing if its zero...
DrawCar0
	LDA CarSprite-1,X ;4 (no page cross) otherwise, load the correct line from CarSprite
				;section below... it's off by 1 though, since at zero
				;we stop drawing
	STA GRP0Cache ;3	;put that line as player graphic for the next line
	DEC Car0Line ;5	and decrement the line count
	;STA WSYNC
	JMP SkipActivateCar0 ;3 save some cpu time
FinishDrawCar0

CheckActivateCar0 ;9 max
	CPY #CAR_0_Y ;2
	BNE SkipActivateCar0 ;2
	LDA #CAR_SIZE ;2
	STA Car0Line ;3
	;STA WSYNC
SkipActivateCar0 ;EndDrawCar0Block

	;STA WSYNC ; 3 71 max
	
	TYA ;2
	EOR FrameCount0 ;3
	AND #%00000001 ;2
	BEQ DrawTraffic4;2,4
	;NOP
	; LDA #TRAFFIC_COLOR ;2
	; STA COLUPF ;3

;Will set the initial value for PF1Cache
DrawTraffic1; 
	TYA; 2
	CLC; 2 
	ADC TrafficOffset1 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry; 4 max if branch max, 2 otherwise
	EOR TrafficOffset1 + 2 ; 2
	JMP AfterEorOffsetWithCarry ; 3
EorOffsetWithCarry
	EOR TrafficOffset1 + 3 ; 3
AfterEorOffsetWithCarry ;18
	TAX ;2
	LDA AesTable,X ; 4
	CMP #TRAFFIC_1_CHANCE;2
	BCS EraseTraffic1 ; Greater or equal don't draw; 2 (no branch) or 3 (branch) or 4 (Branch cross page) 
	LDA #%11000000 ;2
	JMP StoreTraffic1 ;3
EraseTraffic1	
	LDA #0 ;2
StoreTraffic1
	STA PF1Cache ;3
FinishDrawTraffic1	
;36 worse, 35 best

DrawTraffic2;
	TYA; 2
	CLC; 2 
	ADC TrafficOffset2 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry2; 4 max if branch max, 2 otherwise
	EOR TrafficOffset2 + 2 ; 2
	JMP AfterEorOffsetWithCarry2 ; 3
EorOffsetWithCarry2
	EOR TrafficOffset2 + 3 ; 3
AfterEorOffsetWithCarry2 ;18
	TAX ;2
	LDA AesTable,X ; 4
	CMP #TRAFFIC_1_CHANCE;2
	BCS FinishDrawTraffic2 ; Greater or equal don't draw; 2 (no branch) or 3 (branch) or 4 (Branch cross page) 
	LDA PF1Cache ;3
	ORA #%00011000 ;2
	STA PF1Cache ;3
FinishDrawTraffic2	
;36 cyles worse case!

	;STA WSYNC ;65 / 137

DrawTraffic3; PF2 is shared with odd and even lines, needs specific logic to erase
	TYA; 2
	CLC; 2 
	ADC TrafficOffset3 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry3; 4 max if branch max, 2 otherwise
	EOR TrafficOffset3 + 2 ; 2
	JMP AfterEorOffsetWithCarry3 ; 3
EorOffsetWithCarry3
	EOR TrafficOffset3 + 3 ; 3
AfterEorOffsetWithCarry3 ; 18
	TAX ;2
	LDA AesTable,X ; 4
	CMP #TRAFFIC_1_CHANCE;2
	BCS FinishDrawTraffic3 ; Greater or equal don't draw; 2 (no branch) or 3 (branch) or 4 (Branch cross page) 
	LDA PF1Cache ;3
	ORA #%00000011 ;2
	STA PF1Cache ;3
FinishDrawTraffic3	
;36 cyles worse case!

	JMP WhileScanLoop ; 3

DrawTraffic4;
	TYA; 2
	CLC; 2 
	ADC TrafficOffset4 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry4; 4 max if branch max, 2 otherwise
	EOR TrafficOffset4 + 2 ; 2
	JMP AfterEorOffsetWithCarry4 ; 3
EorOffsetWithCarry4
	EOR TrafficOffset4 + 3 ; 3
AfterEorOffsetWithCarry4 ;18
	TAX ;2
	LDA AesTable,X ; 4
	CMP #TRAFFIC_1_CHANCE;2
	BCS EraseTraffic4 ; Greater or equal don't draw; 2 (no branch) or 3 (branch) or 4 (Branch cross page) 
	LDA #%00000110 ;2
	JMP StoreTraffic4 ;3
EraseTraffic4	
	LDA #0 ;2
StoreTraffic4
	STA PF2Cache ;3
FinishDrawTraffic4	
;36 max
	
	
	;SLEEP 80
DrawTraffic5;
	TYA; 2
	CLC; 2 
	ADC TrafficOffset5 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry5; 4 max if branch max, 2 otherwise
	EOR TrafficOffset5 + 2 ; 2
	JMP AfterEorOffsetWithCarry5 ; 3
EorOffsetWithCarry5
	EOR TrafficOffset5 + 3 ; 3
AfterEorOffsetWithCarry5 ;18
	TAX ;2
	LDA AesTable,X ; 4
	CMP #TRAFFIC_1_CHANCE;2
	BCS FinishDrawTraffic5 ; 4 Greater or equal don't draw; 2 (no branch) or 3 (branch) or 4 (Branch cross page) 
	LDA PF2Cache ;3
	ORA #%00110000 ;2
	STA PF2Cache ;3	
FinishDrawTraffic5

DrawTraffic6;
	TYA; 2
	CLC; 2 
	ADC TrafficOffset6 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry6; 4 max if branch max, 2 otherwise
	EOR TrafficOffset6 + 2 ; 2
	JMP AfterEorOffsetWithCarry6 ; 3
EorOffsetWithCarry6
	EOR TrafficOffset6 + 3 ; 3
AfterEorOffsetWithCarry6 ;18
	TAX ;2
	LDA AesTable,X ; 4
	CMP #TRAFFIC_1_CHANCE;2
	BCS FinishDrawTraffic6 ; 4 Greater or equal don't draw; 2 (no branch) or 3 (branch) or 4 (Branch cross page) 
	LDA PF2Cache ;3
	ORA #%10000000 ;2
	STA PF2Cache ;3	
FinishDrawTraffic6

;36 max	
	;SLEEP 36


	;STA WSYNC ;65 / 202 of 222

WhileScanLoop 
	DEY	;2
	BMI FinishScanLoop ;2 or 3 ;two big Breach	
	JMP ScanLoop ;3
FinishScanLoop ; 7 209 of 222

	STA WSYNC ;3 Draw the last line, without wrapping
	LDA PF0Cache  ;3
	STA PF0		  ;3

	LDA GRP0Cache ;3 
	STA GRP0      ;3   
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2      ;3

	;42 cycles to use here

PrepareOverscan
	LDA #2		
	STA WSYNC  	
	STA VBLANK 	
	
	LDA #36 ; one more line before overscan
	STA TIM64T	
	;LDA #0
	;STA VSYNC Is it needed? Why is this here, I don't remember		

;Do more logic

OverScanWait
	LDA INTIM	
	BNE OverScanWait ;Is there a better way?	
	JMP MainLoop      

ClearPF ; 26
	LDA #0  	  ;2
	STA PF0		  ;3
	STA PF1	      ;3
	STA PF2       ;3 	
	STA PF0Cache   ;3
	STA PF1Cache   ;3
	STA PF2Cache   ;3 
	RTS ;6

LoadPF ; 24
	LDA PF0Cache  ;3
	STA PF0		  ;3
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2      ;3

	RTS ;6

;ALL CONSTANTS FROM HERE, ALIGN TO AVOID CARRY
	org $FD00
Font	
Space
	.byte %0;
	.byte #0;
	.byte #0;
	.byte #0;
	.byte #0;
N1	
	.byte #%11100111;
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01100110;
N2
	.byte #%11100111;
	.byte #%00100100; 
	.byte #%11100111; 
	.byte #%10000001; 
	.byte #%11100111;

	org $FE00
AesTable
	DC.B $63,$7c,$77,$7b,$f2,$6b,$6f,$c5,$30,$01,$67,$2b,$fe,$d7,$ab,$76
	DC.B $ca,$82,$c9,$7d,$fa,$59,$47,$f0,$ad,$d4,$a2,$af,$9c,$a4,$72,$c0
	DC.B $b7,$fd,$93,$26,$36,$3f,$f7,$cc,$34,$a5,$e5,$f1,$71,$d8,$31,$15
	DC.B $04,$c7,$23,$c3,$18,$96,$05,$9a,$07,$12,$80,$e2,$eb,$27,$b2,$75
	DC.B $09,$83,$2c,$1a,$1b,$6e,$5a,$a0,$52,$3b,$d6,$b3,$29,$e3,$2f,$84
	DC.B $53,$d1,$00,$ed,$20,$fc,$b1,$5b,$6a,$cb,$be,$39,$4a,$4c,$58,$cf
	DC.B $d0,$ef,$aa,$fb,$43,$4d,$33,$85,$45,$f9,$02,$7f,$50,$3c,$9f,$a8
	DC.B $51,$a3,$40,$8f,$92,$9d,$38,$f5,$bc,$b6,$da,$21,$10,$ff,$f3,$d2
	DC.B $cd,$0c,$13,$ec,$5f,$97,$44,$17,$c4,$a7,$7e,$3d,$64,$5d,$19,$73
	DC.B $60,$81,$4f,$dc,$22,$2a,$90,$88,$46,$ee,$b8,$14,$de,$5e,$0b,$db
	DC.B $e0,$32,$3a,$0a,$49,$06,$24,$5c,$c2,$d3,$ac,$62,$91,$95,$e4,$79
	DC.B $e7,$c8,$37,$6d,$8d,$d5,$4e,$a9,$6c,$56,$f4,$ea,$65,$7a,$ae,$08
	DC.B $ba,$78,$25,$2e,$1c,$a6,$b4,$c6,$e8,$dd,$74,$1f,$4b,$bd,$8b,$8a
	DC.B $70,$3e,$b5,$66,$48,$03,$f6,$0e,$61,$35,$57,$b9,$86,$c1,$1d,$9e
	DC.B $e1,$f8,$98,$11,$69,$d9,$8e,$94,$9b,$1e,$87,$e9,$ce,$55,$28,$df
	DC.B $8c,$a1,$89,$0d,$bf,$e6,$42,$68,$41,$99,$2d,$0f,$b0,$54,$bb,$16

; From FF00 to FFFB (122 bytes) to use here

CarSprite ; Upside down
	.byte #%00000000 ; Easist way to stop drawing
	.byte #%11111111
	.byte #%00100100
	.byte #%10111101
	.byte #%00111100
	.byte #%10111101
	.byte #%00111100

	
TrafficSpeeds ;maybe move to ram for dynamic changes of speed and 0 page access
	.byte #$00;  Trafic0 L
	.byte #$00;  Trafic0 H
	.byte #$0A;  Trafic1 L
	.byte #$01;  Trafic1 H
	.byte #$E6;  Trafic2 L
	.byte #$00;  Trafic2 H
	.byte #$C2;  Trafic3 L
	.byte #$00;  Trafic3 H
	.byte #$9E;  Trafic4 L
	.byte #$00;  Trafic4 H
	.byte #$7A;  Trafic5 L
	.byte #$00;  Trafic5 H
	.byte #$56;  Trafic6 L
	.byte #$00;  Trafic6 H


	org $FFFC
		.word Start
		.word Start
