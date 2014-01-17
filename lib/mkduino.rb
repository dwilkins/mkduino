require "mkduino/version"
require 'yaml'
require 'find'
require 'pathname'
require 'fileutils'

include FileUtils

require_relative "makefile_am"


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


  class ConfigureAc
    attr_accessor :makefile_am
    def initialize makefile_am
      @makefile_am = makefile_am
    end
    def write_configure_ac
      ##
      # Output the configure.ac file
      ##
      puts "Writing configure.ac"
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
      puts("Writing autogen.sh")
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
