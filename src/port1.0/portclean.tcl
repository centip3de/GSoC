# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# $Id: portclean.tcl 116449 2014-01-25 16:57:17Z cal@macports.org $
#
# Copyright (c) 2005-2007, 2009-2011, 2013-2014 The MacPorts Project
# Copyright (c) 2004 Robert Shaw <rshaw@opendarwin.org>
# Copyright (c) 2002 - 2003 Apple Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Inc. nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

# the 'clean' target is provided by this package


# TODO:
# Register the "port clean inactive" command with port.tcl and all that involves.
# Add distfile version checking.
# Add multiple version checking. Test with multiple versions of Python? Or Perl? Or some other common multi-versioned software (Gimp?).
# Add docstrings for the rest of the functions in here at the end. Lack of documentation is sad. 
# Remove the useless/structure comments and add actual docstrings.

# Finished:
# Implement a hash-map, or multidimensional array for ease of app info keeping. Write it yourself if you have to.
# Figure out what the hell is going on with "port clean all" vs "port clean installed" the 'clean' target is provided by this package

package provide portclean 1.0

package require portutil 1.0
package require portrpm 1.0
package require Pextlib 1.0

set org.macports.clean [target_new org.macports.clean portclean::clean_main]
target_runtype ${org.macports.clean} always
target_state ${org.macports.clean} no
target_provides ${org.macports.clean} clean
target_requires ${org.macports.clean} main
target_prerun ${org.macports.clean} portclean::clean_start

namespace eval portclean {
}

set_ui_prefix

proc is_inactive {app} {

    # Determine's whether an application is inactive or not.
    # Args: 
    #           app - An array where the fourth item in it is the activity of the application. 
    # Returns:
    #           1 if inactive, 0 if active.

    if {[lindex $app 4] == 1} {
        return 1
    }
    return 0
}

proc portclean::get_info {} {

    # Get's the information of all installed appliations (those returned by registry::instaled), and returns it in a
    # multidimensional list.
    #
    # Args:
    #           None
    #Returns:
    #           A multidimensional list where each app is a sublist, i.e., {{First Application Info} {Second Application Info} {...}}
    #           Indexes of each sublist are: 0 = name, 1 = version, 2 = revision, 3 = variets, 4 = activity, and 5 = epoch.
    
    set installed_apps [registry::installed]
    set app_info [list] 

    foreach app $installed_apps {

        set name     [lindex $app 0]
        set version  [lindex $app 1]
        set revision [lindex $app 2]
        set varients [lindex $app 3]
        set active   [lindex $app 4]
        set epoch    [lindex $app 5]

        puts [portrpm::make_dependency_list $name]

        lappend app_info [list $name $version $revision $varients $active $epoch]
    }

    return $app_info
}

proc delete_file {args} {

    # Attempts to delete a given file, and catches the errors if there are any.
    #
    # Args:
    #           args - The file path
    # Returns:
    #           None

    ui_debug "Removing file: $args"
    if {[catch {delete $args} result]} {
        ui_debug "$::errorInfo"
        ui_error "$result"
    }
}

proc portclean::clean_inactive {} {

    # Attempts to uninstall all inactive applications. (Performance is now O(N)!)
    #
    # Args: 
    #           None
    # Returns: 
    #           0 if execution was successful.

    set apps [get_info]
    set inactive_count 0

    foreach app $apps {

        if { [is_inactive $app] } {
            set name [lindex $app 0]
            puts "Uninstalling: $name"
            incr inactive_count

            # Note: 'uninstall' takes a name, version, and an options list. 
            registry_uninstall [lindex $app 0] [lindex $app 1] {}
        }
    }
    if { $inactive_count == 0 } {
        puts "Found no inactive ports."
    }

    return 0
}

proc portclean::clean_start {args} {
    global UI_PREFIX prefix

    ui_notice "$UI_PREFIX [format [msgcat::mc "Cleaning %s"] [option subport]]"

    if {[getuid] == 0 && [geteuid] != 0} {
        elevateToRoot "clean"
    }
}

