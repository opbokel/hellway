; move a happy face with PlayerBufferStuffer
;OPB game!
	processor 6502
	include vcs.h
	org $F000
	
;contants
ScreenSize = 191;
MaxHoleLine = 186 ;Some numbers does not work. why? Flag BS?
MinHoleLine = 8
Missale0Height = 4;
	
;memory	
YPosFromBot = $80;
VisiblePlayerLine = $81;
PlayerBuffer = $82 ;setup an extra variable
BallHoleStart = $83
BallHoleEnd = $84
ENABLCache = $85 ;Using the whole byte for performance, only need 1 bit, change if need more memory stead of performance
HoleIncrement = $86
ENAM0Cache = $87  
Missile0YPos = $88 
Missile0Line = $89
FrameCount1 = $8A
FrameCount0 = $8B


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
	LDA #$1C   ;lets go for bright yellow, the traditional color for happyfaces
	STA COLUP0
;Setting some variables...
	LDA #80
	STA YPosFromBot	;Initial Y Position
	
	LDA #50
	STA BallHoleStart	;startt hole line
	
	LDA #100
	STA BallHoleEnd	;end hole line
	
	LDA #-2
	STA HoleIncrement

	LDA #70;
	STA Missile0YPos
	LDA #%00100000;
	STA NUSIZ0;Missile 0 4x
	

	;Let's set up the sweeping line. as a Ball

	LDA #2
	STA ENABL  ;enable it
	; LDA #$A1
	; STA COLUPF ;color it
	
	LDA #$F1	
	STA CTRLPF	;Using 8x is the line on the screen (ball) and mirrored playfield
	
	LDA #$F0	; Horizontal motion of the ball left to right only the most signifcative count
	STA HMBL	
	
;VSYNC time
MainLoop
	LDA #2
	STA VSYNC	
	STA WSYNC	
	STA WSYNC 	
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
	INC YPosFromBot
	INC YPosFromBot
SkipMoveDown

	LDA #%00100000	;Up?
	BIT SWCHA 
	BNE SkipMoveUp
	DEC YPosFromBot
	DEC YPosFromBot
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
	LDA #%00001000   ;a 1 in D3 of REFP0 says make it mirror
	STA REFP0
SkipMoveLeft
	
	LDA #%10000000	;Right?
	BIT SWCHA 
	BNE SkipMoveRight
	LDX #$F0	;a -1 in the left nibble means go right...
	LDA #%00000000
	STA REFP0    ;unmirror it

SkipMoveRight

	STX HMP0	;set the move for player 0, not the missile like last time...

	
; see if player0 and ball collide, and change the background color if so
	LDA #%01000000
	BIT CXP0FB		
	BEQ NoCollision	;skip if not hitting...
	LDA YPosFromBot	;must be a hit! load in the YPos...
	STA COLUBK	;and store as the bgcolor
NoCollision
	STA CXCLR	;reset the collision detection for next time
	LDA #0		 ;zero out the buffer
	STA PlayerBuffer ;just in case

; ;init top border
	; LDA #%11111111
	; STA PF0
	; STA PF1
	; STA PF2
	; LDA #$B6
	; STA COLUPF
	
	
	
MoveHole1

InvertBallMovBotton
	LDA HoleIncrement
	BPL SkipInvertBallMoveBotton ;It is moving UP and should not check
	LDA #MinHoleLine
	CMP BallHoleStart
	BMI SkipInvertBallMoveBotton ;if the start line position is less than max
	LDA #2;
	STA HoleIncrement
	; LDA #$25   
	; STA COLUP0	
SkipInvertBallMoveBotton

InvertBallMovTop
	LDA HoleIncrement
	BMI SkipInvertBallMoveTop ;It is moving down and should not check
	LDA #MaxHoleLine
	CMP BallHoleEnd
	BCS SkipInvertBallMoveTop ;if the end line position is greatter than max
	LDA #-2;
	STA HoleIncrement
	; LDA #$CC   
	; STA COLUP0
SkipInvertBallMoveTop


	CLC
	LDA HoleIncrement
	ADC BallHoleStart
	STA BallHoleStart

	CLC         
	LDA HoleIncrement
	ADC BallHoleEnd
	STA BallHoleEnd	
	
