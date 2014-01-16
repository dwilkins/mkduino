require "mkduino/version"
require 'yaml'
require 'find'
require 'pathname'
require 'fileutils'

include FileUtils

module Mkduino
  #
  # Represents the files needed for a particular arduino library
  #
  class ArduinoLibrary
    def initialize name
      @library_sources = []
      @name = name
      @library_includes = []
    end

    def name
      return @name.downcase
    end

    def add_source_file(file)
      pn = Pathname.new(file)
      puts "!! ******** File #{file} not found ******** " unless pn.exist?
      @library_sources << file
    end
    def add_include_path file
      pn = Pathname.new(file)
      puts "!! ******** File #{file} not found ******** " unless pn.exist?
      include_dir = pn.file? ? pn.dirname : file
      puts "Add include for #{file} = #{include_dir}"

      @library_includes << include_dir.to_s unless @library_includes.include? include_dir.to_s
    end

    def linker_name
      self.name
    end

    def library_name
      "lib#{self.name}.a"
    end

    def makefile_am_output
      output = <<LIBRARY_OUTPUT
lib#{self.name}_a_CFLAGS=-Wall -I$(ARDUINO_VARIANTS) $(ARDUINO_COMMON_INCLUDES) $(lib#{self.name}_a_INCLUDES) -Wl,--gc-sections -ffunction-sections -fdata-sections -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
lib#{self.name}_a_CXXFLAGS=-Wall -I$(ARDUINO_VARIANTS) $(ARDUINO_COMMON_INCLUDES) $(lib#{self.name}_a_INCLUDES) -Wl,--gc-sections -ffunction-sections -fdata-sections -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
lib#{self.name}_a_SOURCES = #{@library_sources.join("\\\n                    ")}
lib#{self.name}_a_INCLUDES = -I#{@library_includes.join("\\\n                    -I")}
LIBRARY_OUTPUT
      output
    end
  end

  #
  # Class that keeps up with the stuff needed for the Makefile.am file
  # this is most of the stuff needed to generate the automake stuff
  #

  class MakefileAm
    attr_accessor :source_files, :header_files, :arduino_sources
    attr_accessor :project_name, :project_author, :project_dir
    attr_accessor :project_includes
    # future stuff
    attr_accessor :git_project
    attr_accessor :board, :common_includes

    def initialize
      @project_dir =  Dir.pwd
      @project_name = File.basename @project_dir
      @project_name.tr!('.','_')
      @source_files = []
      @header_files = []
      @project_includes = []
      @arduino_sources = []
      @arduino_includes = []
      @arduino_libraries = []
      @project_author = {}
      @git_project = nil
      @common_libraries = ['arduino', 'spi','wire']
      @libraries_to_skip = {
        'standard' => ['Esplora','GSM','Robot_Control','Robot_Motor','TFT','robot']
      }
      @board='standard'
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

    #
    # Add a source file that we found in this directory
    #
    def add_source_file(file)
      @source_files << "../" + Pathname.new(file).relative_path_from(Pathname.new(@project_dir)).to_s
    end
    def add_header_file(file)
      @header_files << "../" + Pathname.new(file).relative_path_from(Pathname.new(@project_dir)).to_s
    end

    def add_include_path file
      pn = Pathname.new(file)
      puts "!! ******** File #{file} not found ******** " unless pn.exist?
      include_dir = pn.file? ? pn.dirname : file
      puts "Add include for #{file} = #{include_dir}"

      @project_includes << include_dir.to_s unless @project_includes.include? include_dir.to_s
    end


    #
    # As libraries are found, add them to our collection
    # if they're not already there
    #
    def add_arduino_library library
      @arduino_libraries << library  if !arduino_library library
    end

    #
    # fetch a library from our collection - nil if not there
    #

    def arduino_library library
      @arduino_libraries.each do |l|
        return l if l.name == library
      end
      nil
    end

    #
    # output the Makefile.am macro needed for some include
    # files from libraries that are apparently always needed
    #
    def common_includes
      @arduino_libraries.collect do |l|
        @common_libraries.include?(l.name) ? "$(lib#{l.name}_a_INCLUDES)" : nil
      end.compact.join(' ')
    end


    def source_file_pattern
      /\.([c])(pp|)$/
    end

    def header_file_pattern
      /\.([h])(pp|)$/
    end

    #
    # output a list of all the libraries that are needed here
    # for Makefile.am.   The project will depend on these
    #
    def arduino_library_names
      @arduino_libraries.collect do |l|
        l.library_name
      end
    end

    #
    # return the linker entries for all of the libraries that we
    # know about
    #
    def arduino_linker_entries
      @arduino_libraries.collect do |l|
        "-l#{l.linker_name}"
      end
    end

    #
    # after finding all of the Arduino libraries, go through each
    # one of them asking them to output themselves.
    #

    def output_arduino_libraries
      output = @arduino_libraries.collect do |l|
        l.makefile_am_output
      end.join("\n")
      #
      # After all of the library compile lines are output, output
      # a comprehensive list of all of the include directories associated
      # with the libraries.   Used for the source project
      #
      output += "\nLIBRARY_INCLUDES="
      output += @arduino_libraries.collect do |l|
        "$(lib#{l.name}_a_INCLUDES)"
      end.join(' ')
    end

    def find_arduino_libraries libraries_dir
      lib = nil
      Find.find(libraries_dir) do |path|
        if FileTest.directory?(path)
          if File.basename(path)[0] == ?. || File.basename(path) == 'examples' ||
              (@libraries_to_skip[@board] && @libraries_to_skip[@board].include?(File.basename(path)) )
            Find.prune       # Don't look any further into this directory.
          else
            if File.dirname(path) == libraries_dir
              lib_name = path.split('/')[-1]
              lib = arduino_library(lib_name) || ArduinoLibrary.new(lib_name)
              add_arduino_library lib
            end
            next
          end
        elsif path =~ source_file_pattern
          lib.add_source_file path
        elsif path =~ header_file_pattern
          lib.add_include_path path
        end
      end
    end

    def find_source_files
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
        elsif path =~ source_file_pattern
          add_source_file path
        elsif path =~ header_file_pattern
          add_header_file path
          add_include_path path

        end
      end

      #
      # If no source files were found, make
      # the src/ directory and put in a
      # sample main.cpp file
      #
      if source_files.length < 1
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
        add_source_file project_dir + '/src/main.cpp'
      end
    end




    def write_makefile_am
      File.open('Makefile.am',"w") do |f|
        f.puts <<-MAKEFILE_AM
