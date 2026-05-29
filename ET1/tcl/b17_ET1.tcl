# ============================================================
# Time Profiling (ボトルネック解析用)
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
###############################################################
###############################################################


set CIRCUIT b17
#単純にビット数を指定(test_si ビットが$SI_BIT個ある)
set SI_BIT 1319
set PI_BIT 41

# Number of Pattrens
set PATTERNS 1952
set LAST_DT_FLT NONE
set DROPPED_FLT_FILES {}




# Read library
read_netlist -lib /home/csis/ohtake/cad/lib/TetraMAX/nangate45nm/nangate45nm.v

# Read scanned netlist
read_netlist ../${CIRCUIT}/_${CIRCUIT}.v

# Create the simulation model of the target module for ATPG
run_build_model ${CIRCUIT}

# Design rule check (ex: protocol file name = paulin.spf)
run_drc ../${CIRCUIT}/${CIRCUIT}.spf


# 途中から始める場合、パターン番号($PATTERNS)  からパターン番号($START_PATTERN - 1) までは、既処理であるので、検出故障リストに入れておく
for {set j $PATTERNS} {$j > $START_PATTERN} {incr j -1} {
  set LAST_DT_FLT ${CIRCUIT}/Partitioning_XID/$j/${CIRCUIT}_pn${j}_final_DT.flt
  lappend DROPPED_FLT_FILES $LAST_DT_FLT
}




# $START_PATTERN から処理を始め、 1パターン目まで順番に処理 (0パターン目は、Chain Test であるから無視)
for {set n $START_PATTERN} {$n >= 1} {incr n -1} {
  # 番兵
  set optimized_stil_file_per_pattern NONE

  # [SIビットを処理] 0ビット目から$SI_BIT 目まで順に処理
  for {set bit 0} {$bit < $SI_BIT} {incr bit} {

    # python処理1: b17_ET1.stil を読み込み、$n パタン目のtest_si の$bit 目を"N(don't care)"に変更したパターンを1パターンSTIL出力し、そのパスを返す(b17_ET1.stil は変更しない)
    set stil_file [timed_eval make_candidate_python {

      exec python3 python/${CIRCUIT}_Make_Candidate_X_STIL.py $n test_si $bit
    }]

    # $n パタン目のtest_si の$bit 目が、"P"や"N"の場合、文字列 "SKIP" を返す
    if {$stil_file == "SKIP"} {
        continue
    }

    # X化処理前パターンの$n パタン目で検出される故障リストを設定
    set fault_file ${CIRCUIT}/Partitioning_Flt_Dropping_DT/${CIRCUIT}_pn${n}_DT.flt

    # X化処理前パターンで検出した故障が0個の場合、故障シミュレーションを行うまでもなくX化可能
    if {[file size $fault_file] == 0} {
      puts stderr "XID_FLAG=1: empty DT fault file: $fault_file"

      # python処理2: b17_ET1.stil を読み込み、$n パターン目のtest_siの$bit 目を探し、"N"(don't care)に置換する
      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n test_si $bit
      }

      # $n パターン目の処理終了後の検出故障シミュレートをする際に使用するSTILを指定しておく
      set optimized_stil_file_per_pattern $stil_file

      #処理を抜け、次のビットor 次のパターンの処理へ
      continue
    }

    # set_patterns : python処理1 で出力した1パターンSTILを読み込み
    set_patterns -external $stil_file

    # read_faults : X化処理前パターンの$n パタン目で検出される故障リストを読み込み($n パターン目で検出を保証する)
    read_faults $fault_file

    timed_eval read_dropped_faults {
      # 前コマンドで読み込ませた故障の内、既処理パターン($PATTERNS から$n +1 のパターン)で検出できる故障は$nパターン目で検出保証する故障から除外(ビット数*パターン数 の回数読み込むので時間掛かってそう)
      foreach dropped_file $DROPPED_FLT_FILES {
        read_faults $dropped_file -delete
      }
    }


    # 残っている故障(既処理パターンでは検出できない)を保存するためのファイルを指定(判定用途、上書きでOK)
    set REMAIN_FLT ${CIRCUIT}/Partitioning_XID/$n/${CIRCUIT}_remain_pn$n.flt

    # 残っている故障を書き出す
    write_faults $REMAIN_FLT -all -replace

    # 残っている故障がない場合($nパターンで検出を保証すべきだった故障は、既処理パターンですべて検出可能)、故障シミュレーションを行うまでもなくX化可能
    if {[file size $REMAIN_FLT] == 0} {

      timed_eval apply_x_python {
        # python処理2: b17_ET1.stil を読み込み、$n パターン目のtest_siの$bit 目を探し、"N"(don't care)に置換する
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n test_si $bit
      }

      # $n パターン目の処理終了後の検出故障シミュレートをする際に使用するSTILを指定しておく
      set optimized_stil_file_per_pattern $stil_file

      #処理を抜け、次のビットor 次のパターンの処理へ
      continue
    }



    # Run simulation ($REMAIN_FLT を対象に、python処理1 で出力した1パターンSTILを使用してシミュレーション)
    timed_eval sim_total {

      run_simulation -sequential -update

      run_fault_sim -detected_pattern_storage
    }

    # Report Faults
    set_faults -fault_coverage
    report_faults -summary

    # $REMAIN_FLT の内、python処理1 で出力した1パターンSTILで、検出できた故障を書き出す
    timed_eval write_dt_faults {
      set X_DETECTED_FAULTS ${CIRCUIT}/Partitioning_XID/$n/test_si/$bit/${CIRCUIT}_pn${n}_${bit}_DT.flt
      write_faults $X_DETECTED_FAULTS -class DT -replace
    }

    # 故障リストのリセット
    remove_faults -all

    # X-Identification Check (XID_FLAG に判定結果を設定)
    set XID_FLAG [timed_eval compare_fault_list {

      # python処理3: $REMAIN_FLT と$X_DETECTED_FAULTS を比較し、と$REMAIN_FLT の故障が$X_DETECTED_FAULTS に含まれている場合"1"、そうでない場合"0"を返す
      exec python3 python/Compare_Fault_List.py \
      $X_DETECTED_FAULTS \
      $REMAIN_FLT
    }]


    # $XID_FLAG = 1 の場合
    if {$XID_FLAG == 1} {

      # python処理2: b17_ET1.stil を読み込み、$n パターン目のtest_siの$bit 目を探し、"N"(don't care)に置換する
      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n test_si $bit
      }

      # $n パターン目の処理終了後の検出故障シミュレートをする際に使用するSTILを指定しておく
        set optimized_stil_file_per_pattern $stil_file
    }
  }