CountFrame	
	INC FrameCount0
	BNE SkipIncFC1 ;When it is zero again should increase the MSB
	INC FrameCount1
SkipIncFC1
	
	
; After here we are going to update the screen, No more heavy code
WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd	
	
	LDY #ScreenSize ;#191 ;  	


	STA WSYNC	
	STA HMOVE 	
	
	STA VBLANK  		
	
;main scanline loop...
ScanLoop 
	TYA
	AND #%00000001
	BEQ ProcessLine

DrawLine	
	LDA #$11
	STA COLUPF ;color it

	STA WSYNC 
	
	LDA PlayerBuffer ;buffer was set during last scanline
	STA GRP0         ;put it as graphics now

	;Draw the holes in missiles
	LDA ENABLCache
	STA ENABL
	
	LDA ENAM0Cache
	STA ENAM0
	
	LDA Playfield,Y
	STA PF1
	
	;Test
	LDA #$00;
	STA PF0
	CPY FrameCount0
	BMI sktest
	LDA #$FF;
	STA PF0
	
	LDA #$CC
	STA COLUPF ;color it
	
sktest
	
	; LDA (YPosFromBot+1),Y
	; STA PF1 
	; LDA (YPosFromBot+2),Y
	; STA PF2
	
	; CPY #ScreenSize - 2
    ; BNE SkipHeader
	; LDA #$0
	; STA PF0
	; STA PF1
	; STA PF2
; SkipHeader


	; CPY #2
    ; BNE SkipFooter
	; LDA #%11111111
	; STA PF0
	; STA PF1
	; STA PF2
; SkipFooter






	JMP PrepareNextScanLoop

ProcessLine
	
CheckActivatePlayer
	CPY YPosFromBot
	BNE SkipActivatePlayer
	LDA #9
	STA VisiblePlayerLine 
SkipActivatePlayer


;if the VisiblePlayerLine is non zero,
;we're drawing it next line
;
	LDX VisiblePlayerLine	;check the visible player line...
	BEQ FinishPlayer	;skip the drawing if its zero...
IsPlayerOn	
	LDA BigHeadGraphic-1,X	;otherwise, load the correct line from BigHeadGraphic
				;section below... it's off by 1 though, since at zero
				;we stop drawing
	STA PlayerBuffer	;put that line as player graphic for the next line
	DEC VisiblePlayerLine 	;and decrement the line count
FinishPlayer

CheckStartBall
	CPY BallHoleStart
	BNE SkipStartBall
	LDA #2
	STA ENABLCache  ;disable the missale making the hole
	;Making fun use cache after
	LDA #$A1
	STA COLUPF ;color it
SkipStartBall

CheckEndBall
	CPY BallHoleEnd
	BNE SkipEndBall
	LDA #0
	STA ENABLCache  ;enable the missale closing the hole
	;for fun
	LDA #$33
	STA COLUPF ;color it
SkipEndBall
	


;keep the line count
PrepareNextScanLoop
	DEY		
	BNE ScanLoop	

	LDA #2		
	STA WSYNC  	
	STA VBLANK 	
	
	LDA #35	
	STA TIM64T	
	LDA #0
	STA VSYNC 		

;Do more logic

OverScanWait
	LDA INTIM	
	BNE OverScanWait	
	JMP  MainLoop      

BigHeadGraphic ; Now it is a dog
	;performance. the sprite stops by itself with 0000
	.byte #%00000000
	.byte #%01111110
	.byte #%11000000
	.byte #%10111111
	.byte #%11111101
	.byte #%11001111
	.byte #%11001110
	.byte #%11111100
	.byte #%01010000
	
Playfield
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%10000001
	.byte #%10000001
	.byte #%01000010
	.byte #%01000010
	.byte #%00100100
	.byte #%00100100
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
		.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%10000001
	.byte #%10000001
	.byte #%01000010
	.byte #%01000010
	.byte #%00100100
	.byte #%00100100
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
		.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%11000011
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%10000001
	.byte #%10000001
	.byte #%01000010
	.byte #%01000010
	.byte #%00100100
	.byte #%00100100
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000
	.byte #%00011000


	org $FFFC
	.word Start
	.word Start
