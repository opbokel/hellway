; Hellway! 
; Thanks to AtariAge and all available online docs 
	processor 6502
	include vcs.h
	include macro.h
	org $F000
	
;contants
SCREEN_SIZE = 64;(VSy)
CAR_SIZE = 7
TRAFFIC_SIZE = 7 ; For now, we can make it random later to simulate bigger cars
TRAFFIC_LINE_COUNT = 2
CAR_0_Y = 10
;16 bit precision
;640 max speed!
CAR_MAX_SPEED_H = $02
CAR_MAX_SPEED_L = $80
CAR_MIN_SPEED_H = 0
CAR_MIN_SPEED_L = 0
BACKGROUND_COLOR = $00 ;Black
PLAYER_1_COLOR = $1C ;Yellow
ACCELERATE_SPEED = 1
BREAK_SPEED = 3
ROM_START_MSB = $10
	
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

TrafficOffset0 = $90; Border $91 $92 (24 bit)
TrafficOffset1 = $93; Traffic 1 $94 $95 (24 bit)

;Temporary variables, multiple uses
Tmp0=$A0
Tmp1=$A1
Tmp2=$A2

GameStatus = $C0 ; Flags, D7 = running, expect more flags

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

	LDA #10
	STA TrafficOffset1	;Initial Y Position

;Extract to subrotine? Used also dor the offsets
	LDA #CAR_MIN_SPEED_L
	STA Car0SpeedL
	LDA #CAR_MIN_SPEED_H
	STA Car0SpeedH		
	
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
;Make Objects move in the X axys
	STA HMOVE  ;2
;This must be done after a WSync, otherwise it is impossible to predict the X position
	LDA GameStatus ;3
	EOR #%10000000 ;2 game running, we get 0 and not reset the position.
	BEQ DoNotSetPlayerX ;3
	;Do something better with this 32 cycles
	SLEEP 32;
	STA RESP0 ;3
DoNotSetPlayerX

	STA WSYNC	
	LDA #43	
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

;Break
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

;Temporary code until cars are dynamic, will make it wrap
	;LDA TrafficOffset1
	;AND #%00111111
	;STA TrafficOffset1

;Finish read dpad


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


PrepareNextUpdateLoop
	INY
	INX
	CPX #TRAFFIC_LINE_COUNT * 3;
	BNE UpdateOffsets
	
;Will probably be useful		
CountFrame	
	INC FrameCount0
	BNE SkipIncFC1 ;When it is zero again should increase the MSB
	INC FrameCount1
SkipIncFC1
	
	
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

; After here we are going to update the screen, No more heavy code
WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd ;Is there a better way?	
	
	LDY #SCREEN_SIZE - 1 ;#63 ;  	
	STA WSYNC	
	
	LDA #1
	STA VBLANK  		
	

;main scanline loop...
ScanLoop 
	STA WSYNC ;?? from the end of the scan loop, sync the final line

;Start of next line!			
DrawCache ;24 Is the last line going to the top of the next frame?
	
	LDA GRP0Cache ;3 ;buffer was set during last scanline
	STA GRP0      ;3   ;put it as graphics now

	LDA PF0Cache  ;3
	STA PF0		  ;3
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2      ;3
	

ClearCache ;11 Only the playfields
	LDA #$0 ;2 ;Clear cache
	STA PF1Cache ;3
	STA PF2Cache ; 3
	STA PF0Cache ; 3

DrawTraffic0; 16 max, traffic 0 is the border
	TYA ;2
	CLC ;2
	ADC TrafficOffset0 + 1
	AND #%00000100 ;2 Every 8 game lines, draw the border
	BEQ SkipDrawTraffic0; 2 
	LDA #%01110000; 2
	STA PF0Cache ;3
SkipDrawTraffic0

;51

	STA WSYNC ;73


DrawTraffic1; 17 Max, will be more
	TYA; 2
	CLC; 2 
	ADC TrafficOffset1 + 1;3
	LDA #0 ;2
	ADC TrafficOffset1 + 2;3
	STA PF1Cache ;3

FinishDrawTrafficLine1

	STA WSYNC ;49

BeginDrawCar0Block ;21 is the max, since if draw, does not check active
	LDX Car0Line	;3 check the visible player line...
	BEQ FinishDrawCar0 ;2	skip the drawing if its zero...
DrawCar0
	LDA CarSprite-1,X ;5	;otherwise, load the correct line from CarSprite
				;section below... it's off by 1 though, since at zero
				;we stop drawing
	STA GRP0Cache ;3	;put that line as player graphic for the next line
	DEC Car0Line ;5	and decrement the line count
	JMP SkipActivateCar0 ;3 save some cpu time
FinishDrawCar0

CheckActivateCar0 ;9 max
	CPY #CAR_0_Y ;2
	BNE SkipActivateCar0 ;2
	LDA #CAR_SIZE ;2
	STA Car0Line ;3
SkipActivateCar0 ;EndDrawCar0Block

	
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
	;STA VSYNC Is it needed? Why is this here, I don't remember		

;Do more logic

OverScanWait
	LDA INTIM	
	BNE OverScanWait ;Is there a better way?	
	JMP  MainLoop      


CarSprite ; Upside down
	.byte #%00000000 ; Easist way to stop drawing
	.byte #%11111111
	.byte #%00100100
	.byte #%10111101
	.byte #%00111100
	.byte #%10111101
	.byte #%00111100

	
TrafficSpeeds ;maybe move to ram for dynamic changes of speed and 0 page access
	.byte #0;   Border L
	.byte #0;   Border H
	.byte #$A0; Trafic1 L
	.byte #0;   Trafic1 H

	org $FFFC
	.word Start
	.word Start
