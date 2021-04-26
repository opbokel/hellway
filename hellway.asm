; Hellway! 
; Thanks to AtariAge and all available online docs 
	processor 6502
	include vcs.h
	include macro.h
	org $F000
	
;contants
SCREEN_SIZE = 72;(VSy)
SCORE_SIZE = 5
GAMEPLAY_AREA = SCREEN_SIZE - SCORE_SIZE - 1;
FONT_OFFSET = #SCORE_SIZE -1
COLLISION_FRAMES = $FF; 4,5 seconds
SCORE_FONT_HOLD_CHANGE = $FF; 4,5 seconds
COLLISION_SPEED_L = $10;

WARN_TIME_ENDING = 10 ; Exclusive

TRAFFIC_LINE_COUNT = 5
;16 bit precision
;640 max speed!
CAR_MAX_SPEED_H = $02; L is in a table

CAR_MIN_SPEED_H = 0
CAR_MIN_SPEED_L = 0
CAR_START_LINE = 14 ; Exclusive

CAR_ID_DEFAULT = 0
CAR_ID_HATCHBACK = 1
CAR_ID_SEDAN = 2
CAR_ID_DRAGSTER = 3

DRAGSTER_TURN_MASK = %00000001;

BREAK_SPEED = 10
;For now, will use in all rows until figure out if make it dynamic or not.
TRAFFIC_1_MASK = %11111000 ;Min car size... Maybe make different per track

TRAFFIC_CHANCE_LIGHT = 14
CHECKPOINT_TIME_LIGHT = 29
TRAFFIC_COLOR_LIGHT = $D4

TRAFFIC_CHANCE_REGULAR = 24
CHECKPOINT_TIME_REGULAR = 34
TRAFFIC_COLOR_REGULAR = $34

TRAFFIC_CHANCE_INTENSE = 34
CHECKPOINT_TIME_INTENSE = 39
TRAFFIC_COLOR_INTENSE = $79

TRAFFIC_CHANCE_RUSH_HOUR = 44
CHECKPOINT_TIME_RUSH_HOUR = 44
TRAFFIC_COLOR_RUSH_HOUR = $09

BACKGROUND_COLOR = $03 ;Grey
SCORE_BACKGROUND_COLOR = $A0

SCORE_FONT_COLOR_EASTER_EGG = $38

PLAYER1_COLOR = $96

SCORE_FONT_COLOR = $F9
SCORE_FONT_COLOR_GOOD = $D8
SCORE_FONT_COLOR_BAD = $44
SCORE_FONT_COLOR_START = $C8 ;Cannot be the same as good, font colors = game state
SCORE_FONT_COLOR_OVER = $0C

PLAYER_0_X_START = $35;
PLAYER_0_MAX_X = $36 ; Going left will underflow to FF, so it only have to be less (unsigned) than this

INITIAL_COUNTDOWN_TIME = 90; Seconds +-
CHECKPOINT_INTERVAL = $10 ; Acts uppon TrafficOffset0 + 3
TIMEOVER_BREAK_SPEED = 1

SWITCHES_DEBOUNCE_TIME = 30 ; Frames

BLACK = $00;

MAX_GAME_MODE = 16

PARALLAX_SIZE = 8

HALF_TEXT_SIZE = 5

ONE_SECOND_FRAMES = 60

VERSION_COLOR = $49

QR_CODE_LINE_HEIGHT = 7
QR_CODE_BACKGROUNG = $0F
QR_CODE_COLOR = $00
QR_CODE_SIZE = 25

CURRENT_CAR_MASK = %00000011; 4 cars

;43 default, one less line 2 We start the drawing cycle after 36 lines, because drawing is delayed by one line. 
VBLANK_TIMER = 41
;Almost no game processing with QR code. This gives bleading space by reducing vblank (Still acceptable limits)
VBLANK_TIMER_QR_CODE = 26 ; 22 lines 
	
GRP0Cache = $80
PF0Cache = $81
PF1Cache = $82
PF2Cache = $83
GRP1Cache = $84
ENABLCache = $85
ENAM0Cache = $86
ENAM1Cache = $87

ParallaxMode = $88

FrameCount0 = $8C;
FrameCount1 = $8D;

Player0SpeedL = $8E
Player0SpeedH = $8F

TrafficOffset0 = $90; Border $91 $92 (24 bit) $93 is cache
TrafficOffset1 = $94; Traffic 1 $94 $95 (24 bit) $96 is cache
TrafficOffset2 = $98; Traffic 1 $99 $9A (24 bit) $9B is cache
TrafficOffset3 = $9C; Traffic 1 $9D $9E (24 bit) $9F is cache
TrafficOffset4 = $A0; Traffic 1 $A1 $A2 (24 bit) $A3 is cache

CheckpointBcd0 = $A4
CheckpointBcd1 = $A5
StartSWCHB = $A6 ; Used for Score, so it cannot be cheated.
CarSpritePointerL = $A7
CarSpritePointerH = $A8
CurrentCarId = $A9
AccelerateBuffer = $AA ; Change speed on buffer overflow.
TextSide = $AB
TextFlickerMode = $AC
Gear = $AD

;Temporary variables, multiple uses
Tmp0 = $B0
Tmp1 = $B1
Tmp2 = $B2
Tmp3 = $B3

ScoreBcd0 = $B4
ScoreBcd1 = $B5
ScoreBcd2 = $B6
ScoreBcd3 = $B7

CollisionCounter=$B8
Player0X = $B9
CountdownTimer = $BA
Traffic0Msb = $BB
SwitchDebounceCounter = $BC

TimeBcd0 = $BD
TimeBcd1 = $BE
TimeBcd2 = $BF

GameStatus = $C0 ; Not zero is running! No need to make it a bit flag for now.
TrafficChance = $C1
CheckpointTime = $C2
TrafficColor = $C3
CurrentDifficulty = $C4
GameMode = $C5 ; Bit 0 controls fixed levels, bit 1 random positions, 
				;Bit 2 speed delta, Bit 3 random traffic 

ParallaxOffset1 = $C6 ; C7 
ParallaxOffset2 = $C8 ; C9

BorderType = $CA

HitCountBcd0 = $CB
HitCountBcd1 = $CC

GlideTimeBcd0 = $CD
GlideTimeBcd1 = $CE

OneSecondConter = $CF

ScoreD0 = $D0
ScoreD1 = $D1
ScoreD2 = $D2
ScoreD3 = $D3
ScoreD4 = $D4
ScoreFontColor=$D5
ScoreFontColorHoldChange=$D6
NextCheckpoint=$D7

ParallaxCache=$D8 ; to $DF
ParallaxCache2=$F0 ; to F7


;generic start up stuff, put zero in almost all...
BeforeStart ;All variables that are kept on game reset or select
	LDY #0
	STY SwitchDebounceCounter
	STY CurrentDifficulty
	STY GameStatus
	LDY #16
	STY GameMode
	LDY #%11100000 ; Default Parallax
	STY ParallaxMode
	LDY #CURRENT_CAR_MASK ; Also the max id.
	STY CurrentCarId

Start
	LDA #2
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #0 ;2
	STA VSYNC ;3

	SEI	
	CLD 	
	LDX #$FF	
	TXS	

	LDX #68 ; Skips (VSYNC, RSYNC, WSYNC, VBLANK), TIA is mirrored on 64 - 127
CleanMem 
	CPX #SwitchDebounceCounter
	BEQ SkipClean
	CPX #GameMode
	BEQ SkipClean
	CPX #ParallaxMode
	BEQ SkipClean
	CPX #CurrentCarId
	BEQ SkipClean
	CPX #CurrentDifficulty
	BEQ SkipClean
	CPX #GameStatus
	BEQ SkipClean
	STA 0,X		
SkipClean	
	INX
	BNE CleanMem

	LDA #213
	STA TIM64T ;3	

;Setting some variables...

SettingTrafficOffsets; Time sensitive with player H position
	STA WSYNC ;We will set player position
	JSR DefaultOffsets

	LDA TrafficSpeeds + 4 * 2 ; Same as the line he is in.
	STA Player0SpeedL
	
	SLEEP 11;18
	STA RESP0
		
	LDX #0
	LDA SWCHB ; Reading the switches and mapping to difficulty id
	STA StartSWCHB ; For game over
	AND #%11000000
	BEQ CallConfigureDifficulty
	INX
	CMP #%10000000
	BEQ CallConfigureDifficulty
	INX
	CMP #%01000000
	BEQ CallConfigureDifficulty
	INX

CallConfigureDifficulty
	CPX CurrentDifficulty; Checks change on dificulty Switches
	BNE StoreCurrentDifficulty; Do not change car
	LDA GameStatus
	BNE StoreCurrentDifficulty ; Do not change car for a game running reset
NextCar
	LDY CurrentCarId
	INY
	TYA
	AND #CURRENT_CAR_MASK ; Cycles 4 values...
	STA CurrentCarId
StoreCurrentDifficulty
	STX CurrentDifficulty
	JSR ConfigureDifficulty

ConfigureCarSprite
	LDY CurrentCarId
	LDA CarIdToSpriteAddressL,Y
	STA CarSpritePointerL
	LDA CarIdToSpriteAddressH,Y
	STA CarSpritePointerH

SetGameNotRunning
	LDA #0
	STA GameStatus

ConfigureOneSecondTimer
	LDA #ONE_SECOND_FRAMES
	STA OneSecondConter

HPositioning
	STA WSYNC

	LDA #%00110000;2 Missile Size
	STA NUSIZ0 ;3
	STA NUSIZ1 ;3

	LDA #PLAYER_0_X_START ;2
	STA Player0X ;3

	LDA #INITIAL_COUNTDOWN_TIME ;2
	STA CountdownTimer ;3

	LDA #CHECKPOINT_INTERVAL
	STA NextCheckpoint

	LDA #0 ; Avoid missile reseting position 
	SLEEP 11;
	STA RESP1
	SLEEP 2;
	STA RESBL
	SLEEP 2;
	STA RESM0
	SLEEP 2
	STA RESM1

	LDA #$F0
	STA HMBL
	STA HMM0
	STA HMM1
	STA WSYNC
	STA HMOVE
	STA WSYNC ; Time is irrelevant before sync to TV, ROM space is not!
	STA HMCLR

WaitResetToEnd
	LDA INTIM	
	BNE WaitResetToEnd

MainLoop
	LDA #2
	STA VSYNC	
	STA WSYNC

CalculateTextSide ; Here because it is a waste of cycles not to put anything
	LDA #%00000001
	BIT TextFlickerMode
	BEQ TextSideFrameZero
	AND FrameCount1
	JMP StoreTextSize
TextSideFrameZero
	AND FrameCount0
