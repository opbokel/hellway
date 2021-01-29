# Hellway

## Introduction
An Atari 2600 game, the objective is to travel the maximum distance possible, given the time limit. The game is done in 6502 assembly, and has no intention to use bankswitch or any enhancement chip, respecting the limitations of the time and a 4k ROM which the vast majority of games of the time had.

It can be played online at https://javatari.org/?ROM=https://github.com/opbokel/hellway/blob/master/bin/hellway.asm.bin?raw=true
Or downloaded as a emulator compatible binnary (in the bin folder). The code will be kept open.

## License
Feel free to download, play, burn to a cartridge and have fun. The only restriction is to not sell it in order to make profit. If no profit is made or it is fully donated, I am ok with it. If you do any derivative work, please give the proper credits.

I will sell physical copies in the near future and donate every profit I made to charity projects and people in need. If you like the game, please consider doing any action to make a better day for another person or buying a copy. Also, feel free to talk about it in social medias using the hashtag #hellway2600

## Instructions
Every track has its own speed, and the car generation is deterministic. Accelerating and breaking are equally important.

The top of the screen shows the distance traveled, and also serves as a score. The second field is how much time left, and the third, is your current speed all in hexadecimal.

Every checkpoint you receive more time, and the score turns green.

If the time is over the score turns red, but you still can reach a checkpoint, since the car slowly decelerates.

The game is over when the time is over and the car is stopped. The score turns yellow.

## Switches
* The two difficulty switches change the traffic intensity and color. The switches form a binary number representing intensity. The more traffic it has, the more time you gain on checkpoints. The constants of color, time and traffic are still subject to fine tuning. I tried to reduce eye strain in the color scheme.
    * 0 - BB = Light traffic, Green
    * 1 - BA = Regular traffic, Red (ish) That is the traffic level I personally enjoy the most.
    * 3 - AB = Intense Traffic, Yellow
    * 4 - AA = Rush Hour, White (ish)
    
* Reset restarts the the current game mode and apply the difficulty switches.

## Controls
* The button starts the game and accelerates.
* Up also accelerates, down breaks, and you can move left to right.
* It is possible to break and accelerate at the same time, this will break with half intensity (Heel-and-toe).

## Current Roadmap (the priorities might change):
* A mode where the tracks start at a random position.
* A mode where the tracks speeds are also random.
* A mode where the car is always slowly accelerating, if a limited number of collisions.
* 2 players mode of the above (Very easy since it will be a matter of not hiding the second playfield duplication if players cannot control acceleration)
* Sound (Engine and collision)
* A real 2 players mode where each half of the screen has its own state (hard, and not sure if possible). The game will flicker at 30Hz.
* Evaluate the need for decimal score.

## Closing Thoughts
A very special thanks to all the AtariAge community. You can get the most recent updates about Hellway in https://atariage.com/forums/topic/316402-hellway-an-atari-2600-homebrew-with-love/

