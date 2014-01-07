mkduino
=======

Ruby script for generating a GNU Automake style makefile system for your arduino projects

You'll probably need to use Fedora 19 to have this work out of the box.   Pull requests or
github issues for other distributions / systems will thoughtfully considered.

If there's enough interest, I'll add some command line switches and more dynamic configuration
of he environment.  It would probably be simple to find the arduino environment rather than
hardcoding it.  Also, doing a `git init` and adding certain files to the repo would be really
handy for someone that uses this regularly.   Again - add github issues or send pull requests...

## Installation

`gem install mkduino`

## Usage
========
Go to the directory where your source code is(or should be):

```
mkduino
./autogen.sh
./configure --host=avr
make
make upload
```

## Files Generated
==================

### src/main.cpp
This cpp file is generated if there are no `.cpp`, `.hpp`, `.c` or `.h` files found when mkduino is run.
It's a simple file like the one generated from the IDE.

### Makefile.am
This is where most of the configuration for automake ends up.   This Automake file is
initially configured for an Arduino Pro Mini, but there are some variables that can
be changed in this file to customize it.   Any changes made to this file will be
automatically picked up by make on your next make invocation.

* `ARDUINO_VERSION=-DARDUINO=105`
  Define of what version of the Arduino libaries you're using.
* `ARDUINO_INSTALL=/usr/share/arduino/hardware/arduino`
  Where the Arduino library stuff is installed.   This is the default on a Fedora system
* `MCU=atmega328p`
   Change this if you have a different supported ATMEL chip.
   For instance set it to `MCU=atmega1280` for an ATMEL atmega1280 chip
* `ARDUINO_VARIANTS=$(ARDUINO_INSTALL)/variants/standard`
   You many need to change `standard` to something else for mega 1280 and 2560 chips
* `AVRDUDE_PORT=/dev/ttyUSB0`
  The port that `make upload` will try to send the code to.
* `AVRDUDE_PROGRAMMER = arduino*`
  The `avrdude` programmer type.
  Check the [`avrdude` documentation](http://www.nongnu.org/avrdude/user-manual)

### configure.ac
There's not much to see here.  This file is customized with the project name and that's about it.

### autogen.sh
Execute this file after running `mkduino`.  This file isn't customized for each project - it's the same every time.

### README, NEWS, AUTHORS, ChangeLog, config/config.h and m4/
Standard files and directories for GNU Automake.   Just created, nothing is in them.

## Why?
======
Every time I run the Arduino IDE I struggle to have my hands unlearn the `emacs` keybindings
so I can do some little thing.  I got really tired of it and made myself a makefile.

After bragging about my makefile prowess to my friends, they all wanted to ditch the Arduino IDE.
I was embarrassed of my initial makefile, so I decided to make an environment builder for Arduino.
My initial try at this projects included downloading all of the tools (yes, even gcc), building
it all very similarly to `rvm`.   That proved to be a project much too big for the typical Arduino
hacker to undertake, so I quickly regrouped and hacked out this ruby script to make an automake
environment.

Hopefully this enables you to use your environment of choice for Arduino hacking.
