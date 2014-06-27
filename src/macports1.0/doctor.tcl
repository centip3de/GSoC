
package provide doctor 1.0 
package require macports

namespace eval doctor {
    
    proc main {} {
        
        # The main function. Handles all the calls to the correct functions, and sets the config_options array.
        #
        # Args:
        #           None
        # Returns:
        #           None

        array set config_options [list]

        get_config config_options
        check_path $config_options("macports_location") $config_options("profile_path") $config_options("shell_loc")
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
        puts $fd "xcode_version=4.14"
        
        close $fd
   }

    proc get_config {config_options} {

        # Reads in and parses the configureation file, port_doctor.ini. After parsing, all variables found are assigned 
        # in the 'config_options' associative array.
        #
        # Args:
        #           config_options - The associative array responsible for holding all the configuration options.
        # Returns:
        #           None. 

        upvar $config_options config 

        set path        ${macports::portdbpath}/port_doctor.ini
        set return_args [list]

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

            if {[lindex $tokens 0] eq "macports_location"} {
                set config("macports_location") [lindex $tokens 1]

            } elseif {[lindex $tokens 0] eq "profile_path"} {
                set config("profile_path") [lindex $tokens 1]

            } elseif {[lindex $tokens 0] eq "xcode_version"} {
                set config("xcode_version") [lindex $tokens 1]

            } elseif {[lindex $tokens 0] eq "shell_location"} {
                set config("shell_loc") [lindex $tokens 1]

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
