proc write_signal_list {outfile} {

    set fp [open $outfile w]

    foreach p [get_object_name [get_ports *]] {
        puts $fp $p
    }

    foreach p [get_object_name [get_pins *]] {
        puts $fp $p
    }

    close $fp
}



