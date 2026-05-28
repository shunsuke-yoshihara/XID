# ============================================================
# Time Profiling
# ============================================================

array set TIME_SUM {
  apply_x_python 0
  make_candidate_python 0
  read_dropped_faults 0
  sim_total 0
  write_dt_faults 0
  compare_fault_list 0
}

proc timed_eval {key script} {

  global TIME_SUM

  set t0 [clock milliseconds]

  set ret [uplevel 1 $script]

  set t1 [clock milliseconds]

  incr TIME_SUM($key) [expr {$t1 - $t0}]

  return $ret
}



set CIRCUIT b14
#単純にビット数を指定(test_si ビットが$SI_BIT個ある)
set SI_BIT 215
set PI_BIT 36

# Number of Pattrens
set PATTERNS 663
set START_PATTERNS 59
set LAST_DT_FLT NONE
set DROPPED_FLT_FILES {}


#exec rm -f ${CIRCUIT}/${CIRCUIT}_ET1.stil

# Read library
read_netlist -lib /home/csis/ohtake/cad/lib/TetraMAX/nangate45nm/nangate45nm.v

## Read scanned netlist (ex: netlist file name = paulin_scan.v)
read_netlist ../${CIRCUIT}/_${CIRCUIT}.v

# Create the simulation model of the target module for ATPG
# (ex: module name = paulin)
run_build_model ${CIRCUIT}

# Design rule check (ex: protocol file name = paulin.spf)
run_drc ../${CIRCUIT}/${CIRCUIT}.spf


for {set j $PATTERNS} {$j > $START_PATTERNS} {incr j -1} {
  set LAST_DT_FLT ${CIRCUIT}/Partitioning_XID/$j/${CIRCUIT}_pn${j}_final_DT.flt
  if {[file exists $LAST_DT_FLT]} {
    lappend DROPPED_FLT_FILES $LAST_DT_FLT
  }
}




