


############## Define Circuit Parts(LIST) ####################
set LIST_PI_PORTS  [get_object_name [all_inputs]]
set LIST_PO_PORTS  [get_object_name [all_outputs]]
set LIST_SEQ_CELLS [get_object_name [get_cells -hier -filter "is_sequential==true"]]
set LIST_COMB_CELLS [get_object_name [get_cells -hier -filter "is_combinational==true"]]
set LIST_SEQ_PINS [get_object_name [get_pins -of_objects $LIST_SEQ_CELLS]]
set LIST_SEQ_PINS_IN [get_object_name [get_pins -of_objects $LIST_SEQ_CELLS -filter "direction==in"]]
set LIST_SEQ_PINS_OUT [get_object_name [get_pins -of_objects $LIST_SEQ_CELLS -filter "direction==out"]]
set LIST_ALL_PINS [get_object_name [get_pins  *]]
set LIST_ALL_CELLS [get_object_name [get_cells  *]]
#Include PIO Ports
set LIST_ALL_NETS [get_object_name [get_nets -hier *]]
##############################################################

############## Define Circuit Parts(COLLECTION) ##############
set COLLECTION_PI_PORTS  [all_inputs]
set COLLECTION_PO_PORTS  [all_outputs]
set COLLECTION_COMB_CELLS [get_cells -hier -filter "is_combinational==true"]
set COLLECTION_SEQ_CELLS [get_cells -hier -filter "is_sequential==true"]
set COLLECTION_SEQ_PINS [get_pins -of_objects $LIST_SEQ_CELLS]
set COLLECTION_SEQ_PINS_IN [get_pins -of_objects $LIST_SEQ_CELLS -filter "direction==in"]
set COLLECTION_SEQ_PINS_OUT [get_pins -of_objects $LIST_SEQ_CELLS -filter "direction==out"]
set COLLECTION_ALL_PINS [get_pins  *]
set COLLECTION_ALL_CELLS [get_cells  *]
set COLLECTION_ALL_NETS [get_nets -hier *]
##############################################################


############## Define Circuit Parts Length ###################
set NUMOF_PI_PORTS  [llength [get_object_name [all_inputs]]]
set NUMOF_PO_PORTS [llength [get_object_name [all_outputs]]]
set NUMOF_COMB_CELLS [llength [get_object_name [get_cells -hier -filter "is_combinational==true"]]]
set NUMOF_SEQ_CELLS [llength [get_object_name [get_cells -hier -filter "is_sequential==true"]]]
set NUMOF_SEQ_PINS [llength [get_object_name [get_pins -of_objects $LIST_SEQ_CELLS]]]
set NUMOF_SEQ_PINS_IN [llength [get_object_name [get_pins -of_objects $LIST_SEQ_CELLS -filter "direction==in"]]]
set NUMOF_SEQ_PINS_OUT [llength [get_object_name [get_pins -of_objects $LIST_SEQ_CELLS -filter "direction==out"]]]
set NUMOF_ALL_PINS [llength [get_object_name [get_pins  *]]]
set NUMOF_ALL_CELLS [llength [get_object_name [get_cells  *]]]
set NUMOF_ALL_NETS [llength [get_object_name [get_nets -hier *]]]
##############################################################



proc coll_to_name_list {coll} {
    set lst {}
    foreach_in_collection obj $coll {
        lappend lst [get_object_name $obj]
    }
    return $lst
}


proc lappend_unique {varname value} {
    upvar 1 $varname var
    if {[lsearch -exact $var $value] < 0} {
        lappend var $value
    }
}


proc is_comb_cell {cell_obj} {
    set is_comb [get_attribute $cell_obj is_combinational]
    set is_seq  [get_attribute $cell_obj is_sequential]

    if {$is_comb == "true" && $is_seq != "true"} {
        return 1
    }
    return 0
}

proc is_seq_cell {cell_obj} {
    set is_seq [get_attribute $cell_obj is_sequential]
    if {$is_seq == "true"} {
        return 1
    }
    return 0
}




#############################################
# is_pi_net {net}
#   * $net が、PIであるか判定するProc
#
#   * 入力：
#     　回路のnet (PI or wire を想定)
#
#   * 出力：
#       1 : PIである
#       0 : PIでない
#
#############################################

proc is_pi_net {net} {
  set ports [get_ports -of_objects [get_nets $net] -filter "direction==in"]
  if {[sizeof_collection $ports] > 0} {
    return 1
  }
  return 0
}






#############################################
# is_ppi_net {net}
#   * $net が、FF/Q, FF/QN に接続されているか判定するProc
#
#   * 入力：
#     　回路のnet (PI or wire を想定)
#
#   * 出力：
#       1 : FF/Q, FF/QN に接続されている
#       0 : FF/Q, FF/QN に接続されていない
#
#############################################

proc is_ppi_net {net} {

  # net に接続されている出力側pin を検索
  set drv_pins [get_pins -of_objects [get_nets $net] -filter "direction==out"]


  foreach_in_collection pin $drv_pins {
    #対象pinに接続されているcell を検索
    set cell [get_cells -of_objects $pin]
    if {[sizeof_collection $cell] > 0} {
      #そのセルが順序セルか判定
      set is_seq [get_attribute $cell is_sequential]
      if {$is_seq == "true"} {
        return 1
      }
    }
  }
  return 0
}







#############################################
# is_inv_buf {cell}
#   * $cell が、INVまたはBUFであるか判定するProc
#
#   * 入力：
#     cell (組合せセルを想定)
#
#   * 出力：
#       1 : INV, BUFである
#       0 : INV, BUFでない
#
#############################################


# INV/BUFセル判定
proc is_inv_buf {cell} {
  set ref [get_attribute $cell ref_name]

  #正規表現で大文字小文字を区別せずにINVまたはBUFから始まるセルであった場合、1を返す
  if {[regexp -nocase {^(INV|BUF)} $ref]} {
    return 1
  }

  return 0
}






#############################################
# get_load_pin {net}
#
#   * 指定した netを入力として読み込んでいるピン を取得するProc
#
#   * 入力：
#       net
#         - 回路中の net 名(PIO,wireを想定)
#
#   * 出力：
#	netを読み込んでいるピン
#
#############################################

proc get_load_pin {net} {

    set list_input_pin [get_object_name \
        [get_pins -of_objects [get_nets $net] \
        -filter "pin_direction == in"]]

    return $list_input_pin
}



#############################################
# get_driver_pin {net}
#
#   * 指定した netを駆動しているピン を取得するProc
#
#   * 入力：
#       net
#         - 回路中の net 名
#
#   * 出力：
#       netを駆動しているピン
#
#############################################

proc get_driver_pin {net} {

    set list_driver_pin [get_object_name \
        [get_pins -of_objects [get_nets $net] \
        -filter "pin_direction == out"]]

    return $list_driver_pin
}

