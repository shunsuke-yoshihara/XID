puts $env(TIMESTAMP)

############## Define Circuit ##############
set circuit b14
set CIRCUIT /gdsfs/gdsfs/yoshihara/XID/${circuit}/_${circuit}.v
set ESF_FILE "/gdsfs/gdsfs/yoshihara/XID/${circuit}/${circuit}_Essential_Fault.txt"
############################################


#Read Netlist
read_verilog ${CIRCUIT}
current_design ${circuit}
link
puts ""


source /gdsfs/gdsfs/yoshihara/XID/dc_netlist_parser/tcl/src/utility.tcl
source /gdsfs/gdsfs/yoshihara/XID/dc_netlist_parser/tcl/src/Read_ESF.tcl







######################################################
# Main #
######################################################
# デバッグ
set ESF_FILE "/gdsfs/gdsfs/yoshihara/XID/b14/b14_Essential_Fault.txt"

array set ESF [read_essential_fault_file $ESF_FILE]

foreach pattern_id [lsort -integer [array names ESF]] {

    puts "=================================="
    puts "Pattern : $pattern_id"

    foreach esf $ESF($pattern_id) {

        set fault_site [lindex $esf 0]
        set stuck_val  [lindex $esf 1]

        puts "  fault_site = $fault_site"
        puts "  stuck_val  = $stuck_val"
    }
}


quit
