# Custom build rules for Mythryl programs and libraries

# Copyright (c) 2013 Michele Bini <michele.bini@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ALL = test

all: $(ALL)

clean: tempclean
	rm -f $(ALL) *.compiled *.compiled.* mythryl.log *.index .*.module-dependencies-summary .*.version main.log~ load-compiledfiles.c.log

## Rules for compiling Mythryl

BAEMHI=build-an-executable-mythryl-heap-image

%.lib: %.pkg
	@ [ -e "$@"~ ] && mv "$@" "$@"~; (echo LIBRARY_EXPORTS && echo && sed -n "s/^generic package \\([a-z0-9_']*\\).*/	generic \\1/p" <"$<" && sed -n "s/^package \\([a-z0-9_']*\\).*/	pkg \\1/p" <"$<" && echo && echo LIBRARY_COMPONENTS && echo && (sed -n "s/.*#  *Requires:  *\\([^ ]*\\)/\\1/p"|sed "s,standard,""$$""ROOT/src/lib/std/standard.lib,"|sed "s/^/	/") <"$<" && echo && echo "	""$<" && echo) >"$@".new
	@ mv "$@".new "$@"
	@ echo Built "$@"

%.pkg.compiled: %.lib %.pkg 
	mythryld $< -e ""

%: %.lib %.pkg
	${MAKE} tempclean
	${BAEMHI} $< main::main

tempclean:
	rm -rf .tmp-* tmp-* *.compile.log