StoreTextSize	
	STA TextSide

	STA WSYNC					;Apply Movement, must be done after a WSYNC
	STA HMOVE  ;2
ConfigVBlankTimer
	LDA GameMode
	CMP #MAX_GAME_MODE
	BEQ SetVblankTimerQrCode
	LDA #VBLANK_TIMER
	JMP SetVblankTimer
SetVblankTimerQrCode
	LDA #VBLANK_TIMER_QR_CODE
SetVblankTimer
	STA WSYNC ;3
	STA TIM64T ;3	
	LDA #0 ;2
	STA VSYNC ;3	

RandomizeGame
	LDA GameStatus ;Could be merge with code block bellow
	BNE EndRandomizeGame
	LDA GameMode ; Games 3 and for and not running
	AND #%00000010
	BEQ DeterministicGame
	LDX TrafficOffset1 + 2
	LDA AesTable,X
	EOR FrameCount0
	STA TrafficOffset1 + 2
	LDX TrafficOffset2 + 2
	LDA AesTable,X
	EOR FrameCount0
	STA TrafficOffset2 + 2
	LDX TrafficOffset3 + 2
	LDA AesTable,X
	EOR FrameCount0
	STA TrafficOffset3 + 2
	LDX TrafficOffset4 + 2
	LDA AesTable,X
	EOR FrameCount0
	STA TrafficOffset4 + 2
	JMP EndRandomizeGame

DeterministicGame
	JSR DefaultOffsets

EndRandomizeGame
	
CountFrame	
	INC FrameCount0 ; 5
	BNE SkipIncFC1 ; 2 When it is zero again should increase the MSB
	INC FrameCount1 ; 5 
SkipIncFC1

CallDrawQrCode
	LDA GameMode
	CMP #MAX_GAME_MODE
	BNE TestIsGameRunning
	JMP DrawQrCode

;Does not update the game if not running
TestIsGameRunning
	LDA GameStatus ;3
	BNE ContinueWithGameLogic ;3 Cannot branch more than 128 bytes, so we have to use JMP
	JMP SkipUpdateLogic
ContinueWithGameLogic

EverySecond ; 64 frames to be more precise
	LDA #%00111111
	AND FrameCount0
	BNE SkipEverySecondAction
	CMP CountdownTimer
	BEQ SkipEverySecondAction ; Stop at Zero
	DEC CountdownTimer
SkipEverySecondAction

ChangeTextFlickerMode
	LDA SwitchDebounceCounter
	BNE EndChangeTextFlickerMode
	LDA SWCHB
	AND #%00000010 ;Game select
	BNE EndChangeTextFlickerMode
	INC TextFlickerMode
	LDA #SWITCHES_DEBOUNCE_TIME
	STA SwitchDebounceCounter
EndChangeTextFlickerMode

BreakOnTimeOver ; Uses LDX as the breaking speed
	LDX #0
	LDA CountdownTimer
	BNE Break
	LDY CurrentCarId
	LDA FrameCount0
	AND CarIdToTimeoverBreakInterval,Y
	BNE Break 
	LDX #TIMEOVER_BREAK_SPEED
	
Break
	LDA #%00100000	;Down in controller
	BIT SWCHA 
	BNE BreakNonZero
	LDA INPT4 ;3
	BPL BreakWhileAccelerating
	LDY Gear
	LDX GearToBreakSpeedTable,Y ; Different break speeds depending on speed.
	JMP BreakNonZero