proc portclean::clean_main {} {

    # The main function. Picks which action to do based on which globals (ew) are set or not. 
    #
    # Args (i.e. globals): 
    #           ports_clean_dist     - Determines whether to do 'port clean dist' or not. Set to 'yes' or 'no'.
    #           ports_clean_work     - Determines whether to do 'port clean work' or not. Set to 'yes' or 'no'.
    #           ports_clean_logs     - Determines whether to do 'port clean logs' or not. Set to 'yes' or 'no'.
    #           ports_clean_inactive - Determines whether to do 'port clean inactive' or not. Set to 'yes' or 'no'.
    #           ports_clean_archive  - Determines whether to do 'port clean archive' or not. Set to 'yes' or 'no'.
    #           ports_clean_all      - Determines whether to do all 'port clean' operations. Set to 'yes' or 'no'.
    #           keeplogs             - Determines whether to do 'port clean logs' or not. Set to 'yes' or 'no'.
    #
    # Returns:
    #           None

    global UI_PREFIX ports_clean_dist ports_clean_work ports_clean_logs ports_clean_inactive \
           ports_clean_archive ports_clean_all keeplogs usealtworkpath

    if {$usealtworkpath} {
        ui_warn "Only cleaning in ~/.macports; insufficient privileges for standard locations"
    }

    if {[info exists ports_clean_all] && $ports_clean_all eq "yes" || \
        [info exists ports_clean_dist] && $ports_clean_dist eq "yes"} {
        ui_info "$UI_PREFIX [format [msgcat::mc "Removing distfiles for %s"] [option subport]]"
        clean_dist
    }
    if {([info exists ports_clean_all] && $ports_clean_all eq "yes" || \
        [info exists ports_clean_archive] && $ports_clean_archive eq "yes")
        && !$usealtworkpath} {
        ui_info "$UI_PREFIX [format [msgcat::mc "Removing temporary archives for %s"] [option subport]]"
        clean_archive
    }
    if {[info exists ports_clean_all] && $ports_clean_all eq "yes" || \
        [info exists ports_clean_work] && $ports_clean_work eq "yes" || \
        [info exists ports_clean_archive] && $ports_clean_archive eq "yes" || \
        [info exists ports_clean_dist] && $ports_clean_dist eq "yes" || \
        !([info exists ports_clean_logs] && $ports_clean_logs eq "yes")} {
         ui_info "$UI_PREFIX [format [msgcat::mc "Removing work directory for %s"] [option subport]]"
         clean_work
    }
    if {(([info exists ports_clean_logs] && $ports_clean_logs eq "yes") || ($keeplogs eq "no"))
        && !$usealtworkpath} {
        clean_logs
    }

    if {[info exists ports_clean_inactive] && $port_clean_inactive eq "yes" || \
        [info exists ports_clean_all] && $port_clean_all eq "yes"} {
            clean_inactive
    }

    return 0
}

#
# Remove the directory where the distfiles reside.
# This is crude, but works.
#
proc portclean::clean_dist {} {
    global name ports_force distpath dist_subdir distfiles patchfiles usealtworkpath portdbpath altprefix

    # remove known distfiles for sure (if they exist)
    set count 0
    foreach file $distfiles {
        set distfile [getdistname $file]
        ui_debug "Looking for $distfile"
        set distfile [file join $distpath $distfile]
        if {[file isfile $distfile]} {
            delete_file $distfile
            incr count
        }
        if {!$usealtworkpath && [file isfile ${altprefix}${distfile}]} {
            delete_file ${altprefix}${distfile}
            incr count
        }
    }
    if {$count > 0} {
        ui_debug "$count distfile(s) removed."
    } else {
        ui_debug "No distfiles found to remove at $distpath"
    }

    set count 0
    if {![info exists patchfiles]} {
        set patchfiles ""
    }
    foreach file $patchfiles {
        set patchfile [getdistname $file]
        ui_debug "Looking for $patchfile"
        set patchfile [file join $distpath $patchfile]
        if {[file isfile $patchfile]} {
            delete_file $patchfile
            incr count
        }
        if {!$usealtworkpath && [file isfile ${altprefix}${patchfile}]} {
            delete_file ${altprefix}${patchfile}
            incr count
        }
    }
    if {$count > 0} {
        ui_debug "$count patchfile(s) removed."
    } else {
        ui_debug "No patchfiles found to remove at $distpath"
    }

    # next remove dist_subdir if only needed for this port,
    # or if user forces us to
    set dirlist [list]
    if {$dist_subdir != $name} {
        if {!([info exists ports_force] && $ports_force eq "yes")
            && [file isdirectory $distpath]
            && [llength [readdir $distpath]] > 0} {
            ui_warn [format [msgcat::mc "Distfiles directory '%s' may contain distfiles needed for other ports, use the -f flag to force removal" ] $distpath]
        } else {
            lappend dirlist $dist_subdir
            lappend dirlist $name
        }
    } else {
        lappend dirlist $name
    }
    # loop through directories
    set count 0
    foreach dir $dirlist {
        if {$usealtworkpath} {
            set distdir [file join ${altprefix}${portdbpath} distfiles $dir]
        } else {
            set distdir [file join ${portdbpath} distfiles $dir]
        }
        if {[file isdirectory $distdir]} {
            delete_file $distdir
            incr count
        }
        if {!$usealtworkpath && [file isdirectory ${altprefix}${distdir}]} {
            delete_file ${altprefix}${distdir}
            incr count
        }
    }
    if {$count > 0} {
        ui_debug "$count distfile directory(s) removed."
    } else {
        ui_debug "No distfile directory found to remove."
    }
    return 0
}