################################################################################################################################################
############################################################################################# test_si の処理終了、piについても同様の処理を行う##
################################################################################################################################################


  # [PIビットを処理] 0ビット目から$PI_BIT 目まで順に処理
  for {set bit 0} {$bit < $PI_BIT} {incr bit} {

    # python処理1: b17_ET1.stil を読み込み、$n パタン目のpi の$bit 目を"N(don't care)"に変更したパターンを1パターンSTIL出力し、そのパスを返す(b17_ET1.stil は変更しない)
    set stil_file [timed_eval make_candidate_python {

      exec python3 python/${CIRCUIT}_Make_Candidate_X_STIL.py $n pi $bit
    }]


    # $n パタン目のpi の$bit 目が、"P"や"N"の場合、文字列 "SKIP" を返す
    if {$stil_file == "SKIP"} {
    continue
    }

    # X化処理前パターンの$n パタン目で検出される故障リストを設定
    set fault_file ${CIRCUIT}/Partitioning_Flt_Dropping_DT/${CIRCUIT}_pn${n}_DT.flt

    # X化処理前パターンで検出した故障が0個の場合、故障シミュレーションを行うまでもなくX化可能
    if {[file size $fault_file] == 0} {
      puts stderr "XID_FLAG=1: empty DT fault file: $fault_file"

      # python処理2: b17_ET1.stil を読み込み、$n パターン目のpiの$bit 目を探し、"N"(don't care)に置換する
      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n pi $bit
      }

      # $n パターン目の処理終了後の検出故障シミュレートをする際に使用するSTILを指定しておく
      set optimized_stil_file_per_pattern $stil_file

      #処理を抜け、次のビットor 次のパターンの処理へ
      continue
    }

    # set_patterns : python処理1 で出力した1パターンSTILを読み込み
    set_patterns -external $stil_file

    # read_faults : X化処理前パターンの$n パタン目で検出される故障リストを読み込み($n パターン目で検出を保証する)
    read_faults $fault_file


    timed_eval read_dropped_faults {
      # 前コマンドで読み込ませた故障の内、既処理パターン($PATTERNS から$n +1 のパターン)で検出できる故障は$nパターン目で検出保証する故障から除外
      foreach dropped_file $DROPPED_FLT_FILES {
        read_faults $dropped_file -delete
      }
    }

    # 残っている故障(既処理パターンでは検出できない)を保存するためのファイルを指定
    set REMAIN_FLT ${CIRCUIT}/Partitioning_XID/$n/${CIRCUIT}_remain_pn$n.flt

    # 残っている故障を書き出す
    write_faults $REMAIN_FLT -all -replace

    # 残っている故障がない場合($nパターンで検出を保証すべきだった故障は、既処理パターンですべて検出可能)、故障シミュレーションを行うまでもなくX化可能
    if {[file size $REMAIN_FLT] == 0} {

        # python処理2: b17_ET1.stil を読み込み、$n パターン目のpiの$bit 目を探し、"N"(don't care)に置換する
      timed_eval apply_x_python {
        exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n pi $bit
      }

      # $n パターン目の処理終了後の検出故障シミュレートをする際に使用するSTILを指定しておく
      set optimized_stil_file_per_pattern $stil_file

      #処理を抜け、次のビットor 次のパターンの処理へ
      continue
    }



    # Run simulation ($REMAIN_FLT を対象に、python処理1 で出力した1パターンSTILを使用してシミュレーション)
    timed_eval sim_total {

      run_simulation -sequential -update

      run_fault_sim -detected_pattern_storage
    }

    # Report Faults
    set_faults -fault_coverage
    report_faults -summary


    # $REMAIN_FLT の内、検出できた故障を書き出す
    timed_eval write_dt_faults {
      set X_DETECTED_FAULTS ${CIRCUIT}/Partitioning_XID/$n/pi/$bit/${CIRCUIT}_pn${n}_${bit}_DT.flt
      write_faults $X_DETECTED_FAULTS -class DT -replace
    }


    # 故障リストのリセット
    remove_faults -all

    #X Identification Check (XID_FLAG に判定結果を設定)
    set XID_FLAG [timed_eval compare_fault_list {

      # python処理3: $REMAIN_FLT と$X_DETECTED_FAULTS を比較し、と$REMAIN_FLT の故障が$X_DETECTED_FAULTS に含まれている場合"1"、そうでない場合"0"を返す
      exec python3 python/Compare_Fault_List.py \
      $X_DETECTED_FAULTS \
      $REMAIN_FLT
    }]



    # $XID_FLAG = 1 の場合
    if {$XID_FLAG == 1} {

        # python処理2: b17_ET1.stil を読み込み、$n パターン目のpiの$bit 目を探し、"N"(don't care)に置換する
        timed_eval apply_x_python {
          exec python3 python/${CIRCUIT}_Apply_X_To_Current_STIL.py $n pi $bit
        }
        # $n パターン目の処理終了後の検出故障シミュレートをする際に使用するSTILを指定しておく
        set optimized_stil_file_per_pattern $stil_file
    }
  }


