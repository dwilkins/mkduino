# configure_ac.rb
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

module Mkduino
  class ConfigureAc < Mkduino::GeneratedFile
    attr_accessor :makefile_am, :output_filename
    def initialize makefile_am, output_filename = 'configure.ac', options = {}
      super output_filename, options
      @makefile_am = makefile_am
    end

    def write_configure_ac
      write_file do |f|
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
      return

    end
  end
end
