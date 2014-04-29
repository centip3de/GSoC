TCL_SUBDIR=			tcl8.5.15/unix
TCL_TARGETS=		install-binaries install-libraries

TCLTHREAD_SUBDIR=	thread2.7.0
TCLTREHAD_TARGETS=	install-binaries install-libraries

TCLX_SUBDIR=		tclx8.4
TCLX_TARGETS=		install-binaries install-libraries

TCLLIB_SUBDIR=		tcllib-1.15
TCLLIB_TARGETS= 	install-libraries

DESTROOT=   		/Users/mrappleseed/GSoC/mports/trunk/base/vendor/vendor-destroot

.PHONY: all clean distclean install destroot test
.PHONY: destroot-tcl destroot-tcllthread destroot-tclx destroot-tcllib
.PHONY: install-tcl install-tcllthread install-tclx install-tcllib
.PHONY: %-tcl %-tcllthread %-tclx %-tcllib

# for make all, run destroot (where destroot will depend on all of each
# subpackage)
all: destroot

%-tcl:
	@echo ===\> making $(@:%-tcl=%) in ${DIRPRFX}tcl8.5.15/unix
	@$(MAKE) -C tcl8.5.15/unix $(@:%-tcl=%)

%-tclthread:
	@echo ===\> making $(@:%-tclthrad=%) in ${DIRPRFX}thread2.7.0
	@$(MAKE) -C thread2.7.0 $(@:%-tclthread=%)

%-tclx:
	@echo ===\> making $(@:%-tclx=%) in ${DIRPRFX}tclx8.4
	@$(MAKE) -C tclx8.4 $(@:%-tclx=%)

%-tcllib:
	@echo ===\> making $(@:%-tcllib=%) in ${DIRPRFX}tcllib-1.15
	@$(MAKE) -C tcllib-1.15 $(@:%-tcllib=%)

destroot: destroot-tcl destroot-tclthread destroot-tclx destroot-tcllib
destroot-tcl: all-tcl
	@echo ===\> staging to destroot in ${DIRPRFX}tcl8.5.15/unix
	@$(MAKE) -C tcl8.5.15/unix DESTDIR=${DESTROOT} install-binaries install-libraries

destroot-tclthread: all-tclthread
	@echo ===\> staging to destroot in ${DIRPRFX}thread2.7.0
	@$(MAKE) -C thread2.7.0 DESTDIR=${DESTROOT} install-binaries install-libraries

destroot-tclx: all-tclx
	@echo ===\> staging to destroot in ${DIRPRFX}tclx8.4
	@$(MAKE) -C tclx8.4 DESTDIR=${DESTROOT} install-binaries install-libraries

destroot-tcllib: all-tcllib
	@echo ===\> staging to destroot in ${DIRPRFX}tcllib-1.15
	@$(MAKE) -C tcllib-1.15 DESTDIR=${DESTROOT} install-libraries

install: install-tcl install-tclthread install-tclx install-tcllib
install-tcl:
	@echo ===\> making $(@:%-tcl=%) in ${DIRPRFX}tcl8.5.15/unix
	@$(MAKE) -C tcl8.5.15/unix install-binaries install-libraries

install-tclthread:
	@echo ===\> making $(@:%-tclthrad=%) in ${DIRPRFX}thread2.7.0
	@$(MAKE) -C thread2.7.0 install-binaries install-libraries

install-tclx:
	@echo ===\> making $(@:%-tclx=%) in ${DIRPRFX}tclx8.4
	@$(MAKE) -C tclx8.4 install-binaries install-libraries

install-tcllib:
	@echo ===\> making $(@:%-tcllib=%) in ${DIRPRFX}tcllib-1.15
	@$(MAKE) -C tcllib-1.15 install-libraries

test:

clean: clean-tcl clean-tcllib clean-tclx clean-tclthread
	rm -rf ${DESTROOT}

distclean:
	rm -f Makefile
	rm -rf $(TCL_SUBDIR:/unix=) $(TCLTHREAD_SUBDIR) $(TCLX_SUBDIR) $(TCLLIB_SUBDIR)
	rm -rf vendor-destroot