################################################################################################################################################
############################################################################################# pi の処理終了#####################################
################################################################################################################################################

####################################
#以下、1パターン終了毎に実行される
####################################


# 全故障を追加(改善の余地あり、$DROPPED_FLT_FILES の中の各Flt の故障の重複は避けなければ実行が長くなる可能性大)
  add_faults -all

  # 番兵がいた場合(1ビットもXに更新されていない)
  if {$optimized_stil_file_per_pattern == "NONE"} {
    puts stderr "ERROR: no optimized STIL selected for pattern $n"
    exit 1
  }

  # X化処理後の1パターンSTILを読み込ませる
  set_patterns -external $optimized_stil_file_per_pattern

  # Run simulation (全故障に対して、X化処理後の1パターンSTILで故障シミュレーション)
  timed_eval sim_total {

    run_simulation -sequential -update

    run_fault_sim -detected_pattern_storage
  }


  # Report Faults
  set_faults -fault_coverage
  report_faults -summary

  # 全故障に対して、X化処理後の1パターンSTILで検出できる故障を書き出す ( $LAST_DT_FLT )
  set LAST_DT_FLT ${CIRCUIT}/Partitioning_XID/$n/${CIRCUIT}_pn${n}_final_DT.flt
  timed_eval write_dt_faults {
    write_faults $LAST_DT_FLT -class DT -replace
  }

  # $LAST_DT_FLT に含まれる故障は、以降のパターンの処理では、検出を保証しなくて良い
  # 検出を保証しなくてもよい故障をDROPPED_FLT_FILES に入れておく
  lappend DROPPED_FLT_FILES $LAST_DT_FLT

  #故障リストのリセット
  remove_faults -all

}




#####################################################
# 計測結果
#####################################################
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

####################################################





report_summaries cpu_usage
quit
