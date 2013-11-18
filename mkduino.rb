#! /usr/bin/env ruby
#
# mkduino.rb
#   Ruby script for generating a GNU Automake (ish)
#   environment for Arduino development
#
# (C) Copyright 2013
# David H. Wilkins  <dwilkins@conecuh.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#


require 'yaml'
require 'find'
require 'pathname'
require 'fileutils'

include FileUtils

class MakefileAm
  attr_accessor :source_files, :header_files, :arduino_sources
  attr_accessor :project_name, :project_author, :project_dir
  # future stuff
  attr_accessor :git_project


  def initialize
    @project_dir =  Dir.pwd
    @project_name = File.basename @project_dir
    @project_name.tr!('.','_')
    @source_files = []
    @header_files = []
    @arduino_sources = []
    @project_author = {}
    @git_project = nil
    @project_author[:username] = ENV['USERNAME']
    git_exists = `which git`.chomp
    if git_exists &&  git_exists.length > 0
      @project_author[:name] = `git config --get user.name`.chomp
      @project_author[:email] = `git config --get user.email`.chomp
      @git_project = `git remote show -n origin 2> /dev/null | grep 'Fetch URL:' | cut -f 5 -d ' '`.chomp
    else
      @project_author[:name] = @project_author[:username]
      @project_author[:email]= @project_author[:username]
      @git_project = "no_git_project"
    end
  end


  def add_source_file(file)
    @source_files << Pathname.new(file).relative_path_from(Pathname.new(@project_dir)).to_s
  end
  def add_header_file(file)
    @header_files << Pathname.new(file).relative_path_from(Pathname.new(@project_dir)).to_s
  end
  def add_arduino_source_file(file)
    pn = Pathname.new(file)
    puts "!! ******** File #{file} not found ******** " unless pn.exist?
    @arduino_sources << file
  end


  def source_file_pattern
    /\.([c])(pp|)$/
  end
  def header_file_pattern
    /\.([h])(pp|)$/
  end

end

class ConfigureAc

end


ma = MakefileAm.new

#
# Root around for some source file
# and add them to the Makefile.am
#
Find.find(Dir.pwd) do |path|
  if FileTest.directory?(path)
    if File.basename(path)[0] == ?.
      Find.prune       # Don't look any further into this directory.
    else
      next
    end
  elsif path =~ ma.source_file_pattern
    ma.add_source_file path
  elsif path =~ ma.header_file_pattern
    ma.add_header_file path
  end
end

#
# If no source files were found, make
# the src/ directory and put in a
# sample main.cpp file
#
if ma.source_files.length < 1
  `mkdir src`  unless Dir.exist?('src')
  File.open('src/main.cpp',"w") do |f|
  f.puts <<-MAIN_CPP
#include <Arduino.h>

extern "C" void __cxa_pure_virtual(void) {
    while(1);
}

void setup() {
  Serial.begin(115200);
  Serial.println("Startup...");
}

void loop() {
}



int main(void)
{
  init();
  setup();
  for (;;){
    loop();
  }
  return 0;
}
MAIN_CPP
  end
  ma.add_source_file ma.project_dir + '/src/main.cpp'
end


##
# Add a bunch of Arduino source files to the makefile
# these will go into building the libcore.a library
# for this project
##

ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/HardwareSerial.cpp'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/WMath.cpp'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/WString.cpp'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/Print.cpp'
## ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/IPAddress.cpp'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/wiring.c'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/wiring_analog.c'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/wiring_digital.c'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/wiring_pulse.c'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/wiring_shift.c'
ma.add_arduino_source_file '/usr/share/arduino/hardware/arduino/cores/arduino/WInterrupts.c'

puts ma.to_yaml

##
# Output the Makefile.am file withe the needed variable replacements
##
File.open('Makefile.am',"w") do |f|
  f.puts <<-MAKEFILE_AM
