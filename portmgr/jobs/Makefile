# $Id: Makefile 118562 2014-04-04 22:58:04Z cal@macports.org $

SCRIPTS=	PortIndex2MySQL

edit = sed \
	-e 's,@TCLSH@,$(TCLSH),g'


include ../../Mk/macports.autoconf.mk


all: ${SCRIPTS}

PortIndex2MySQL: PortIndex2MySQL.tcl
	${edit} $< > $@
	chmod 755 $@

clean:
	rm -f ${SCRIPTS}

distclean: clean
