# autogen_sh.rb
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
  class AutogenSh < GeneratedFile
    def initialize output_filename = 'autogen.sh', options = {}
      super output_filename, options
    end
    def write_autogen_sh
      puts("Writing #{@output_filename}")
      write_file do |f|
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
      `chmod +x #{@output_directory}#{@output_filename}`
    end
  end
end