BreakWhileAccelerating ; Allow better control while breaking.
	LDX (#BREAK_SPEED / 2)

BreakNonZero
	CPX #0
	BEQ SkipBreak
	STX Tmp0

DecreaseSpeed
	SEC
	LDA Player0SpeedL
	SBC Tmp0
	STA Player0SpeedL
	LDA Player0SpeedH
	SBC #0
	STA Player0SpeedH

CheckMinSpeed
	BMI ResetMinSpeed; Overflow d7 is set
	CMP #CAR_MIN_SPEED_H
	BEQ CompareLBreakSpeed; is the same as minimun, compare other byte.
	BCS SkipAccelerateIfBreaking; Greater than min, we are ok! 

CompareLBreakSpeed	
	LDA Player0SpeedL
	CMP #CAR_MIN_SPEED_L	
	BCC ResetMinSpeed ; Less than memory
	JMP SkipAccelerateIfBreaking ; We are greather than min speed in the low byte.

ResetMinSpeed
	LDA #CAR_MIN_SPEED_H
	STA Player0SpeedH
	LDA #CAR_MIN_SPEED_L
	STA Player0SpeedL

SkipAccelerateIfBreaking
	JMP SkipAccelerate
SkipBreak

Acelerates
	LDA CountdownTimer
	BEQ SkipAccelerate; cannot accelerate if timer is zero

ContinueAccelerateTest
	LDA INPT4 ;3
	BPL IncreaseCarSpeed ; Test button and then up, both accelerate.
	LDA #%00010000	;UP in controller
	BIT SWCHA 
	BNE SkipAccelerate

IncreaseCarSpeed
	LDX #2
	LDY CurrentCarId
IncreaseCarSpeedLoop
;Adds speed
	CLC
	LDA AccelerateBuffer
	ADC CarIdToAccelerateSpeed,Y
	STA AccelerateBuffer
	BCC ContinueIncreaseSpeedLoop ; Not enought in the buffer to change speed
	INC Player0SpeedL
	BNE ContinueIncreaseSpeedLoop ; When turns Zero again, increase MSB
	INC Player0SpeedH
ContinueIncreaseSpeedLoop
	DEX
	BNE IncreaseCarSpeedLoop
SkipIncreaseCarSpeed

CheckIfAlreadyMaxSpeed
	LDA Player0SpeedH
	CMP #CAR_MAX_SPEED_H
	BCC SkipAccelerate ; less than my max speed
	BNE ResetToMaxSpeed ; Not equal, so if I am less, and not equal, I am more!
	;High bit is max, compare the low
	LDY CurrentCarId
	LDA Player0SpeedL
	CMP CarIdToMaxSpeedL,Y
	BCC SkipAccelerate ; High bit is max, but low bit is not
	;BEQ SkipAccelerate ; Optimize best case, but not worse case

ResetToMaxSpeed ; Speed is more, or is already max
	LDA #CAR_MAX_SPEED_H
	STA Player0SpeedH
	LDY CurrentCarId
	LDA CarIdToMaxSpeedL,Y
	STA Player0SpeedL
SkipAccelerate

InitUpdateOffsets
	LDX #0 ; Memory Offset 24 bit
	LDY #0 ; Line Speeds 16 bits
	LDA TrafficOffset0 + 1;
	STA Tmp3 ; Used for bcd score, to detect change on D4
	LDA GameMode
	AND #%00000100 ; GameModes with high delta
	BEQ UpdateOffsets
	LDY #(TrafficSpeedsHighDelta - TrafficSpeeds)
	
UpdateOffsets; Car sped - traffic speed = how much to change offet (signed)
	SEC
	LDA Player0SpeedL
	SBC TrafficSpeeds,Y
	STA Tmp0
	INY
	LDA Player0SpeedH
	SBC TrafficSpeeds,Y
	STA Tmp1
	LDA #0; Hard to figure out, makes the 2 complement result work correctly, since we use this 16 bit signed result in a 24 bit operation
	SBC #0
	STA Tmp2

AddsTheResult
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
	BCC CalculateOffsetCache
	CPX #2 ;MSB offset 0
	BNE CalculateOffsetCache
	INC Traffic0Msb

CalculateOffsetCache
	INX
	SEC
	ADC #0 ;Increment by one
	STA TrafficOffset0,X ; cache of the other possible value for the MSB in the frame, make drawing faster.

PrepareNextUpdateLoop
	INY
	INX
	CPX #TRAFFIC_LINE_COUNT * 4;
	BNE UpdateOffsets

BcdScore ; 48
	LDA TrafficOffset0 + 1 ;3
	EOR Tmp3 ;3
	AND #%00010000 ; 2 Change in D4 means change on screen first digit, inc BCD
	BEQ FinishBcdScore ;2

ContinueBcdScore
	SED ;2
	CLC ;2
	LDA ScoreBcd0 ;3
	ADC #1 ;2
	STA ScoreBcd0 ;3
	LDA ScoreBcd1 ;3
	ADC #0 ;2
	STA ScoreBcd1 ;3
	LDA ScoreBcd2 ;3
	ADC #0 ;2
	STA ScoreBcd2 ;3
	LDA ScoreBcd3 ;3
	ADC #0 ;2
	STA ScoreBcd3 ;3
	CLD ;2
FinishBcdScore

;Until store the movemnt, LDX contains the value to be stored.
TestCollision;
; see if player0 colides with the rest
	LDA CXM0P
	ORA CXM1P
	ORA CXM1P
	ORA CXP0FB
	ORA CXPPMM
	AND #%11000000 ; Accounting for random noise in the bus		
	BEQ NoCollision	;skip if not hitting...
	LDA CollisionCounter ; If colision is alredy happening, ignore!
	BNE NoCollision	
	LDA ScoreFontColor ; Ignore colisions during checkpoint (Green Score)
	CMP #SCORE_FONT_COLOR_GOOD
	BEQ NoCollision
	CMP #SCORE_FONT_COLOR_START
	BEQ NoCollision
	LDA #COLLISION_FRAMES	;must be a hit! Change rand color bg
	STA CollisionCounter	;and store as colision.
CountBcdColision
	LDA ScoreFontColor ; Do not count colisions on game over.
	CMP #SCORE_FONT_COLOR_OVER
	BEQ SkipSetColisionSpeedL
	SED ;2
	CLC ;2
	LDA HitCountBcd0 ;3
	ADC #1 ;3
	STA HitCountBcd0 ;3
	LDA HitCountBcd1 ;3
	ADC #0 ;2
	STA HitCountBcd1 ;3
	CLD ;2
EndCountBcdColision
	LDA Player0SpeedH
	BNE SetColisionSpeedL ; Never skips setting colision speed if high byte > 0
	LDA #COLLISION_SPEED_L
	CMP Player0SpeedL
	BCS SkipSetColisionSpeedL
SetColisionSpeedL
	LDA #COLLISION_SPEED_L ; Needs optimization!
	STA Player0SpeedL
SkipSetColisionSpeedL	
	LDA #0
	STA Player0SpeedH
	LDX #$40	;Move car left 4 color clocks, to center the stretch (+4)	
	JMP StoreHMove ; We keep position consistent
NoCollision

DecrementCollision
	LDY CollisionCounter
	BEQ FinishDecrementCollision
	LDA #%00110101; Make player bigger to show colision
	STA NUSIZ0
	DEY
	STY CollisionCounter ; We save some cycles in reset size.
FinishDecrementCollision

ResetPlayerSize
	BNE FinishResetPlayerSize
	LDA #%00110000
	STA NUSIZ0;
FinishResetPlayerSize

ResetPlayerPosition ;For 1 frame, he will not colide, but will have the origina size
	CPY #1 ; Last frame before reset
	BNE SkipResetPlayerPosition
	LDX #$C0	;Move car left 4 color clocks, to center the stretch (-4)
	JMP StoreHMove
SkipResetPlayerPosition

MakeDragsterTurnSlow ; Only car diff that does not use a table.
	LDA CurrentCarId
	CMP #CAR_ID_DRAGSTER
	BNE PrepareReadXAxis
	LDX #0
	LDA FrameCount0
	AND #DRAGSTER_TURN_MASK
	BEQ StoreHMove ; Ignore movement on some frames

; for left and right, we're gonna 
; set the horizontal speed, and then do
; a single HMOVE.  We'll use X to hold the
; horizontal speed, then store it in the 
; appropriate register
PrepareReadXAxis
	LDX #0
	LDY Player0X
BeginReadLeft
	BEQ SkipMoveLeft ; We do not move after maximum
	LDA #%01000000	;Left
	BIT SWCHA 
	BNE SkipMoveLeft
	LDX #$10	;a 1 in the left nibble means go left
	DEC Player0X
	JMP StoreHMove ; Cannot move left and right...
SkipMoveLeft
BeginReadRight
	CPY #PLAYER_0_MAX_X
	BEQ SkipMoveRight ; At max already
	LDA #%10000000	;Right
	BIT SWCHA 
	BNE SkipMoveRight
	LDX #$F0	;a -1 in the left nibble means go right...
	INC Player0X
SkipMoveRight
StoreHMove
	STX HMP0	;set the move for player 0, not the missile like last time...
	STA CXCLR	;reset the collision detection for next frame.

DividePlayerSpeedBy4
	LDA Player0SpeedH
	ASL
	ASL
	ASL
	ASL
	ASL
	ASL
	STA Tmp1
	LDA Player0SpeedL
	LSR
	LSR
	AND #%00111111
	ORA Tmp1
	STA Tmp0 ; Division Result

CalculateParallax1Offset ; 3/4 speed
	SEC
	LDA Player0SpeedL
	SBC Tmp0
	STA Tmp2
	LDA Player0SpeedH
	SBC #0
	STA Tmp3

	CLC
	LDA ParallaxOffset1
	ADC Tmp2
	STA ParallaxOffset1
	LDA ParallaxOffset1 + 1
	ADC Tmp3
	STA ParallaxOffset1 + 1

CalculateParallax2Offset ; 2/4 speed
	SEC
	LDA Tmp2
	SBC Tmp0
	STA Tmp2
	LDA Tmp3
	SBC #0
	STA Tmp3

	CLC
	LDA ParallaxOffset2
	ADC Tmp2
	STA ParallaxOffset2
	LDA ParallaxOffset2 + 1
	ADC Tmp3
	STA ParallaxOffset2 + 1

SkipUpdateLogic ; Continue here if not paused

CalculateGear
	LDA Player0SpeedL  ;3
	AND #%10000000      ;2
	ORA Player0SpeedH   ;3
	CLC                 ;2
	ROL                 ;2
	ADC #0 ; 2 Places the possible carry produced by ROL
	STA Gear

ProcessBorder ;Can be optimized (probably)
	LDY #PARALLAX_SIZE - 1 ; Used by all SBRs
	LDA ParallaxMode
	CMP #%01110000
	BEQ HorizontalParallaxMode
	CMP #%11010000
	BEQ VerticalParallaxMode
	CMP #%10110000
	BEQ TachometerMode	

DefaultBorderMode
	JSR DefaultBorderLoop
	JMP EndProcessingBorder
VerticalParallaxMode
	JSR VerticalParallaxLoop
	JMP EndProcessingBorder
TachometerMode
	JSR PrepareTachometerBorderLoop
	JMP EndProcessingBorder
HorizontalParallaxMode
	JSR HorizontalParallaxLoop

EndProcessingBorder

ProcessScoreFontColor
	LDX ScoreFontColorHoldChange
	BEQ ResetScoreFontColor
	DEX
	STX ScoreFontColorHoldChange
	JMP SkipScoreFontColor
ResetScoreFontColor
	LDA #SCORE_FONT_COLOR
	STA ScoreFontColor
SkipScoreFontColor

IsGameOver
	LDA CountdownTimer
	ORA Player0SpeedL
	ORA Player0SpeedH
	BNE IsCheckpoint
	LDA #1
	STA ScoreFontColorHoldChange
	LDA #SCORE_FONT_COLOR_OVER
	STA ScoreFontColor
	JMP SkipIsTimeOver

IsCheckpoint
	LDA NextCheckpoint
	CMP TrafficOffset0 + 2
	BNE SkipIsCheckpoint
	CLC
	ADC #CHECKPOINT_INTERVAL
	STA NextCheckpoint
	LDA #SCORE_FONT_COLOR_GOOD
	STA ScoreFontColor
	LDA #SCORE_FONT_HOLD_CHANGE
	STA ScoreFontColorHoldChange
AddCheckpointBcd
	SED ;2
	CLC ;2
	LDA CheckpointBcd0 ;3
	ADC #1 ;3
	STA CheckpointBcd0 ;3
	LDA CheckpointBcd1 ;3
	ADC #0 ;2
	STA CheckpointBcd1 ;3
	CLD ;2
EndCheckpointBcd
	LDA CountdownTimer
	CLC
	ADC CheckpointTime
	STA CountdownTimer
	BCC JumpSkipTimeOver
	LDA #$FF
	STA CountdownTimer ; Does not overflow!
JumpSkipTimeOver
	JSR NextDifficulty ; Increments to the next dificulty (Will depend on game mode in the future)
	JMP SkipIsTimeOver ; Checkpoints will add time, so no time over routine, should also override time over.
SkipIsCheckpoint

IsTimeOver
	LDA CountdownTimer
	BNE SkipIsTimeOver
	LDA #1 ; Red while 0, so just sets for the next frame, might still pass a checkpoint by inertia
	STA ScoreFontColorHoldChange
	LDA #SCORE_FONT_COLOR_BAD
	STA ScoreFontColor
SkipIsTimeOver

ExactlyEverySecond ; 88 Here to use this nice extra cycles of the 5 scanlines
	LDA GameStatus ;3
	BEQ EndExactlyEverySecond ; 2 Count only while game running
	LDA ScoreFontColor ;3
	CMP #SCORE_FONT_COLOR_OVER ;2
	BEQ EndExactlyEverySecond ;2
	DEC OneSecondConter ;5
	BNE EndExactlyEverySecond ;2

	SED ;2 BCD Operations after this point
CountGlideTimeBcd
	LDA ScoreFontColor ;3
	CMP #SCORE_FONT_COLOR_BAD ;2
	BNE EndCountGlideTimeBcd ;2
	CLC ;2
	LDA GlideTimeBcd0 ;3
	ADC #1 ;3
	STA GlideTimeBcd0 ;3
	LDA GlideTimeBcd1 ;3
	ADC #0 ;2
	STA GlideTimeBcd1 ;3
EndCountGlideTimeBcd
IncreaseTotalTimerBcd
	CLC ;2
	LDA TimeBcd0 ;3
	ADC #1 ;2
	STA TimeBcd0 ;3
	LDA TimeBcd1 ;3
	ADC #0 ;2
	STA TimeBcd1 ;3
	LDA TimeBcd2 ;3
	ADC #0 ;2
	STA TimeBcd2 ;3

ResetOneSecondCounter
	CLD ;2
	LDA #ONE_SECOND_FRAMES ;3
	STA OneSecondConter ;3

EndExactlyEverySecond

PrintEasterEggCondition
	LDA FrameCount1
	AND #%00111000
	ORA GameStatus
	CMP #%00111000
	BNE ChooseTextSide
	JSR PrintEasterEgg
	JMP RightScoreWriteEnd

;Could be done during on vblank to save this comparisson time (before draw score), 
;but I am saving vblank cycles for now, in case of 2 players.
ChooseTextSide ; 
	LDA TextSide ;3
	BNE LeftScoreWrite ; Half of the screen with the correct colors.
	JMP RightScoreWrite 

LeftScoreWrite
	LDA ScoreFontColor
	CMP #SCORE_FONT_COLOR_GOOD
	BEQ PrintCheckpoint
	CMP #SCORE_FONT_COLOR_START
	BEQ PrintStartGame
	LDA GameStatus
	BEQ PrintHellwayLeft
WriteDistance ;Not optimized yet, ugly code.
Digit0Distance
	LDA TrafficOffset0 + 1 ;3
	LSR ; 2
	LSR ; 2
	LSR ; 2
	LSR ; 2
	TAX ; 2
	LDA FontLookup,X ;4
	STA ScoreD3 ;3

Digit1Distance
	LDA TrafficOffset0 + 2 ;3
	AND #%00001111 ;2
	TAX ; 2
	LDA FontLookup,X ;4 
	STA ScoreD2 ;3

Digit2Distance
	LDA TrafficOffset0 + 2 ;3
	LSR ; 2
	LSR ; 2
	LSR ; 2
	LSR ; 2
	TAX ; 2
	LDA FontLookup,X ;4
	STA ScoreD1 ;3

Digit3Distance
	LDA Traffic0Msb ;3
	AND #%00001111 ;2
	TAX ; 2
	LDA FontLookup,X ;4 
	STA ScoreD0 ;3

DistanceOverflowDigit ; If overflow, the pipe becomes the last digit
	LDA Traffic0Msb
	AND #%11110000 ;2
	BNE DrawDistanceExtraDigit
	LDA #<Pipe + #FONT_OFFSET;3
	STA ScoreD4 ;3
	JMP EndDrawDistance
DrawDistanceExtraDigit
	LSR ; 2
	LSR ; 2
	LSR ; 2
	LSR ; 2
	TAX ; 2
	LDA FontLookup,X ;4
	STA ScoreD4 ;3

EndDrawDistance
	JMP RightScoreWriteEnd;3

PrintCheckpoint
	LDX #<CheckpointText
	JSR PrintStaticText
	JMP RightScoreWriteEnd;3
PrintStartGame
	LDX #<GoText
	JSR PrintStaticText
	JMP RightScoreWriteEnd;3

PrintHellwayLeft
	LDA FrameCount1
	AND #1
	BNE PrintCreditsLeft
	LDX #<HellwayLeftText
	JMP PrintGameMode
PrintCreditsLeft
	LDX #<OpbText

PrintGameMode
	JSR PrintStaticText
	LDX GameMode
	LDA FontLookup,X ;4 
	STA ScoreD0 ;3
	JMP RightScoreWriteEnd;3

RightScoreWrite
	LDA GameStatus
	BEQ PrintHellwayRight
	LDA ScoreFontColor
	CMP #SCORE_FONT_COLOR_OVER
	BEQ PrintGameOver
Digit0Timer
	LDA CountdownTimer ;3
	AND #%00001111 ;2
	TAX ; 2
	LDA FontLookup,X ;4 
	STA ScoreD1 ;3

Digit1Timer
	LDA CountdownTimer ;3
	LSR ; 2
	LSR ; 2
	LSR ; 2
	LSR ; 2
	TAX ; 2
	LDA FontLookup,X ;4
	STA ScoreD0 ;3

	LDA #<Pipe + #FONT_OFFSET ;3
	STA ScoreD2 ;3

Digit0Speed
	LDA Player0SpeedL
	AND #%00111100 ;2 Discard the last bits
	LSR ; 2
	LSR ; 2
	TAX ; 2
	LDA FontLookup,X ;4
	STA ScoreD4 ;3

Digit1Speed
	LDA Player0SpeedL
	AND #%11000000 ;2 Discard the last bits
	CLC
	ROL ;First goes into carry
	ROL
	ROL
	STA Tmp0
	LDA Player0SpeedH
	ASL
	ASL
	ORA Tmp0
	TAX ; 2
	LDA FontLookup,X ;4
	STA ScoreD3 ;3
	JMP RightScoreWriteEnd

PrintHellwayRight
	LDA FrameCount1
	AND #1
	BNE PrintCreditsRight
	LDX #<HellwayRightText
	JMP PrintRightIntro
PrintCreditsRight
	LDX #<YearText
PrintRightIntro
	JSR PrintStaticText
	JMP RightScoreWriteEnd
PrintGameOver
	LDA FrameCount0
	BMI PrintOverText
	LDX #<GameText
	JMP StoreGameOverText
PrintOverText
	LDX #<OverText
StoreGameOverText
	JSR PrintStaticText
RightScoreWriteEnd


ScoreBackgroundColor
	LDX #0
	LDA SWCHB
	AND #%00001000 ; If Black and white, this will make A = 0
	BEQ BlackAndWhiteScoreBg
	LDA #SCORE_BACKGROUND_COLOR
	LDX #BACKGROUND_COLOR
BlackAndWhiteScoreBg
	STA Tmp2 ; Score Background
	STX Tmp3 ; Traffic Background

ConfigurePFForScore
	;LDA #SCORE_BACKGROUND_COLOR; Done above
	STA COLUBK
	JSR ClearAll
	LDA #%00000010 ; Score mode
	STA CTRLPF
	LDA TextSide ;3
	BNE RightScoreOn ; Half of the screen with the correct colors.
LeftScoreOn
	LDA ScoreFontColor
	STA COLUP1
	LDA Tmp2
	STA COLUP0
	LDA #1 ;Jumps faster in the draw loop
	STA Tmp1
	JMP CallWaitForVblankEnd
RightScoreOn
	LDA ScoreFontColor
	STA COLUP0
	LDA Tmp2
	STA COLUP1
	LDA #0 ;Jumps faster in the draw loop
	STA Tmp1

; After here we are going to update the screen, No more heavy code
CallWaitForVblankEnd
	JSR WaitForVblankEnd

DrawScoreHud
	JSR PrintScore

	STA WSYNC

	LDA INPT4 ;3
	BPL WaitAnotherScoreLine ; Draw traffic while button is pressed.
	LDA ScoreFontColor
	CMP #SCORE_FONT_COLOR_OVER
	BNE WaitAnotherScoreLine
	LDA TextSide ;3
	BNE LeftScoreOnGameOver
	JMP DrawGameOverScreenRight
LeftScoreOnGameOver
	JMP DrawGameOverScreenLeft

WaitAnotherScoreLine
	STA WSYNC

PrepareForTraffic
	JSR ClearPF ; 32

	STA WSYNC
	STA WSYNC

	LDA #%00110001 ; 2 Score mode
	STA CTRLPF ;3
	
	LDA TrafficColor ;3
	STA COLUPF ;3
	
	LDA #PLAYER1_COLOR ;2
	STA COLUP1 ;3

	LDA ScoreFontColor ;3
	STA COLUP0 ;3

	LDY #GAMEPLAY_AREA ;2; (Score)

	JSR ClearPF ; 32 Useless, but get to wait 32 cycles

	SLEEP 14
	
	LDA Tmp3 ;3
	STA COLUBK ;3
	JMP DrawCache ;3 Skips the first WSYNC, so the last background line can be draw to the end.
	;The first loop never drans a car, so it is fine this jump uses 3 cycles of the next line.

;main scanline loop...
ScanLoop 
	STA WSYNC ;?? from the end of the scan loop, sync the final line

;Start of next line!			
DrawCache ;63 Is the last line going to the top of the next frame?
	LDA PF0Cache ;3
	STA PF0	     ;3

	LDA PF1Cache ;3
	STA PF1	     ;3

	CPY #CAR_START_LINE ;2 ;Saves memory and still fast
	BCS SkipDrawCar;2
	LDA (CarSpritePointerL),Y ;5 ;Very fast, in the expense of rom space
	STA GRP0      ;3   ;put it as graphics now
SkipDrawCar
	
	LDA GRP1Cache ;3
	STA GRP1      ;3

	LDA ENABLCache ;3
	STA ENABL      ;3

	LDA ENAM0Cache ;3
	STA ENAM0    ;3

	LDA ENAM1Cache  ;3
	STA ENAM1 ;3

	LDA #0		 ;2
	;STA PF1Cache ;3
	STA GRP1Cache ;3
	STA ENABLCache ;3
	STA ENAM0Cache ;3
	STA ENAM1Cache; 3

	;BEQ DrawTraffic3
DrawTraffic1; 33
	TYA; 2
	CLC; 2 
	ADC TrafficOffset1 + 1;3
	AND #TRAFFIC_1_MASK ;2 ;#%11111000
	BCS EorOffsetWithCarry; 2(worse not to jump), 4 if branch
	EOR TrafficOffset1 + 2 ; 3
	JMP AfterEorOffsetWithCarry ; 3
EorOffsetWithCarry
	EOR TrafficOffset1 + 3 ; 3
AfterEorOffsetWithCarry ;17
	TAX ;2
	LDA AesTable,X ; 4
	CMP TrafficChance;3
	BCS FinishDrawTraffic1 ; 2
	LDA #$FF ;2
	STA GRP1Cache ;3
FinishDrawTraffic1

DrawTraffic2; 33
	TYA; 2
	CLC; 2 
	ADC TrafficOffset2 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry2; 4 max if branch max, 2 otherwise
	EOR TrafficOffset2 + 2 ; 3
	JMP AfterEorOffsetWithCarry2 ; 3
EorOffsetWithCarry2
	EOR TrafficOffset2 + 3 ; 3
AfterEorOffsetWithCarry2 ;17
	TAX ;2
	LDA AesTable,X ; 4
	CMP TrafficChance;3
	BCS FinishDrawTraffic2 ; 2
	LDA #%00000010 ;2
	STA ENABLCache;3
FinishDrawTraffic2	

	;STA WSYNC ;65 / 137

	; LDA Tmp0 ; Flicker this line if drawing car
	; BEQ FinishDrawTraffic4
DrawTraffic3; 33
	TYA; 2
	CLC; 2 
	ADC TrafficOffset3 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry3; 4 max if branch max, 2 otherwise
	EOR TrafficOffset3 + 2 ; 3
	JMP AfterEorOffsetWithCarry3 ; 3
EorOffsetWithCarry3
	EOR TrafficOffset3 + 3 ; 3
AfterEorOffsetWithCarry3 ;17
	TAX ;2
	LDA AesTable,X ; 4
	CMP TrafficChance;3
	BCS FinishDrawTraffic3 ; 2 
	LDA #%00000010 ;2
	STA ENAM0Cache
FinishDrawTraffic3	
	
DrawTraffic4; 33
	TYA; 2
	CLC; 2 
	ADC TrafficOffset4 + 1;3
	AND #TRAFFIC_1_MASK ;2
	BCS EorOffsetWithCarry4; 4 max if branch max, 2 otherwise
	EOR TrafficOffset4 + 2 ; 3
	JMP AfterEorOffsetWithCarry4 ; 3
EorOffsetWithCarry4
	EOR TrafficOffset4 + 3 ; 3
AfterEorOffsetWithCarry4 ;17
	TAX ;2
	LDA AesTable,X ; 4
	CMP TrafficChance;3
	BCS FinishDrawTraffic4 ; 2
	LDA #%00000010 ;2
	STA ENAM1Cache	;3
FinishDrawTraffic4

DrawTraffic0; 20
	TYA ;2
	AND #%00000111 ;2
	TAX ;2
	LDA ParallaxCache,X ;4
	STA PF1Cache ;3
	LDA ParallaxCache2,X ;4
	STA PF0Cache ;3

SkipDrawTraffic0

WhileScanLoop 
	DEY	;2
	BMI FinishScanLoop ;2 two big Breach, needs JMP
	JMP ScanLoop ;3
FinishScanLoop ; 7 209 of 222

	STA WSYNC ;3 Draw the last line, without wrapping
	JSR LoadAll
	STA WSYNC ; do stuff!
	STA WSYNC
	STA WSYNC
	;42 cycles to use here

PrepareOverscan
	LDA #2		
	STA WSYNC  	
	STA VBLANK 	
	
	LDA #6 ; 2 more lines before overscan (was 37)...
	STA TIM64T	

LeftSound ;41
	LDA CountdownTimer ;3
	BEQ EngineOff      ;2
	LDX Gear
	LDA Player0SpeedL ;3
	LSR ;2
	LSR ;2
	LSR ;2
	AND #%00001111 ;2
	STA Tmp0 ;3
	LDA EngineBaseFrequence,X ; 4 Max of 5 bits
	SEC ;2
	SBC Tmp0 ;3
	STA AUDF0 ;3
	LDA EngineSoundType,X ;4
	STA AUDC0 ;3
	JMP EndLeftSound ;3
EngineOff
	LDA #0
	STA AUDC0

EndLeftSound


RightSound ; 71 More speed = smaller frequency divider. Just getting speed used MSB. (0 to 23)
	LDA ScoreFontColor ;3
	CMP #SCORE_FONT_COLOR_OVER ;2
	BEQ MuteRightSound ;2 A little bit of silence, since you will be run over all the time
	CMP #SCORE_FONT_COLOR_GOOD ;2
	BEQ PlayCheckpoint ;2
	LDA CollisionCounter ;3
	CMP #$E0 ;2
	BCS PlayColision ;2
	LDA NextCheckpoint ;3
	SEC ;2
	SBC TrafficOffset0 + 2 ;3
	CMP #$02 ;2
	BCC PlayBeforeCheckpoint ;4
	LDA CountdownTimer ; 3
	BEQ MuteRightSound ;2
	CMP #WARN_TIME_ENDING ;2
	BCC PlayWarnTimeEnding ;4
	JMP MuteRightSound ;3
PlayColision
	LDA #31
	STA AUDF1
	LDA #8
	STA AUDC1
	LDA #8
	STA AUDV1
	JMP EndRightSound

PlayCheckpoint
	LDA ScoreFontColorHoldChange ;3
	LSR ;2
	LSR ;2
	LSR ;2
	STA AUDF1 ;3
	LDA #12 ;2
	STA AUDC1 ;3
	LDA #6 ;2
	STA AUDV1 ;3
	JMP EndRightSound ;3

PlayBeforeCheckpoint
	LDA FrameCount0 ;3
	AND #%00011100 ;2
	ORA #%00000011;2
	STA AUDF1 ;3
	LDA #12 ;2
	STA AUDC1 ;3
	LDA #3 ;2
	STA AUDV1 ;3
	JMP EndRightSound ;3

PlayWarnTimeEnding
	LDA FrameCount0 ;3
	AND #%00000100 ;2
	BEQ MuteRightSound ;2 Bip at regular intervals
	CLC ;2
	LDA #10 ;2
	ADC CountdownTimer ;2
	STA AUDF1 ;3
	LDA #12 ;2
	STA AUDC1 ;3
	LDA #3 ;2
	STA AUDV1 ;3
	JMP EndRightSound ;3
	
MuteRightSound
	LDA #0
	STA AUDV1
EndRightSound

;Read Fire Button before, will make it start the game for now.
StartGame
	LDA INPT4 ;3
	BMI SkipGameStart ;2 ;not pressed the fire button in negative in bit 7
	LDA GameStatus ;3
	ORA SwitchDebounceCounter ; Do not start during debounce
	BNE SkipGameStart
	LDA GameMode
	CMP #MAX_GAME_MODE
	BNE SetGameRunning
	LDA #0
	STA GameMode
	LDA #SWITCHES_DEBOUNCE_TIME
	STA SwitchDebounceCounter
	JMP SkipGameStart
SetGameRunning 
	INC GameStatus
	LDA #0;
	STA FrameCount0
	STA FrameCount1
	LDA #10
	STA AUDV0
	LDA #SCORE_FONT_COLOR_START
	STA ScoreFontColor
	LDA #SCORE_FONT_HOLD_CHANGE
	STA ScoreFontColorHoldChange
SkipGameStart

ReadSwitches
	LDX SwitchDebounceCounter
	BNE DecrementSwitchDebounceCounter
	LDA #%00000001
	BIT SWCHB
	BNE SkipReset 
	LDA #SWITCHES_DEBOUNCE_TIME
	STA SwitchDebounceCounter
	JMP OverScanWaitBeforeReset
SkipReset

GameModeSelect
	LDA GameStatus ;We don't read game select while running and save precious cycles
	BNE SkipGameSelect
	JSR ConfigureDifficulty ; Keeps randomizing dificulty for modes 8 to F, also resets it for other modes
ReadDpadParallax
	LDA SWCHA
	AND #%11110000
	CMP #%11110000 ; 1 means it is not on that direction 
	BEQ ContinueGameSelect ; We do not change parallax while gamepad is centered!
	STA ParallaxMode
ContinueGameSelect
	LDA #%00000010
	BIT SWCHB
	BNE SkipGameSelect
	LDX GameMode
	CPX #MAX_GAME_MODE
	BEQ ResetGameMode
	INX
	JMP StoreGameMode
ResetGameMode
	LDX #0
StoreGameMode
	STX GameMode
	LDA #SWITCHES_DEBOUNCE_TIME
	STA SwitchDebounceCounter
SkipGameSelect
	JMP EndReadSwitches
DecrementSwitchDebounceCounter
	DEC SwitchDebounceCounter
EndReadSwitches

OverScanWait
	LDA INTIM	
	BNE OverScanWait ;Is there a better way?	
	JMP MainLoop      

OverScanWaitBeforeReset
	LDA INTIM	
	BNE OverScanWaitBeforeReset ;Is there a better way?	
	JMP Start   

Subroutines

ClearAll ; 52
	LDA #0  	  ;2
	STA GRP1      ;3
	STA ENABL     ;3
	STA ENAM0     ;3
	STA ENAM1     ;3
	STA GRP1Cache ;3
	STA ENABLCache ;3
	STA ENAM0Cache ;3
	STA ENAM1Cache ;3

ClearPF ; 26
	LDA #0  	  ;2
ClearPFSkipLDA0
	STA PF0		  ;3
	STA PF1	      ;3
	STA PF2       ;3 	
	STA PF0Cache   ;3
	STA PF1Cache   ;3
	STA PF2Cache   ;3 
	RTS ;6
EndClearAll

LoadAll ; 48
	LDA PF0Cache  ;3
	STA PF0		  ;3
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2      ;3

	LDA GRP1Cache ;3
	STA GRP1      ;3

	LDA ENABLCache ;3
	STA ENABL      ;3

	LDA ENAM0Cache ;3
	STA ENAM0      ;3

	LDA ENAM1Cache ;3
	STA ENAM1      ;3

	RTS ;6
EndLoadAll

NextDifficulty 
	LDA GameMode ; For now, even games change the difficult
	AND #%00000001
	BNE CheckRandomDifficulty

	LDA CurrentDifficulty
	CLC
	ADC #1
	AND #%00000011 ; 0 to 3
	STA CurrentDifficulty

ConfigureDifficulty
	LDY CurrentDifficulty ;Needed, not always NextDifficulty is entrypoint
	LDA TrafficChanceTable,Y
	STA TrafficChance
	LDA TrafficColorTable,Y
	STA TrafficColor

	LDA GameMode;
	AND #%00000001
	BEQ UseNextDifficultyTime
	JMP StoreDifficultyTime
UseNextDifficultyTime
	INY
StoreDifficultyTime
	LDA TrafficTimeTable,Y
	STA CheckpointTime

CheckRandomDifficulty
	LDA GameMode
	AND #%00001000 ; Random difficulties
	BEQ ReturnFromNextDifficulty
RandomDifficulty
	LDX FrameCount0
	LDA AesTable,X
	;EOR TrafficChance, no need, lets make life simple
	AND #%00111111
	STA TrafficChance
	
ReturnFromNextDifficulty
	RTS
EndNextDifficulty

DefaultOffsets
	LDA #$20
	STA TrafficOffset1 + 2
	LDA #$40
	STA TrafficOffset2 + 2	;Initial Y Position
	LDA #$60
	STA TrafficOffset3 + 2	;Initial Y Position
	LDA #$80
	STA TrafficOffset4 + 2	;Initial Y Position
	LDA #$A0
	RTS

PrintStaticText ; Preload X with the offset referent to StaticText
	LDA StaticText,X
	STA ScoreD0
	INX
	LDA StaticText,X
	STA ScoreD1
	INX
	LDA StaticText,X
	STA ScoreD2
	INX
	LDA StaticText,X
	STA ScoreD3
	INX
	LDA StaticText,X
	STA ScoreD4
	RTS

HorizontalParallaxLoop
	LDA #%11101111 ; Clear the house
	AND ParallaxCache,Y	
	STA ParallaxCache,Y	
CalculateParallax0
	TYA
	CLC
	ADC TrafficOffset0 + 1
	AND #%00000100
	BEQ HasEmptySpace0
HasBorder0
	LDA ParallaxCache,Y
	ORA #%00001111
	JMP StoreParallax0
HasEmptySpace0
	LDA ParallaxCache,Y
	AND #%11110000

StoreParallax0
	STA ParallaxCache,Y

CalculateParallax1
	TYA
	CLC
	ADC ParallaxOffset1 + 1
	AND #%00000100
	BEQ HasEmptySpace1
HasBorder1
	LDA ParallaxCache,Y
	ORA #%11100000
	JMP StoreParallax1
HasEmptySpace1
	LDA ParallaxCache,Y
	AND #%00011111

StoreParallax1
	STA ParallaxCache,Y

CalculateParallax2
	TYA
	CLC
	ADC ParallaxOffset2 + 1
	AND #%00000100
	BEQ HasEmptySpace2
HasBorder2
	LDA #%01100000 
	JMP StoreParallax2
HasEmptySpace2
	LDA #0

StoreParallax2
	STA ParallaxCache2,Y

ContinueHorizontalParallaxLoop
	DEY
	BPL HorizontalParallaxLoop
	RTS

DefaultBorderLoop
CalculateDefaultBorder
	TYA
	CLC
	ADC TrafficOffset0 + 1
	AND #%00000100
	BEQ HasEmptySpace
HasBorder
	LDA #$FF
	JMP StoreBorder
HasEmptySpace
	LDA #0

StoreBorder
	STA ParallaxCache,Y	
	LDA #0
	STA ParallaxCache2,Y ; Clear other modes

ContinueDefaultBorderLoop
	DEY
	BPL DefaultBorderLoop
	RTS

PrepareTachometerBorderLoop
	LDA Player0SpeedL
	LSR
	LSR
	LSR
	LSR
	AND #%00000111
	STA Tmp1 ; RPM
	LDX CurrentCarId ; Y cannot be destroyed here
	LDA CarIdToMaxGear,X
	STA Tmp2 ; Max Gear

TachometerBorderLoop
	TYA
	CLC
	ADC TrafficOffset0 + 1
	AND #%00000100
	BEQ HasBorderTac
	LDX Gear
	LDA TachometerGearLookup,X
	STA ParallaxCache,Y
	LDA #0
	STA ParallaxCache2,Y
	JMP ContinueBorderTac
HasBorderTac
	LDA Tmp2 ; Max Gear
	CMP Gear ; Only on max speed
	BEQ FullBorderTac
	LDX Tmp1
	LDA TachometerSizeLookup1,X
	STA ParallaxCache,Y
	LDA TachometerSizeLookup2,X
	STA ParallaxCache2,Y
	JMP ContinueBorderTac

FullBorderTac
	LDA #$FF
	STA ParallaxCache,Y
	STA ParallaxCache2,Y
	JMP ContinueBorderTac

ContinueBorderTac
	DEY
	BPL TachometerBorderLoop
	RTS

VerticalParallaxLoop
CalculateVerticalParallax0
	TYA
	CLC
	ADC TrafficOffset0 + 1
	AND #%00000110
	BNE HasNoVerticalLine0
HasVerticalLine0
	LDA #$FF
	STA ParallaxCache,Y
	STA ParallaxCache2,Y
	JMP ContinueVerticalParallaxLoop ; Biggest line possible
HasNoVerticalLine0
	LDA #0
	STA ParallaxCache,Y
	STA ParallaxCache2,Y

CalculateVerticalParallax1
	TYA
	CLC
	ADC ParallaxOffset1 + 1
	AND #%00000111
	BNE HasNoVerticalLine1

HasVerticalLine1
	LDA #%11111100
	STA ParallaxCache,Y
	LDA #%11000000
	STA ParallaxCache2,Y
	JMP ContinueVerticalParallaxLoop
HasNoVerticalLine1
	LDA #0
	STA ParallaxCache,Y
	STA ParallaxCache2,Y

CalculateVerticalParallax2
	TYA
	CLC
	ADC ParallaxOffset2 + 1
	AND #%00000111
	BNE HasNoVerticalLine2

HasVerticalLine2
	LDA #%11110000
	STA ParallaxCache,Y
	JMP ContinueVerticalParallaxLoop
HasNoVerticalLine2
	LDA #0
	STA ParallaxCache,Y
	STA ParallaxCache2,Y

ContinueVerticalParallaxLoop
	DEY
	BPL VerticalParallaxLoop
	RTS

PrintEasterEgg ; Not very optimized, but I have cycles to spare.
	LDA #SCORE_FONT_COLOR_EASTER_EGG
	STA ScoreFontColor
	LDA #1
	STA ScoreFontColorHoldChange

	LDA FrameCount1
	AND #%00000111
	STA Tmp3
	;0 is Zelda Name, (default)
	LDA #1
	CMP Tmp3
	BEQ PrintZeldaDateLeft

	LDA #2
	CMP Tmp3
	BEQ PrintPolvinhosLeft

	LDA #3
	CMP Tmp3
	BEQ PrintPolvinhosDateLeft

	LDA #4
	CMP Tmp3
	BEQ PrintIvonneLeft

	LDA #5
	CMP Tmp3
	BEQ PrintIvonneDateLeft

	LDA #6
	CMP Tmp3
	BEQ PrintArtLeft

	LDA #7
	CMP Tmp3
	BEQ PrintLeonardoLeft
	
PrintZeldaLeft
	LDX #<ZeldaTextLeft
	JMP ProcessPrintEasterEgg
PrintPolvinhosLeft
	LDX #<PolvinhosTextLeft
	JMP ProcessPrintEasterEgg
PrintIvonneLeft
	LDX #<IvonneTextLeft
	JMP ProcessPrintEasterEgg
PrintArtLeft
	LDX #<PaperArtTextLeft
	JMP ProcessPrintEasterEgg

PrintZeldaDateLeft
	LDX #<ZeldaDateLeft
	JMP ProcessPrintEasterEgg
PrintPolvinhosDateLeft
	LDX #<PolvinhosDateLeft
	JMP ProcessPrintEasterEgg
PrintIvonneDateLeft
	LDX #<IvonneDateLeft
	JMP ProcessPrintEasterEgg
PrintLeonardoLeft
	LDX #<LeonardoTextLeft
	JMP ProcessPrintEasterEgg

ProcessPrintEasterEgg
	LDA FrameCount0 ;3
	AND #%00000001 ;2
	BNE TranformIntoRightText
	JMP PrintEasterEggText
TranformIntoRightText ; Just adds 5 to X, texts are properly aligned
	TXA
	CLC
	ADC #HALF_TEXT_SIZE
	TAX

PrintEasterEggText
	JSR PrintStaticText
	RTS

PrintScore ; Runs in 2 lines, this is the best I can do!
	LDX #0
	LDY #FONT_OFFSET

ScoreLoop ; 20 
	STA WSYNC ;2

	LDA PF0Cache  ;3 Move to a macro?
	STA PF0		  ;3
	
	LDA PF1Cache ;3
	STA PF1	     ;3
	
	LDA PF2Cache ;3
	STA PF2 ;3

DrawScoreD0 ; 15
	LDX ScoreD0 ; 3
	LDA Font,X	;4
	STA PF0Cache ;3
	DEC ScoreD0 ;5

DrawScoreD1 ; 23	
	LDX ScoreD1 ; 3
	LDA Font,X	;4
	ASL ;2
	ASL ;2
	ASL ;2
	ASL ;2
	STA PF1Cache ;3
	DEC ScoreD1 ;5

DrawScoreD2 ; 20
	LDX ScoreD2 ; 3
	LDA Font,X	;4
	AND #%00001111 ;2
	ORA PF1Cache ;3
	STA PF1Cache ;3
	DEC ScoreD2 ;5

DrawScoreD3 ; 23
	LDX ScoreD3 ; 3
	LDA Font,X	;4
	LSR ;2
	LSR ;2
	LSR ;2
	LSR ;2
	STA PF2Cache ;3
	DEC ScoreD3 ;5

DrawScoreD4 ; 20
	LDX ScoreD4 ; 3
	LDA Font,X	;4
	AND #%11110000 ;2
	ORA PF2Cache ;3
	STA PF2Cache ;3
	DEC ScoreD4 ;5


	DEY ;2
	BPL ScoreLoop ;4

	STA WSYNC
	JSR LoadAll
	RTS ; 6

PrintRightDecimalDigits
	LDA 0,Y
	LSR
	LSR
	LSR
	LSR
	TAX
	LDA FontLookup,X ;4
	STA ScoreD2 ;3

	LDA 0,Y
	AND #%00001111
	TAX 
	LDA FontLookup,X ;4
	STA ScoreD3 ;3

	INY
	LDA 0,Y
	LSR
	LSR
	LSR
	LSR
	TAX
	LDA FontLookup,X ;4
	STA ScoreD0 ;3

	LDA 0,Y
	AND #%00001111
	TAX 
	LDA FontLookup,X ;4
	STA ScoreD1 ;3

	LDA #<Triangle + FONT_OFFSET
	STA ScoreD4
	RTS

PrintLastLeftDecimalDigits
	LDA 0,Y
	LSR
	LSR
	LSR
	LSR
	TAX
	LDA FontLookup,X ;4
	STA ScoreD3 ;3
	LDA 0,Y
	AND #%00001111
	TAX 
	LDA FontLookup,X ;4
	STA ScoreD4 ;3
	RTS

PrintZerosLeft
	LDA #<C0 + FONT_OFFSET
	STA ScoreD2
	STA ScoreD3
	STA ScoreD4
	RTS

DrawGameOverScoreLine
	STA WSYNC
	JSR PrintScore
	STA WSYNC
	STA WSYNC
	JSR ClearPF
	RTS

DrawGameOverScreenLeft
	STA WSYNC
	JSR ClearPF

DrawBcdScoreLeft
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR
	STA COLUP0
	STA WSYNC
	LDA #<CS + #FONT_OFFSET
	STA ScoreD0

	LDA #<Colon + #FONT_OFFSET
	STA ScoreD1

	LDA ScoreBcd3
	AND #%00001111
	TAX
	LDA FontLookup,X ;4
	STA ScoreD2 ;3

	LDY #ScoreBcd2
	JSR PrintLastLeftDecimalDigits
	
	JSR DrawGameOverScoreLine

DrawTimerLeft
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR_EASTER_EGG
	STA COLUP0
	LDA #<CT + #FONT_OFFSET
	STA ScoreD0
	LDA #<Colon + #FONT_OFFSET
	STA ScoreD1
	LDA #<C0 + #FONT_OFFSET
	STA ScoreD2
	LDY #TimeBcd2
	STA WSYNC
	JSR PrintLastLeftDecimalDigits
	JSR DrawGameOverScoreLine

DrawGlideTimerLeft
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR_BAD
	STA COLUP0
	STA WSYNC
	LDA #<CG + #FONT_OFFSET
	STA ScoreD0
	LDA #<Colon + #FONT_OFFSET
	STA ScoreD1
	JSR PrintZerosLeft
	JSR DrawGameOverScoreLine

DrawHitCountLeft
	JSR Sleep8Lines
	LDA #TRAFFIC_COLOR_INTENSE
	STA COLUP0
	STA WSYNC
	LDA #<CH + #FONT_OFFSET
	STA ScoreD0
	LDA #<Colon + #FONT_OFFSET
	STA ScoreD1
	JSR PrintZerosLeft
	JSR DrawGameOverScoreLine

DrawCheckpointCountLeft
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR_GOOD
	STA COLUP0
	STA WSYNC
	LDA #<CC + #FONT_OFFSET
	STA ScoreD0
	LDA #<Colon + #FONT_OFFSET
	STA ScoreD1
	JSR PrintZerosLeft
	JSR DrawGameOverScoreLine

DrawGameVersionLeft
	JSR Sleep8Lines
	LDA #VERSION_COLOR
	STA COLUP0

	LDA GameMode
	TAX
	LDA FontLookup,X ;4
	STA ScoreD0 ;3

	LDA CurrentCarId
	TAX
	LDA FontLookup,X ;4
	STA ScoreD1 ;3

	LDA StartSWCHB
	AND #%01000000 ; P0 difficulty
	EOR #%01000000 ; Reverse bytes
	ROL
	ROL
	ROL 
	CLC
	ADC #10
	TAX
	LDA FontLookup,X ;4
	STA ScoreD2 ;3

	LDA StartSWCHB
	AND #%10000000 ; P0 difficulty
	EOR #%10000000 ; Reverse bytes
	ROL
	ROL
	CLC
	ADC #10
	TAX
	LDA FontLookup,X ;4
	STA ScoreD3 ;3

	LDA #<Pipe + FONT_OFFSET
	STA ScoreD4

	JSR DrawGameOverScoreLine
	
	JMP FinalizeDrawGameOver

DrawGameOverScreenRight
	STA WSYNC
	JSR ClearPF
	
DrawBcdScoreRight	
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR
	STA COLUP1
	STA WSYNC
	LDY #ScoreBcd0
	JSR PrintRightDecimalDigits

	JSR DrawGameOverScoreLine

DrawTimerRight
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR_EASTER_EGG
	STA COLUP1
	LDY #TimeBcd0
	JSR PrintRightDecimalDigits

	JSR DrawGameOverScoreLine
DrawGlideTimeRight
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR_BAD
	STA COLUP1
	LDY #GlideTimeBcd0
	JSR PrintRightDecimalDigits
	JSR DrawGameOverScoreLine

DrawHitCountRight
	JSR Sleep8Lines
	LDA #TRAFFIC_COLOR_INTENSE
	STA COLUP1
	LDY #HitCountBcd0
	JSR PrintRightDecimalDigits
	JSR DrawGameOverScoreLine

DrawCheckpointCountRight
	JSR Sleep8Lines
	LDA #SCORE_FONT_COLOR_GOOD
	STA COLUP1
	LDY #CheckpointBcd0
	JSR PrintRightDecimalDigits
	JSR DrawGameOverScoreLine

DrawVersionRight
	JSR Sleep8Lines
	LDA #VERSION_COLOR
	STA COLUP1
	STA WSYNC
	LDX #<VersionText
	JSR PrintStaticText
	JSR DrawGameOverScoreLine

FinalizeDrawGameOver
	LDA #SCORE_FONT_COLOR_OVER ;Restores the game state
	STA ScoreFontColor
	JSR Sleep4Lines
	JSR Sleep32Lines
	JSR Sleep32Lines
	JMP PrepareOverscan

WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd	
	STA WSYNC
	STA VBLANK
	RTS	

Sleep4Lines
	STA WSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	RTS

Sleep8Lines
	JSR Sleep4Lines
	JSR Sleep4Lines
	RTS

Sleep32Lines
	JSR Sleep8Lines
	JSR Sleep8Lines
	JSR Sleep8Lines
	JSR Sleep8Lines
	RTS

;ALL CONSTANTS FROM HERE (The QrCode routine is the only exception), ALIGN TO AVOID CARRY
	org $FC00
QrCode1
	.byte #%00011111
	.byte #%00010000
	.byte #%00010111
	.byte #%00010111
	.byte #%00010111
	.byte #%00010000
	.byte #%00011111
	.byte #%00000000
	.byte #%00010111
	.byte #%00010000
	.byte #%00011101
	.byte #%00010110
	.byte #%00000011
	.byte #%00011001
	.byte #%00010011
	.byte #%00011100
	.byte #%00001011
	.byte #%00000000
	.byte #%00011111
	.byte #%00010000
	.byte #%00010111
	.byte #%00010111
	.byte #%00010111
	.byte #%00010000
	.byte #%00011111

QrCode2
	.byte #%11000011
	.byte #%10011010
	.byte #%10000010
	.byte #%11011010
	.byte #%10101010
	.byte #%11001010
	.byte #%11110011
	.byte #%01111000
	.byte #%11011111
	.byte #%11111100
	.byte #%11000111
	.byte #%10011000
	.byte #%00100011
	.byte #%10111001
	.byte #%11010010
	.byte #%00110000
	.byte #%11101011
	.byte #%00101000
	.byte #%10101011
	.byte #%01110010
	.byte #%11111010
	.byte #%01111010
	.byte #%00110010
	.byte #%00111010
	.byte #%01100011	

QrCode3
	.byte #%10011000
	.byte #%11000011
	.byte #%00111001
	.byte #%00110100
	.byte #%11111111
	.byte #%01110001
	.byte #%11010101
	.byte #%11010001
	.byte #%01011111
	.byte #%00100110
	.byte #%00101101
	.byte #%11101001
	.byte #%11010110
	.byte #%00100110
	.byte #%10111010
	.byte #%00000011
	.byte #%11011101
	.byte #%11100000
	.byte #%01010111
	.byte #%00010100
	.byte #%00110101
	.byte #%11100101
	.byte #%10110101
	.byte #%11010100
	.byte #%10010111

QrCode4
	.byte #%00001001
	.byte #%00001110
	.byte #%00001111
	.byte #%00001100
	.byte #%00001100
	.byte #%00001000
	.byte #%00001000
	.byte #%00000110
	.byte #%00000110
	.byte #%00001011
	.byte #%00001111
	.byte #%00000100
	.byte #%00001000
	.byte #%00001111
	.byte #%00001001
	.byte #%00000111
	.byte #%00000101
	.byte #%00000000
	.byte #%00001111
	.byte #%00001000
	.byte #%00001011
	.byte #%00001011
	.byte #%00001011
	.byte #%00001000
	.byte #%00001111

; Moved here because of rom space.
; The only SBR in constants space
DrawQrCode
	LDX #QR_CODE_BACKGROUNG ;2
	LDY #QR_CODE_COLOR ;2
	LDA #%00000001 ; Mirror playfield
	STA CTRLPF
	JSR ClearAll ; To be 100 sure!
	LDA SWCHB
	AND #%00001000 ; If Black and white, this will make A = 0
	BEQ StoreReversedQrCode
	STX COLUBK
	STY COLUPF
	JMP ContinueQrCode
StoreReversedQrCode
	STX COLUPF
	STY COLUBK

ContinueQrCode
	LDY #QR_CODE_SIZE - 1
	LDX #QR_CODE_LINE_HEIGHT
	JSR WaitForVblankEnd
	JSR Sleep8Lines
	JSR Sleep8Lines
	JSR Sleep8Lines

QrCodeLoop ;Assync mirroed playfield, https://atariage.com/forums/topic/149228-a-simple-display-timing-diagram/
	STA WSYNC
	LDA QrCode1,Y ; 4
	STA PF1  ;3
	LDA QrCode2,Y ;4
	STA PF2 ;3
	SLEEP 27 ; 
	LDA QrCode3,Y ;4
	STA PF2 ;3 Write ends at cycle 48 exactly!
	LDA QrCode4,Y ; 4
	STA PF1  ;3

	DEX ;2
	BNE QrCodeLoop ;2
	LDX #QR_CODE_LINE_HEIGHT ;2
	DEY ;2
	BPL QrCodeLoop ;4

EndQrCodeLoop
	STA WSYNC ;
	LDA #0
	STA PF1  ;3
	STA PF2  ;3

	JSR Sleep32Lines
	JMP PrepareOverscan
    
	org $FD00
Font	
C0
	.byte #%11100111;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%11100111;	
C1	
	.byte #%11100111;
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01100110;
C2
	.byte #%11100111;
	.byte #%00100100; 
	.byte #%11100111; 
	.byte #%10000001; 
	.byte #%11100111;
C3
	.byte #%11100111;
	.byte #%10000001; 
	.byte #%11100111; 
	.byte #%10000001; 
	.byte #%11100111;
C4
	.byte #%10000001;
	.byte #%10000001; 
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%10100101;
C5
	.byte #%11100111;
	.byte #%10000001; 
	.byte #%11100111; 
	.byte #%00100100; 
	.byte #%11100111;
C6
	.byte #%11100111;
	.byte #%10100101; 
	.byte #%11100111; 
	.byte #%00100100; 
	.byte #%11100111;
C7
	.byte #%10000001;
	.byte #%10000001; 
	.byte #%10000001; 
	.byte #%10000001; 
	.byte #%11100111;
C8
	.byte #%11100111;
	.byte #%10100101; 
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%11100111;
C9
	.byte #%11100111;
	.byte #%10000001; 
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%11100111;
CA
	.byte #%10100101;
	.byte #%10100101; 
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%11100111;
CB
	.byte #%01100110;
	.byte #%10100101; 
	.byte #%01100110; 
	.byte #%10100101;
	.byte #%01100110;
CC
	.byte #%11100111;
	.byte #%00100100; 
	.byte #%00100100; 
	.byte #%00100100;
	.byte #%11100111;

CD
	.byte #%01100110;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101;
	.byte #%01100110;

CE
	.byte #%11100111;
	.byte #%00100100; 
	.byte #%11100111; 
	.byte #%00100100; 
	.byte #%11100111;

CF
	.byte #%00100100;
	.byte #%00100100; 
	.byte #%11100111; 
	.byte #%00100100; 
	.byte #%11100111;

CG
	.byte #%11000011;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%00100100; 
	.byte #%11000011;	

CH
	.byte #%10100101;
	.byte #%10100101; 
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%10100101;

CK
	.byte #%10100101;
	.byte #%10100101; 
	.byte #%01100110; 
	.byte #%10100101; 
	.byte #%10100101;

CL
	.byte #%11100111;
	.byte #%00100100; 
	.byte #%00100100; 
	.byte #%00100100; 
	.byte #%00100100;

CI
	.byte #%01000010;
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01000010;

CM
	.byte #%10100101;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%11100111; 
	.byte #%10100101;

CN
	.byte #%10100101;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%01100110;	


CO
	.byte #%01000010;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%01000010;	

CP
	.byte #%00100100;
	.byte #%00100100; 
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%11100111;

CR
	.byte #%10100101;
	.byte #%10100101; 
	.byte #%01100110; 
	.byte #%10100101; 
	.byte #%01100110;

CS
	.byte #%01100110;
	.byte #%10000001; 
	.byte #%01000010; 
	.byte #%00100100; 
	.byte #%11000011;

CT 
	.byte #%01000010;
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%11100111;

CV 
	.byte #%01000010;
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101;	

CY
	.byte #%01000010;
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%10100101; 
	.byte #%10100101;

CW 
	.byte #%10100101;
	.byte #%11100111; 
	.byte #%10100101; 
	.byte #%10100101; 
	.byte #%10100101;

CZ 
	.byte #%11100111;
	.byte #%00100100; 
	.byte #%01000010; 
	.byte #%10000001; 
	.byte #%11100111;

Pipe
	.byte #%01000010;
	.byte #%00000000; 
	.byte #%01000010; 
	.byte #%00000000; 
	.byte #%01000010;

Exclamation
	.byte #%01000010;
	.byte #%00000000; 
	.byte #%01000010; 
	.byte #%01000010; 
	.byte #%01000010;

Dot
	.byte #%01000010;
	.byte #%01000010; 
	.byte #%00000000; 
	.byte #%00000000; 
	.byte #%00000000;

Colon
	.byte #%01000010;
	.byte #%01000010; 
	.byte #%00000000; 
	.byte #%01000010; 
	.byte #%01000010;

Triangle
	.byte #%10000001;
	.byte #%11000011; 
	.byte #%11100111; 
	.byte #%11000011; 
	.byte #%10000001;

Space ; Moved from the beggining so 0 to F is fast to draw.
	.byte #0;
	.byte #0;
	.byte #0;
	.byte #0;
	.byte #0;

FontLookup ; Very fast font lookup for dynamic values!
	.byte #<C0 + #FONT_OFFSET
	.byte #<C1 + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET
	.byte #<C3 + #FONT_OFFSET
	.byte #<C4 + #FONT_OFFSET
	.byte #<C5 + #FONT_OFFSET 
	.byte #<C6 + #FONT_OFFSET
	.byte #<C7 + #FONT_OFFSET
	.byte #<C8 + #FONT_OFFSET 
	.byte #<C9 + #FONT_OFFSET
	.byte #<CA + #FONT_OFFSET 
	.byte #<CB + #FONT_OFFSET 
	.byte #<CC + #FONT_OFFSET
	.byte #<CD + #FONT_OFFSET
	.byte #<CE + #FONT_OFFSET
	.byte #<CF + #FONT_OFFSET
	.byte #<CG + #FONT_OFFSET

EngineSoundType
	.byte #2
	.byte #2
	.byte #14
	.byte #6
	.byte #6
	.byte #14

EngineBaseFrequence
	.byte #31
	.byte #21
	.byte #20
	.byte #31
	.byte #22
	.byte #3

TachometerSizeLookup1
	.byte #%00011111
	.byte #%00111111
	.byte #%01111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111

TachometerSizeLookup2
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%10000000
	.byte #%11000000
	.byte #%11100000
	.byte #%11110000

TachometerGearLookup
	.byte #%00000001
	.byte #%00000010
	.byte #%00000100
	.byte #%00001000
	.byte #%00010000
	.byte #%00110000

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

StaticText ; All static text must be on the same MSB block. 
CheckpointText; Only the LSB, which is the offset.
	.byte #<CC + #FONT_OFFSET
	.byte #<CK + #FONT_OFFSET
	.byte #<CP + #FONT_OFFSET 
	.byte #<CT + #FONT_OFFSET
	.byte #<Exclamation + #FONT_OFFSET

HellwayLeftText
	.byte #<Space + #FONT_OFFSET
	.byte #<Pipe + #FONT_OFFSET
	.byte #<CH + #FONT_OFFSET 
	.byte #<CE + #FONT_OFFSET
	.byte #<CL + #FONT_OFFSET

HellwayRightText
	.byte #<CL + #FONT_OFFSET
	.byte #<CW + #FONT_OFFSET
	.byte #<CA + #FONT_OFFSET
	.byte #<CY + #FONT_OFFSET 
	.byte #<Exclamation + #FONT_OFFSET

OpbText
	.byte #<Space + #FONT_OFFSET
	.byte #<Pipe + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<CP + #FONT_OFFSET 
	.byte #<CB + #FONT_OFFSET 

YearText
	.byte #<Space + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET
	.byte #<C0 + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET 
	.byte #<C1 + #FONT_OFFSET
 
GameText
	.byte #<CG + #FONT_OFFSET
	.byte #<CA + #FONT_OFFSET
	.byte #<CM + #FONT_OFFSET
	.byte #<CE + #FONT_OFFSET 
	.byte #<Space + #FONT_OFFSET

OverText
	.byte #<CO + #FONT_OFFSET
	.byte #<CV + #FONT_OFFSET
	.byte #<CE + #FONT_OFFSET
	.byte #<CR + #FONT_OFFSET 
	.byte #<Space + #FONT_OFFSET
GoText
	.byte #<CG + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<Exclamation + #FONT_OFFSET
	.byte #<Exclamation + #FONT_OFFSET 
	.byte #<Exclamation + #FONT_OFFSET

ZeldaTextLeft
	.byte #<CZ + #FONT_OFFSET
	.byte #<CE + #FONT_OFFSET
	.byte #<CL + #FONT_OFFSET
	.byte #<CD + #FONT_OFFSET 
	.byte #<CA + #FONT_OFFSET

ZeldaTextRight
	.byte #<Space + #FONT_OFFSET
	.byte #<CM + #FONT_OFFSET
	.byte #<Dot + #FONT_OFFSET
	.byte #<CB + #FONT_OFFSET 
	.byte #<Dot + #FONT_OFFSET

ZeldaDateLeft
	.byte #<C2 + #FONT_OFFSET
	.byte #<C9 + #FONT_OFFSET
	.byte #<Dot + #FONT_OFFSET
	.byte #<C0 + #FONT_OFFSET 
	.byte #<C6 + #FONT_OFFSET

ZeldaDateRight
	.byte #<Dot + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET
	.byte #<C0 + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET 
	.byte #<C0 + #FONT_OFFSET

PolvinhosTextLeft
	.byte #<CP + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<CL + #FONT_OFFSET
	.byte #<CV + #FONT_OFFSET 
	.byte #<CI + #FONT_OFFSET

PolvinhosTextRight
	.byte #<CN + #FONT_OFFSET
	.byte #<CH + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<CS + #FONT_OFFSET 
	.byte #<Space + #FONT_OFFSET

PolvinhosDateLeft
	.byte #<C2 + #FONT_OFFSET
	.byte #<C7 + #FONT_OFFSET
	.byte #<Dot + #FONT_OFFSET
	.byte #<C0 + #FONT_OFFSET 
	.byte #<C9 + #FONT_OFFSET

PolvinhosDateRight
	.byte #<Dot + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET
	.byte #<C0 + #FONT_OFFSET
	.byte #<C1 + #FONT_OFFSET 
	.byte #<C4 + #FONT_OFFSET

IvonneTextLeft
	.byte #<CV + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<CA + #FONT_OFFSET
	.byte #<Space + #FONT_OFFSET 
	.byte #<CI + #FONT_OFFSET

IvonneTextRight
	.byte #<CV + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<CN + #FONT_OFFSET
	.byte #<CN + #FONT_OFFSET 
	.byte #<CE + #FONT_OFFSET

IvonneDateLeft
	.byte #<C1 + #FONT_OFFSET
	.byte #<C4 + #FONT_OFFSET
	.byte #<Dot + #FONT_OFFSET
	.byte #<C0 + #FONT_OFFSET 
	.byte #<C2 + #FONT_OFFSET

IvonneDateRight
	.byte #<Dot + #FONT_OFFSET
	.byte #<C1 + #FONT_OFFSET
	.byte #<C9 + #FONT_OFFSET
	.byte #<C2 + #FONT_OFFSET 
	.byte #<C8 + #FONT_OFFSET

PaperArtTextLeft
	.byte #<CP + #FONT_OFFSET
	.byte #<CA + #FONT_OFFSET
	.byte #<CP + #FONT_OFFSET
	.byte #<CE + #FONT_OFFSET 
	.byte #<CR + #FONT_OFFSET

PaperArtTextRight
	.byte #<Space + #FONT_OFFSET
	.byte #<CA + #FONT_OFFSET
	.byte #<CR + #FONT_OFFSET
	.byte #<CT + #FONT_OFFSET 
	.byte #<Space + #FONT_OFFSET

LeonardoTextLeft
	.byte #<CL + #FONT_OFFSET
	.byte #<CE + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<CN + #FONT_OFFSET 
	.byte #<CA + #FONT_OFFSET

LeonardoTextRight
	.byte #<CR + #FONT_OFFSET
	.byte #<CD + #FONT_OFFSET
	.byte #<CO + #FONT_OFFSET
	.byte #<Space + #FONT_OFFSET 
	.byte #<CN + #FONT_OFFSET

VersionText
	.byte #<C1 + #FONT_OFFSET
	.byte #<Dot + #FONT_OFFSET
	.byte #<C4 + #FONT_OFFSET
	.byte #<C3 + #FONT_OFFSET 
	.byte #<Triangle + #FONT_OFFSET


EndStaticText

CarSprite0 ; Upside down, Original Car
	ds 7
	.byte #%01111110
	.byte #%00100100
	.byte #%10111101
	.byte #%00111100
	.byte #%10111101
	.byte #%00111100

CarSprite1 ; Car variant posted by KevinMos3 (AtariAge), thanks!
	ds 7
	.byte #%10111101
	.byte #%01111110
	.byte #%01011010
	.byte #%01100110
	.byte #%10111101
	.byte #%00111100

CarSprite2 ; Car variant posted by TIX (AtariAge), his normal car, thanks!
	ds 7
	.byte #%01111110
	.byte #%10100101
	.byte #%01000010
	.byte #%01000010
	.byte #%10111101
	.byte #%01111110

CarSprite3 ; Car variant posted by TIX (AtariAge), dragster, thanks!
	ds 7
	.byte #%00111100
	.byte #%11011011
	.byte #%11011011
	.byte #%00111100
	.byte #%01011010
	.byte #%00111100

TrafficSpeeds
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
TrafficSpeedsHighDelta
	.byte #$00;  Trafic0 L
	.byte #$00;  Trafic0 H
	.byte #$0A;  Trafic1 L
	.byte #$01;  Trafic1 H
	.byte #$C8;  Trafic2 L
	.byte #$00;  Trafic2 H
	.byte #$86;  Trafic3 L
	.byte #$00;  Trafic3 H
	.byte #$44;  Trafic4 L
	.byte #$00;  Trafic4 H

CarIdToSpriteAddressL
	.byte #<CarSprite0
	.byte #<CarSprite1
	.byte #<CarSprite2
	.byte #<CarSprite3

CarIdToSpriteAddressH
	.byte #>CarSprite0
	.byte #>CarSprite1
	.byte #>CarSprite2
	.byte #>CarSprite3

CarIdToAccelerateSpeed
	.byte #128
	.byte #192
	.byte #96
	.byte #192

CarIdToTimeoverBreakInterval ; Glide
	.byte #%00000011 ;Every 4 frames
	.byte #%00000011 ;Every 4 frames
	.byte #%00001111 ;Every 16 frames
	.byte #%00000011 ;Every 4 frames

CarIdToMaxSpeedL
	.byte #$80
	.byte #$00 ; One less gear
	.byte #$80
	.byte #$80 

CarIdToMaxGear
	.byte #5
	.byte #4 ; One less gear
	.byte #5
	.byte #5

GearToBreakSpeedTable
	.byte #(BREAK_SPEED - 1)
	.byte #(BREAK_SPEED - 1)
	.byte #(BREAK_SPEED + 0)
	.byte #(BREAK_SPEED + 1)
	.byte #(BREAK_SPEED + 2)
	.byte #(BREAK_SPEED + 2)

TrafficColorTable
	.byte #TRAFFIC_COLOR_LIGHT
	.byte #TRAFFIC_COLOR_REGULAR
	.byte #TRAFFIC_COLOR_INTENSE
	.byte #TRAFFIC_COLOR_RUSH_HOUR

TrafficChanceTable
	.byte #TRAFFIC_CHANCE_LIGHT
	.byte #TRAFFIC_CHANCE_REGULAR
	.byte #TRAFFIC_CHANCE_INTENSE
	.byte #TRAFFIC_CHANCE_RUSH_HOUR

TrafficTimeTable
	.byte #CHECKPOINT_TIME_LIGHT
	.byte #CHECKPOINT_TIME_REGULAR
	.byte #CHECKPOINT_TIME_INTENSE
	.byte #CHECKPOINT_TIME_RUSH_HOUR
	.byte #CHECKPOINT_TIME_LIGHT ; For cycling, makes code easier


	org $FFFC
		.word BeforeStart
		.word BeforeStart ; Can be used for subrotine (BRK)