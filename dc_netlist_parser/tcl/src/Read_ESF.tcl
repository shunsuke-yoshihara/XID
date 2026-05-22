proc read_essential_fault_file {filename} {
    array unset PATTERN_TO_ESF
    array set PATTERN_TO_ESF {}

    set fp [open $filename r]

    while {[gets $fp line] >= 0} {
        if {[regexp {^\s*$} $line]} {
            continue
        }

        set fields [split $line]
        set pattern_id [lindex $fields 0]
        set fault_site [lindex $fields 1]
        set stuck_val  [lindex $fields 2]

        lappend PATTERN_TO_ESF($pattern_id) [list $fault_site $stuck_val]
    }

    close $fp
    return [array get PATTERN_TO_ESF]
}
