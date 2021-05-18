# Hellway V1.43 (Digital Release, cartridge comming soon)

## Introduction
An Atari 2600 game, the objective is to travel the maximum distance possible, given the time limit. The game is done in 6502 assembly, and has no intention to use bankswitch or any enhancement chip, respecting the limitations of the time and a 4k ROM which the vast majority of games of the time had.

It can be played online at https://javatari.org/?ROM=https://github.com/opbokel/hellway/raw/master/bin/hellway.asm.bin

or downloaded as a emulator compatible binnary (in the bin folder). The code will be kept open.

You can get the most recent updates about Hellway in https://atariage.com/forums/topic/316402-hellway-an-atari-2600-homebrew-with-love/

Trailer: https://www.youtube.com/watch?v=FnLFaKNxdbw

## License
Feel free to download, play, burn to a cartridge and have fun. The only restriction is to not sell it in order to make profit. If no profit is made or it is fully donated, I am ok with it. If you do any derivative work, please give the proper credits.

I will sell physical copies in the near future and donate every profit I make to charity projects and people in need. If you like the game, please consider doing any action to make a better day for another person or buying a copy. Also, feel free to talk about it in social medias using the hashtag #hellway2600

## Instructions
The game starts with a QR code, pointing to this repo at the moment. It can be dismissed by pressing fire or game select. Expect improved functionalities in the future. An updated high score and a mobile optimized quick manual are exemples. It can be shown again by cycling through the game modes.

Every track has its own speed, and the car generation is deterministic. Accelerating and braking are equally important.

The top of the screen shows the distance traveled, and also serves as a score. The second field is how much time left, and the third, is your current speed all in hexadecimal.

Every checkpoint (0x100) you receive more time, and the score and the car turn green. This will make you invincible for a few seconds. You will receiving an audio alert just before it.

If the time is over the score and the car turns red, but you still can reach a checkpoint, since the car slowly decelerates. You will start receive an audio alert 10 seconds before the timer is over.

The game is over when the time is over and the car is stopped. The score turns white.

## Switches
* Difficulty switches: They change the traffic intensity and color. The switches form a binary number representing intensity. The more traffic it has, the more time you gain on checkpoints. The time added is of the level you are entering, not of the level you passed (which are the same for fixed traffic intensity modes).  

    * 0 - BB = Light traffic, Green (+ 29 seconds)
    * 1 - BA = Regular traffic, Red (ish) (+ 34 seconds)
    * 3 - AB = Intense Traffic, Purple (+ 39 seconds)
    * 4 - AA = Rush Hour, White (ish) (+ 44 seconds)
    
* Game Reset: Restarts the current game mode and applies the difficulty switches. If the game is stopped and there is no changes to the difficulty switches, it will cycle through the cars.
    * Car 0 - Car with spoiler:
        * Max Speed:    * * *
        * Handling:     * * *
        * Acceleration: * *
        * Gliding:      * *

    * Car 1 - Hatchback:
        * Max Speed:    * *
        * Handling:     * * *
        * Acceleration: * * *
        * Gliding:      * *

    * Car 2 - Sedan:
        * Max Speed:    * * *
        * Handling:     * * *
        * Acceleration: * 
        * Gliding:      * * *

    * Car 3 - Dragster:
        * Max Speed:    * * *
        * Handling:     *
        * Acceleration: * * *
        * Gliding:      * * 

* TV Type (Color / BW): Changes between the default background color and a black background. A completely black background offers better contrast and might work better on Black and White televisions, but can be hard on the eyes. The main reason for this feature is to provide accessibility for people with color blindness or other disabilities. This can be changed anytime during gameplay. It also reverses the QR code color.

* Game Select: Changes the game mode, this must be done before starting the game (or after a reset) while the title is displayed. Modes 0 and 2 should give you the MOST BALANCED EXPERIENCE, regardless of the select car or difficulty switch positions. The game mode is in the top left corner:

    * Mode 0 = Default mode, traffic level changes every checkpoint, and keep cycling. The difficulty switches define only the starting traffic intensity.
    * Mode 1 = Similar to Mode 0, but the traffic level defined by the switches does not change.
    * Mode 2 = Mode 0 + Randomized traffic lines.
    * Mode 3 = Mode 1 + Randomized traffic lines.
    * Mode 4 = Mode 0 + Bigger speed difference between traffic lines.
    * Mode 5 = Mode 1 + Bigger speed difference between traffic lines.
    * Mode 6 = Mode 2 + Bigger speed difference between traffic lines.
    * Mode 7 = Mode 3 + Bigger speed difference between traffic lines.
    * Mode 8 = Mode 0 + Random traffic intensity every checkpoint.
    * Mode 9 = Mode 1 + Random traffic intensity every checkpoint. 
    * Mode A = Mode 2 + Random traffic intensity every checkpoint.
    * Mode B = Mode 3 + Random traffic intensity every checkpoint.
    * Mode C = Mode 4 + Random traffic intensity every checkpoint.
    * Mode D = Mode 5 + Random traffic intensity every checkpoint. 
    * Mode E = Mode 6 + Random traffic intensity every checkpoint.
    * Mode F = Mode 7 + Random traffic intensity every checkpoint.
    * Mode G = QR code

Bigger speed difference between traffic lines makes the game a little harder, with opportunities for overtaking opening and closing much faster and changing lines is more difficult. 

For modes 8 to F, the traffic level to be cyclic or fixed only has effect on the checkpoint time. In this mode, locking into rush hour for example, will make the game easier, since you will always get 45 seconds.

It much easier to read it as a binary number (like linux file permissions). Each byte defines a property (0 / 1).

* D0 => (Cyclic / Fixed) traffic intensity.
* D1 => (Constant / Randomized) traffic lines.
* D2 => (Smaller / Bigger) speed difference between lines.
* D3 => (Constant / Random) traffic intensity.

Deterministic game modes (0,1,4,5) will always generate the same sequence of cars for each line.

If game select is pressed during gameplay, it will draw all text alternating between left and right every 4 seconds. Because of hardware constraints, all text in the game flicker at 30hz, this removes the flickering. The main reason is to allow the screen to be captured no matter what combination of camera and monitor you are using by taking two distinct pictures. This also helps with emulators that do not emulate phosphor mode.

## Border Effects
While in the title screen it is possible to change what the border of the screen looks like by pressing the D-pad:
* Up (default) => Basic strip pattern.
* Left => Tachometer, the stripes grow representing the engine RPM, the vertical line position represents the current gear.
* Down => Vertical parallax, the planes are on top of each other
* Right => Horizontal Parallax, the planes are next to each other.

 
## Controls
* The button starts the game and accelerates.
* Up also accelerates, down brakes, and you can move left to right.
* It is possible to brake and accelerate at the same time, this will brake with half intensity (Heel-and-toe).

## Game Over Screen
Gives you a detailed statistics of the game session:
* S: Score (also distance) in decimal. This is a direct conversion of the HUD.
* T: The total time you spend playing in seconds.
* G: The time you spent gliding (unable to accelerate) in seconds.
* H: The number of times you hit another car.
* C: Total number of checkpoints.
* Last line is a unique identifier of the version of the game and the configuration played, making it easier to to compare scores among friends and online, and also for archiving your scores, it reads like this:
GameMode (0 to F), Car Type (0 to 3), Difficulty Switch 1 (B - A), Difficulty Switch 2 (B - A), | Game Version. 
Example: E2AB|1.30

* Holding the fire button allows you to see the traffic passing by (like in the previous version).


## Closing Thoughts
A very special thanks to all the AtariAge community. 

