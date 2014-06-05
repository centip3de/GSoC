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

namespace eval reclaim {
}

proc reclaim::main {args} {

    # The main function. Calls each individual function that needs to be run.
    # Args: 
    #           None
    # Returns:
    #           None

    uninstall_inactive
    remove_distfiles
}

proc reclaim::walk_files {dir delete dist_paths} {

    # Recursively walk through each directory that isn't an installed port and if delete each file that isn't a directory if requested.
    # Args:
    #           dir             - A string path of the given directory to walk through
    #           delete          - Whether to delete each file found that isn't a directory or not. Set to 'yes' or 'no'. 
    #           dist_paths      - A list of the full paths for all distfiles from installed ports  
    # Returns: 
    #           'no' if no distfiles were found, and 'yes' if distfiles were found. 

    set found_distfile no 

    foreach item [readdir $dir] {

        set currentPath [file join $dir $item]

        if {[file isdirectory $currentPath]} {
            walk_files $currentPath $delete $dist_paths

        } else {
            
            if {[lsearch $dist_paths $currentPath] == -1} {
                set found_distfile yes

                # Only care about files that exist in /distfiles that are not a distfile from an installed file.
                puts "Found distfile: $item"

                if {$delete eq "yes" && $item ne ".DS_Store"} {
                    puts "Removing distfile: $item"

                    # Because we're only deleting files (not directories) that we know exist, if there was an error, it's because of lack of root privledges.
                    if {[catch {file delete $currentPath} result]} { 
                        elevateToRoot "reclaim"
                        file delete $currentPath
                    }
                }
            }
        }
    }

    return $found_distfile
}

proc reclaim::remove_distfiles {} {

    # Check for distfiles in both the root, and home directories. If found, delete them.
    # Args:
    #               None
    # Returns:
    #               0 on successful execution

    global macports::portdbpath
    global macports::user_home

    # The root and home distfile folder locations, respectively. 
    set root_dist       [file join ${macports::portdbpath} distfiles]
    set home_dist       ${macports::user_home}/.macports$root_dist

    set port_info    [get_info]
    set dist_path    [list]

    foreach port $port_info {

        # Get mport reference
        set mport [mportopen_installed [lindex $port 0] [lindex $port 1] [lindex $port 2] [lindex $port 3] {}]

        # Setup sub-Tcl-interpreter that executed the installed port
        set workername [ditem_key $mport workername]

        # Append that port's distfiles to the list
        set subdir [$workername eval return \$dist_subdir]
        set name   [$workername eval return \$distfiles]

        set root_path [file join $root_dist $subdir $name]
        set home_path [file join $home_dist $subdir $name]

        # Add the full file path to the list, depending where it's located.
        if {[file isfile $root_path]} {
            lappend dist_path $root_path

        } else {
            if {[file isfile $home_path]} {
                lappend dist_path $home_path
            }
        }
    }

    # Walk through each directory, and delete any files found. Alert the user if no files were found.
    if {[walk_files $root_dist yes $dist_path] eq "no"} {
        puts "No distfiles found in root directory."
    }

    if {[walk_files $home_dist yes $dist_path] eq "no"} {
        puts "No distfiles found in home directory."
    }

    return 0
} 

proc reclaim::is_inactive {app} {

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

proc reclaim::get_info {} {

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

proc reclaim::uninstall_inactive {} {

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