# 1パターン- $Patterns パターン(0パターン目は、Chain Test)
for {set n $START_PATTERNS} {$n >= 1} {incr n -1} {
  set optimized_stil_file_per_pattern NONE

  for {set bit 0} {$bit < $SI_BIT} {incr bit} {

    set stil_file [timed_eval make_candidate_python {

      exec python3 python/${CIRCUIT}_Make_Candidate_X_STIL.py $n test_si $bit
    }]


    if {$stil_file == "SKIP"} {
        continue
    }

    set fault_file ${CIRCUIT}/Partitioning_Flt_Dropping_DT/${CIRCUIT}_pn${n}_DT.flt

    # 元パターンで検出した故障が0個の場合、故障シミュレーションを行う必要はない(X化可能)
    if {[file size $fault_file] == 0} {
      puts stderr "XID_FLAG=1: empty DT fault file: $fault_file"

      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n test_si $bit
      }

      set optimized_stil_file_per_pattern $stil_file
      continue
    }

    #set_patterns -external ${CIRCUIT}/Partitioning_XID/$n/test_si/$bit/${CIRCUIT}_pn${n}_$bit.stil
    set_patterns -external $stil_file

    read_faults $fault_file

    timed_eval read_dropped_faults {
      foreach dropped_file $DROPPED_FLT_FILES {
        read_faults $dropped_file -delete
      }
    }


    set TMP_FLT ${CIRCUIT}/Partitioning_XID/$n/${CIRCUIT}_remain_pn$n.flt
    write_faults $TMP_FLT -all -replace

    if {[file size $TMP_FLT] == 0} {

      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n test_si $bit
      }

      set optimized_stil_file_per_pattern $stil_file
      continue
    }



    # Run simulation
    timed_eval sim_total {

      run_simulation -sequential -update

      run_fault_sim -detected_pattern_storage
    }

    # Report Faults
    set_faults -fault_coverage
    report_faults -summary

    # Write Fault List

    timed_eval write_dt_faults {
      write_faults ${CIRCUIT}/Partitioning_XID/$n/test_si/$bit/${CIRCUIT}_pn${n}_${bit}_DT.flt -class DT -replace
    }

    #write_faults ${CIRCUIT}/Partitioning_XID/$n/test_si/$bit/${CIRCUIT}_pn${n}_${bit}_ND.flt -class ND -replace
    #write_faults ${CIRCUIT}/Partitioning_XID/$n/test_si/$bit/${CIRCUIT}_pn${n}_${bit}.flt -all -replace
    remove_faults -all

    #X Identification Check
    set XID_FLAG [timed_eval compare_fault_list {

      exec python3 python/Compare_Fault_List.py \
      ${CIRCUIT}/Partitioning_XID/$n/test_si/$bit/${CIRCUIT}_pn${n}_${bit}_DT.flt \
      $TMP_FLT
    }]



    if {$XID_FLAG == 1} {

      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n test_si $bit
      }

        set optimized_stil_file_per_pattern $stil_file
    }
  }




  for {set bit 0} {$bit < $PI_BIT} {incr bit} {

    set stil_file [timed_eval make_candidate_python {

      exec python3 python/${CIRCUIT}_Make_Candidate_X_STIL.py $n pi $bit
    }]


    if {$stil_file == "SKIP"} {
    continue
    }


    set fault_file ${CIRCUIT}/Partitioning_Flt_Dropping_DT/${CIRCUIT}_pn${n}_DT.flt

    # 元パターンで検出した故障が0個の場合、故障シミュレーションを行う必要はない(X化可能)
    if {[file size $fault_file] == 0} {
      puts stderr "XID_FLAG=1: empty DT fault file: $fault_file"

      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n pi $bit
      }

      set optimized_stil_file_per_pattern $stil_file
      continue
    }

    #set_patterns -external ${CIRCUIT}/Partitioning_XID/$n/pi/$bit/${CIRCUIT}_pn${n}_$bit.stil
    set_patterns -external $stil_file

    read_faults $fault_file

    timed_eval read_dropped_faults {
      foreach dropped_file $DROPPED_FLT_FILES {
        read_faults $dropped_file -delete
      }
    }

    set TMP_FLT ${CIRCUIT}/Partitioning_XID/$n/${CIRCUIT}_remain_pn$n.flt
    write_faults $TMP_FLT -all -replace

    if {[file size $TMP_FLT] == 0} {

      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n pi $bit
      }

      set optimized_stil_file_per_pattern $stil_file
      continue
    }



    # Run simulation
    timed_eval sim_total {

      run_simulation -sequential -update

      run_fault_sim -detected_pattern_storage
    }

    # Report Faults
    set_faults -fault_coverage
    report_faults -summary

    # Write Fault List

    timed_eval write_dt_faults {
      write_faults ${CIRCUIT}/Partitioning_XID/$n/pi/$bit/${CIRCUIT}_pn${n}_${bit}_DT.flt -class DT -replace
    }

    #write_faults ${CIRCUIT}/Partitioning_XID/$n/pi/$bit/${CIRCUIT}_pn${n}_${bit}_ND.flt -class ND -replace
    #write_faults ${CIRCUIT}/Partitioning_XID/$n/pi/$bit/${CIRCUIT}_pn${n}_${bit}.flt -all -replace

    #X Identification Check
    set XID_FLAG [timed_eval compare_fault_list {

      exec python3 python/Compare_Fault_List.py \
      ${CIRCUIT}/Partitioning_XID/$n/pi/$bit/${CIRCUIT}_pn${n}_${bit}_DT.flt \
      $TMP_FLT
    }]

    remove_faults -all

    if {$XID_FLAG == 1} {

        timed_eval apply_x_python {
          exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n pi $bit
        }

        set optimized_stil_file_per_pattern $stil_file
    }
  }


  add_faults -all

  if {$optimized_stil_file_per_pattern == "NONE"} {
    puts stderr "ERROR: no optimized STIL selected for pattern $n"
    exit 1
  }

  set_patterns -external $optimized_stil_file_per_pattern
  # Run simulation
  timed_eval sim_total {

    run_simulation -sequential -update

    run_fault_sim -detected_pattern_storage
  }


  # Report Faults
  set_faults -fault_coverage
  report_faults -summary

  # Write Fault List
  set LAST_DT_FLT ${CIRCUIT}/Partitioning_XID/$n/${CIRCUIT}_pn${n}_final_DT.flt

  timed_eval write_dt_faults {
    write_faults $LAST_DT_FLT -class DT -replace
  }

  lappend DROPPED_FLT_FILES $LAST_DT_FLT
  remove_faults -all

}



puts stderr ""
puts stderr "========================================"
puts stderr " Accumulated Time Summary"
puts stderr "========================================"

foreach key [lsort [array names TIME_SUM]] {
  puts stderr [format \
    "%-25s %12d ms  %10.2f sec  %8.2f min" \
    $key \
    $TIME_SUM($key) \
    [expr {$TIME_SUM($key) / 1000.0}] \
    [expr {$TIME_SUM($key) / 60000.0}]
  ]
}







report_summaries cpu_usage
quit