proc portclean::clean_work {} {
    global portbuildpath subbuildpath worksymlink usealtworkpath altprefix portpath

    if {[file isdirectory $subbuildpath]} {
        delete_file $subbuildpath
        # silently fail if non-empty (other subports might be using portbuildpath)
        catch {file delete $portbuildpath}
    } else {
        ui_debug "No work directory found to remove at ${subbuildpath}"
    }

    if {!$usealtworkpath && [file isdirectory ${altprefix}${subbuildpath}]} {
        delete_file ${altprefix}${subbuildpath}
        catch {file delete ${altprefix}${portbuildpath}}
    } else {
        ui_debug "No work directory found to remove at ${altprefix}${subbuildpath}"
    }

    # Clean symlink, if necessary
    if {![catch {file type $worksymlink} result] && $result eq "link"} {
        ui_debug "Removing symlink: $worksymlink"
        delete $worksymlink
    }
    
    # clean port dir in alt prefix
    if {[file exists "${altprefix}${portpath}"]} {
        ui_debug "removing ${altprefix}${portpath}"
        delete "${altprefix}${portpath}"
    }

    return 0
}

proc portclean::clean_logs {} {
    global portpath portbuildpath worksymlink portverbose keeplogs prefix subport
    set logpath [getportlogpath $portpath]
    set subdir [file join $logpath $subport]
  	if {[file isdirectory $subdir]} {
        delete_file $subdir
        catch {file delete $logpath}
    } else {
        ui_debug "No log directory found to remove at ${logpath}"
    }           	
    return 0
}

proc portclean::clean_archive {} {
    global subport ports_version_glob portdbpath

    # Define archive destination directory, target filename, regex for archive name
    set archivepath [file join $portdbpath incoming]

    if {[info exists ports_version_glob]} {
        # Match all possible archive variants that match the version
        # glob specified by the user.
        set fileglob "$subport-[option ports_version_glob]*.*.*.*"
    } else {
        # Match all possible archives for this port.
        set fileglob "$subport-*_*.*.*.*"
    }

    # Remove the archive files
    set count 0
    foreach dir [list $archivepath ${archivepath}/verified] {
        set archivelist [glob -nocomplain -directory $dir $fileglob]
        foreach path $archivelist {
            # Make sure file is truly an archive file for this port, and not
            # an accidental match with some other file that might exist. Also
            # delete anything ending in .TMP since those are incomplete and
            # thus can't be checked and aren't useful anyway.
            set archivetype [string range [file extension $path] 1 end]
            if {[file isfile $path] && ($archivetype eq "TMP"
                || [extract_archive_metadata $path $archivetype portname] == $subport)} {
                delete_file $path
                if {[file isfile ${path}.rmd160]} {
                    delete_file ${path}.rmd160
                }
                incr count
            }
        }
    }
    if {$count > 0} {
        ui_debug "$count archive(s) removed."
    } else {
        ui_debug "No archives found to remove at $archivepath"
    }

    return 0
}
