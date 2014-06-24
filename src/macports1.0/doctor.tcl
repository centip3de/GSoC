
package provide doctor 1.0 
package require macports

namespace eval doctor {
    
    proc main {} {
        get_config
        check_path
    }

    proc get_config {} {
        set path        ${macports::portdbpath}/port_doctor.ini
        set return_args [list]

        if {[file exists $path] == 0} {
            ui_msg "No configuration file found. Resorting to defaults."
            return 
        }

        set fd   [open $path r]
        set text [read $fd]
        set data [split $text "\n"]

        close $fd

        foreach line $data {
            set tokens [split $data "="]
            
            if {[lindex $tokens 0] eq "check_path"} {
                lappend return_args [lindex $tokens 1]
            }
        }

    }

    proc check_path {} {
        set output $::env(PATH)

        if {"/opt/local/bin" in $output} {
            return

        } else {
            ui_warn "your environmental \$PATH variable does not currently include, /opt/local/bin, which is where port is located. \
                     Would you like to add /opt/local/bin to your \$PATH variable now? \[Y/N\]"
            
            set input [gets stdin]
            if {$input == "y" || $input == "Y"} {
                ui_msg "Attempting to add /opt/local/bin to your ~/.bash_profile..."

                set home_path   ${macports::user_home}/.bash_profile
                set fd          [open $home_path a]

                puts $fd "PATH=\$PATH:/opt/local/bin"
                puts $fd "export PATH"

                close $fd

                ui_msg "Reloading ~/.bash_profile..."

                exec /bin/bash $home_path

                ui_msg "Port should now be successfully set up."
                
            } elseif {$input == "n" || $input == "N"} {    
                ui_msg "Not fixing your \$PATH variable."

            } else {
                ui_msg "Not a valid choice: $input"
            }
       }
   }

                


}