## Process this file with automake to produce Makefile.in
bin_PROGRAMS=#{self.project_name}
# MCU=atmega1280
MCU=atmega328p
F_CPU=-DF_CPU=16000000
ARDUINO_VERSION=-DARDUINO=105
ARDUINO_INSTALL=/usr/share/arduino/hardware/arduino
ARDUINO_CORES=$(ARDUINO_INSTALL)/cores/arduino
ARDUINO_VARIANTS=$(ARDUINO_INSTALL)/variants/#{self.board}
ARDUINO_COMMON_INCLUDES=#{self.common_includes}
ARDUINO_INCLUDE_PATH=-I$(ARDUINO_VARIANTS) $(LIBRARY_INCLUDES)
nodist_#{self.project_name}_SOURCES=#{self.source_files.join(' ')}

#{self.project_name}_CFLAGS=-Wall $(#{self.project_name}_INCLUDES) $(ARDUINO_INCLUDE_PATH) -Wl,--gc-sections -ffunction-sections -fdata-sections -gstabs -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
#{self.project_name}_CXXFLAGS=-Wall $(#{self.project_name}_INCLUDES) $(ARDUINO_INCLUDE_PATH) -Wl,--gc-sections -ffunction-sections -fdata-sections -gstabs -mmcu=$(MCU) $(F_CPU) $(ARDUINO_VERSION) -D__AVR_LIBC_DEPRECATED_ENABLE__
#{self.project_name}_LDFLAGS=-L.
#{self.project_name}_LDADD=#{self.arduino_linker_entries.join(' ')} -lm
#{self.project_name}_INCLUDES=-I#{self.project_includes.join("\\\n                    -I")}

lib_LIBRARIES=#{self.arduino_library_names.join(' ')}
#{self.output_arduino_libraries}


AM_LDFLAGS=
AM_CXXFLAGS=-g0 -Os
AM_CFLAGS=-g0 -Os
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
	$(OBJCOPY) -S -O $(FORMAT) $(bin_PROGRAMS) $(bin_PROGRAMS).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)
MAKEFILE_AM

      end
    end

  end


  class ConfigureAc
    attr_accessor :makefile_am
    def initialize makefile_am
      @makefile_am = makefile_am
    end
    def write_configure_ac
      ##
      # Output the configure.ac file
      ##
      File.open('configure.ac',"w") do |f|
        f.puts <<-CONFIGURE_AC
dnl Process this file with autoconf to produce a configure script.")
AC_INIT([#{makefile_am.project_name}], [1.0])
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
    end
  end

  class AutogenSh
    def write_autogen_sh
      File.open('autogen.sh',"w") do |f|
      f.puts <<-AUTOGEN_SH
#!/bin/sh
if [ -e 'Makefile.am' ] ; then
    echo "Makefile.am Exists - reconfiguring..."
    autoreconf --force --install -I config -I m4
    echo
    echo
    echo "************************************"
    echo "** Now run mkdir build ; cd build ; ../configure --host=avr **"
    echo "************************************"
    exit
fi
echo "Lets get your project started!"

echo '## Process this file with automake to produce Makefile.in' >> Makefile.am
echo No Makefile.am
AUTOGEN_SH
      end
    end
  end
end
