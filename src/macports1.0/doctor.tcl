

# Todo:
# Move port_doctor.ini to the port tree, below _resources 
# Command-Line tools version check

package provide doctor 1.0 
package require macports
package require portutil 1.0

namespace eval doctor {
    
    proc main {} {
        
        # The main function. Handles all the calls to the correct functions, and sets the config_options array.
        #
        # Args:
        #           None
        # Returns:
        #           None

        array set config_options [list]

        set parser_options {"macports_location" "profile_path" "shell_location" "xcode_version_10.9" "xcode_version_10.8" \
                            "xcode_version_10.7" "xcode_version_10.6" "xcode_version_10.7" "xcode_version_10.6" "xcode_version_10.5" \
                            "xcode_version_10.4" "xcode_build"}

        get_config config_options $parser_options
        check_path $config_options(macports_location) $config_options(profile_path) $config_options(shell_location)
        check_xcode config_options
    }

    proc check_xcode {config_options} {
        upvar $config_options config 

        set mac_version     ${macports::macosx_version}
        set xcode_current   ${macports::xcodeversion} 
        set xcode_versions  $config(xcode_version_$mac_version)

        if {$xcode_current in $xcode_versions} {
            return
        
        } else {
            ui_error "currently installed version of Xcode, $xcode_current, is not supported by MacPorts. \
                      For your currently installed system, only the following versions of Xcode are supported: \
                      $xcode_versions"
        }
    }

    proc make_default_config {} {

        # Builds a config for the user, using all default parameters.
        #
        # Args:
        #           None
        # Returns:
        #           None

        set path    ${macports::portdbpath}/port_doctor.ini
        set fd      [open $path w]
        
        puts $fd "macports_location=/opt/local"
        puts $fd "profile_path=${macports::user_home}/.bash_profile"
        puts $fd "shell_location=/bin/bash"
        puts $fd "xcode_version_10.9=5.1.1 5.1 5.0.2 5.0.1"
        puts $fd "xcode_version_10.8=5.1 5.0.2 5.0.1 5.0 4.6.3 4.6.2 4.6.1 4.6 4.5.2 4.5.1 4.5"
        puts $fd "xcode_version_10.7=4.6.3 4.6.2 4.6.1 4.6 4.5.2 4.5.1 4.5 4.3.3"
        puts $fd "xcode_version_10.6=4.2 3.2.6 3.2.5 3.2.4 3.2.3 3.2.2 3.2.1 3.2"
        puts $fd "xcode_version_10.5=3.1.4 3.1.3 3.1.2 3.1.1 3.1 3.0"
        puts $fd "xcode_version_10.4=2.5 2.4.1 2.4 2.3 2.2.1 2.2 2.1 2.0"
        puts $fd "xcode_build=5B1008"
        
        close $fd
   }

    proc get_config {config_options parser_options} {

        # Reads in and parses the configureation file, port_doctor.ini. After parsing, all variables found are assigned 
        # in the 'config_options' associative array.
        #
        # Args:
        #           config_options - The associative array responsible for holding all the configuration options.
        #           parser_options - The list responsible for holding each option to set/look for in the configuration file.
        # Returns:
        #           None. 

        upvar $config_options config 

        set path ${macports::portdbpath}/port_doctor.ini

        if {[file exists $path] == 0} {
            ui_warn "No configuration file found. Creating generic config file."
            make_default_config
        }

        set fd   [open $path r]
        set text [read $fd]
        set data [split $text "\n"]

        close $fd

        foreach line $data { 
            set tokens [split $line "="]

            if {[lindex $tokens 0] in $parser_options} {
                set config([lindex $tokens 0]) [lindex $tokens 1]
            
            } elseif {[lindex $tokens 0] eq ""} {
                continue

            } else {
                ui_error "unrecognized port_doctor.ini config option: [lindex $tokens 0]"
            }
        }
    }

    proc check_path {port_loc profile_path shell_loc} {

        # Checks to see if port_location/bin and port_location/sbin are in the environmental $PATH variable.
        # If they aren't, it appends it to the correct shell's profile file.
        #
        # Args:
        #           port_loc        - The location of port (as set in the config file)
        #           profile_path    - The location of the profile file (as set in the config file)
        #           shell_loc       - The location of the shell binary (as set in the config file)
        # Returns:
        #           None.

        set path ${macports::user_path}
        set split [split $path :]

        if {"$port_loc/bin" in $split && "$port_loc/sbin" in $split } {
            return

        } else {
            ui_warn "your environmental \$PATH variable does not currently include, $port_loc/bin, which is where port is located. \
                     Would you like to add $port_loc/bin to your \$PATH variable now? \[Y/N\]"
            set input [gets stdin]

            if {$input == "y" || $input == "Y"} {
                ui_msg "Attempting to add $port_loc/bin to $profile_path"

                if {[file exists $profile_path] == 1} {
                    set fd [open $profile_path a]

                } else {
                    ui_error "$profile_path does not exist."
                }

                puts $fd "export PATH=$port_loc/bin:$port_loc/sbin:\$PATH"
                close $fd

                ui_msg "Reloading $profile_path..."
                exec $shell_loc $profile_path

                ui_msg "Port should now be successfully set up."
                
            } elseif {$input == "n" || $input == "N"} {    
                ui_msg "Not fixing your \$PATH variable."

            } else {
                ui_msg "Not a valid choice: $input"
            }
       }
   }
}
