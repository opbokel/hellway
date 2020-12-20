; move a happy face with GRP0CacheStuffer
;OPB game!
	processor 6502
	include vcs.h
	include macro.h
	org $F000
	
;contants
ScreenSize = 64;(192)
CarSize = 7
TrafficLineCount = 1
CarIntialY = 8
CarMaxSpeed = 255
CarMinSpeed = 0
BackgroundColor = $00 ;Black
Player1Color = $1C ;Yellow
	
;memory	
Car0Y = $80
Car0Line = $81 ; Never changes at this point!
GRP0Cache = $82
FrameCount0 = $83;
FrameCount1 = $84;
PF0Cache = $85
PF1Cache = $86
PF2Cache = $87
TrafficOffset0 = $88; Border
Car0Speed = $89
TrafficSpeed0 = $8A
COLUBKCache = $8B

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
	
;Setting some variables...

	LDA #Player1Color
	STA COLUP0

	LDA #CarIntialY
	STA Car0Y	;Initial Y Position

	LDA #CarMinSpeed
	STA Car0Speed	
	
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

;Begin read controlers
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


;Acelerates / breaks the car
	LDA #%00010000	;UP in controller
	BIT SWCHA 
	BNE SkipAccelerate
	INC Car0Speed;
SkipAccelerate
	LDA #%00100000	;Down in controller
	BIT SWCHA 
	BNE SkipBreak
	DEC Car0Speed
SkipBreak


;Finish read controlers
		
;Calculate te relative speeds and update offsets
	LDY #2
RepeatUpdateLines ;to be able to rum more than one line at a time
	LDX #TrafficLineCount
UpdateLines
	LDA Car0Speed
	CMP TrafficSpeeds-1,X
	BCC TrafficIsFaster ;See 6502 specs, jump if the car is slower than traffic
PlayerIsFaster
	SEC
	SBC TrafficSpeeds-1,X
	CLC
	ADC TrafficSpeed0-1,X
	STA TrafficSpeed0-1,X
	BCC PrepareNextUpdateLoop; Change the offset only when there is a carry!
	INC TrafficOffset0-1,X	
	JMP PrepareNextUpdateLoop
TrafficIsFaster 
	LDA TrafficSpeeds-1,X
	SEC
	SBC Car0Speed
	CLC
	ADC TrafficSpeed0-1,X
	STA TrafficSpeed0-1,X
	BCC PrepareNextUpdateLoop; Change the offset only when there is a carry!
	DEC TrafficOffset0-1,X
PrepareNextUpdateLoop
	DEX
	BNE UpdateLines
	DEY 
	BNE RepeatUpdateLines
	
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
	STA WSYNC ;10 from the end of the scan loop, sync the final line
			
DrawCache ;24
	
	LDA COLUBKCache
	STA COLUBK	

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
	

	STA WSYNC ;73


	;STA WSYNC ;75
	
DrawCar0; Border
	DEC TrafficOffset0; 5 Make the shape change per line;
	LDA TrafficOffset0 ;3
	AND #%00000100 ;2 Every 8 game lines, draw the border
	BEQ SkipCar0Draw;2 
	LDA #%01110000 ;2
	STA PF0Cache ;3
SkipCar0Draw

	STA WSYNC ;49

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

CarSprite ; Upside down
	.byte #%00000000 ; Easist way to stop drawing
	.byte #%11111111
	.byte #%00100100
	.byte #%10111101
	.byte #%00111100
	.byte #%10111101
	.byte #%00111100

	
TrafficSpeeds ;maybe move to ram for dynamic changes and speed of 0 page access
	.byte #0 ; Border

	org $FFFC
	.word Start
	.word Start