## Process this file with automake to produce Makefile.in
bin_PROGRAMS=#{ma.project_name}
# MCU=atmega1280
MCU=atmega328p
F_CPU=-DF_CPU=16000000
ARDUINO_VERSION=-DARDUINO=105
ARDUINO_INSTALL=/usr/share/arduino/hardware/arduino
ARDUINO_CORES=$(ARDUINO_INSTALL)/cores/arduino
ARDUINO_VARIANTS=$(ARDUINO_INSTALL)/variants/standard
ARDUINO_INCLUDE_PATH=-I$(ARDUINO_CORES) -I$(ARDUINO_VARIANTS)
nodist_#{ma.project_name}_SOURCES=#{ma.source_files.join(' ')} #{ma.header_files.join(' ')}
#{ma.project_name}_CFLAGS=-Wall $(ARDUINO_INCLUDE_PATH) -gstabs -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
#{ma.project_name}_CXXFLAGS=-Wall $(ARDUINO_INCLUDE_PATH) -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
#{ma.project_name}_LDFLAGS=-L.
#{ma.project_name}_LDADD=-lcore -lm

lib_LIBRARIES=libcore.a
libcore_a_CFLAGS=-Wall $(ARDUINO_INCLUDE_PATH) -gstabs -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
libcore_a_CXXFLAGS=-Wall $(ARDUINO_INCLUDE_PATH) -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
libcore_a_SOURCES = #{ma.arduino_sources.join("\\\n                  ")}


AM_LDFLAGS=
AM_CXXFLAGS=-g
AM_CFLAGS=-g
VPATH=/usr/share/arduino/hardware/arduino/cores/arduino

# AVRDUDE_PORT=/dev/ttyACM0
AVRDUDE_PORT=/dev/ttyUSB0
AVRDUDE_PROGRAMMER = arduino
# UPLOAD_RATE = 115200
UPLOAD_RATE = 57600
FORMAT=ihex

AVRDUDE_WRITE_FLASH = -U flash:w:$(bin_PROGRAMS).hex
AVRDUDE_FLAGS = -q -D -C/etc/avrdude/avrdude.conf -p$(MCU) -P$(AVRDUDE_PORT) -c$(AVRDUDE_PROGRAMMER) -b$(UPLOAD_RATE)


.PHONY: upload
upload: all-am
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $(bin_PROGRAMS) $(bin_PROGRAMS).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)
MAKEFILE_AM

end

##
# Output the configure.ac file
##
File.open('configure.ac',"w") do |f|
  f.puts <<-CONFIGURE_AC
dnl Process this file with autoconf to produce a configure script.")
AC_INIT([#{ma.project_name}], [1.0])
dnl AC_CONFIG_SRCDIR( [ Makefile.am ] )
AM_INIT_AUTOMAKE
AM_CONFIG_HEADER(config.h)
dnl AM_CONFIG_HEADER(config.h)
dnl Checks for programs.
AC_PROG_CC( avr-gcc )
AC_PROG_CXX( avr-g++ )
AC_PROG_RANLIB( avr-ranlib )
AC_PATH_PROG(OBJCOPY, avr-objcopy)
AC_PATH_PROG(AVRDUDE, avrdude)

AC_ISC_POSIX

dnl Checks for libraries.

dnl Checks for header files.
AC_HAVE_HEADERS( Arduino.h )

dnl Checks for library functions.

dnl Check for st_blksize in struct stat


dnl internationalization macros
AC_OUTPUT([Makefile])

CONFIGURE_AC

end

File.open('autogen.sh',"w") do |f|
  f.puts <<-AUTOGEN_SH
#!/bin/sh
if [ -e 'Makefile.am' ] ; then
    echo "Makefile.am Exists - reconfiguring..."
    autoreconf --force --install -I config -I m4
    echo
    echo
    echo "************************************"
    echo "** Now run ./configure --host=avr **"
    echo "************************************"
    exit
fi
echo "Lets get your project started!"

echo '## Process this file with automake to produce Makefile.in' >> Makefile.am
echo No Makefile.am
AUTOGEN_SH
end


`chmod +x autogen.sh`
`mkdir m4` unless Dir.exist?('m4')
`mkdir config` unless Dir.exist?('config')
`touch config/config.h`
`touch NEWS`
`touch README`
`touch AUTHORS`
`touch ChangeLog`

puts "*******************************"
puts "** now run ./autogen.sh      **"
puts "*******************************"
