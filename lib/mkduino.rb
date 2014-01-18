# mkduino.rb
#
# (C) Copyright 2013,2014
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


require "mkduino/version"
require 'yaml'
require 'find'
require 'pathname'
require 'fileutils'

include FileUtils

require_relative "file_generator"
require_relative "makefile_am"
require_relative "configure_ac"
require_relative "autogen_sh"

module Mkduino
  GENERATED_FILES = ["Makefile.am",
                     "configure.ac",
                     "autogen.sh",
                     "config/config.h",
                     "NEWS",
                     "README",
                     "AUTHORS",
                     "ChangeLog"]


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


end
