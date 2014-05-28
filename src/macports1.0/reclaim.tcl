# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

# TODO:
# Add distfile version checking.
# Remove the useless/structure comments and add actual docstrings.
# Pretty sure we should be using ui_msg, instead of puts and what not. Should probably add that.
# Add test cases
# Add copyright notice

# Finished:
# Register the "port cleanup" command with port.tcl and all that involves.
# Implement a hash-map, or multidimensional array for ease of app info keeping. Write it yourself if you have to.
# Figure out what the hell is going on with "port clean all" vs "port clean installed" the 'clean' target is provided by this package

package provide reclaim 1.0
package require macports
package require portfetch 1.0

namespace eval reclaim {
}

proc reclaim::main {args} {

    # The main function. Calls each individual function that needs to be run.
    # Args: 
    #           None
    # Returns:
    #           None

    uninstall_inactive
    check_distfiles
}

proc walk_files {dir delete} {

    # Recursively walk through each item in the given directory and if requested, delete each file that isn't a directory.
    # Args:
    #           dir    - A string path of the given directory to walk through
    #           delete - Whether to delete each file found that isn't a directory or not. Set to 'yes' or 'no'. 
    # Returns: 
    #           None

    foreach item [readdir $dir] {

        set currentPath [file join $dir $item]

        if {[file isdirectory $currentPath]} {
            walk_files $currentPath $delete 

        } else {
            puts "Found distfile: $item"

            if {$delete eq "yes"} {
                set path [file join $dir $item]
                puts "Removing distfile: $item"

                #Because we're only deleting files (not directories) that we know exist, if there was an error, it's because of lack of root privledges.
                if {[catch {file delete $path} result]} { 
                    elevateToRoot "reclaim"
                    file delete $path
                }
            }
        }
    }
}

proc check_distfiles {} {

    # Check for distfiles in both the root, and home directories. If found, delete them.
    # Args:
    #               None
    #
    # Returns:
    #               0 on successful execution

    global macports::portdbpath
    global macports::user_home

    # The root and home distfile folder locations, respectively. 
    set root [file join ${macports::portdbpath} distfiles]
    set home ${macports::user_home}/.macports$root

    # Walk through each directory, and delete any files found.
    walk_files $root yes
    walk_files $home yes

    # Returning 0 is in style this year. 
    return 0
} 

proc is_inactive {app} {

    # Determine's whether an application is inactive or not.
    # Args: 
    #           app - An array where the fourth item in it is the activity of the application.
    # Returns:
    #           1 if inactive, 0 if active.

    if {[lindex $app 4] == 0} {
        return 1
    }
    return 0
}

proc get_info {} {

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

        lappend app_info [list $name $version $revision $varients $active $epoch]
    }

    return $app_info
}

proc uninstall_inactive {} {

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


