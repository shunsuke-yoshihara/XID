# 実行前に必要な処理

`pon_XID.tcsh` を以下のディレクトリに作成すること。

tcsh pon_XID.tcsh で実行可能。

```text
/gdsfs/gdsfs/yoshihara/XID/dc_netlist_parser/script/
```

ファイル内容:

```tcsh
# NETLIST Parser
# Design Compiler Setup
source /gdsfs/gdsfs/cad/env/syn/U-2022.12.env
#ln -s ~ohtake/cad/env/.synopsys_dc.setup .
#mkdir work

#Define Value
echo "Define Value"
set XID=../tcl/X_Identification.tcl
set CIRCUIT=b14
echo "Define Value : OK"

# Time Stamp
setenv TIMESTAMP `date +%m%d%H%M`

# Call Design Compiler
echo "Call Design Compiler"
dc_shell -64 -f ${XID} > ../report/${CIRCUIT}/dc/XID_${TIMESTAMP}.log
echo "End of Netlist Parse"
```


実行前 に以下のディレクトリを作成のこと。

以下のディレクトリに時刻付きでログが格納される。

```text
/gdsfs/gdsfs/yoshihara/XID/dc_netlist_parser/report/${回路名}/dc/
```


# 各関数の動作確認
## tcl/src/utility.tcl
### get_load_pin {net}
サンプル回路 : b15
```text
AND4_X2 U1739 ( .A1(n2276), .A2(n2279), .A3(n1290), .A4(NA_n), .ZN(n2281) );
OAI21_X2 U3907 ( .B1(NA_n), .B2(n3929), .A(n2274), .ZN(n2280) );
SDFFR_X2 uWord_reg_14_ ( .D(n3857), .SI(n4132), .SE(test_se), .CK(CLOCK), .RN(n3798), .Q(uWord[14]), .QN(test_so) );
```
実行結果  
1. net が、外部入力、どこかの入力になっている外部出力の場合
2. net が、wireである場合
3. net が、どの入力ピンにも入っていない外部出力の場合

```text
dc_shell> puts [get_load_pin NA_n]  #1
U3907/B1 U1739/A4
dc_shell>
dc_shell> puts [get_load_pin n3857] #2
uWord_reg_14_/D
dc_shell>
dc_shell> puts [get_load_pin test_so] #3

dc_shell>
```



### get_driver_pin {net}
サンプル回路 : b15
```text
assign Datao[31] = 1'b0;
AND4_X2 U1739 ( .A1(n2276), .A2(n2279), .A3(n1290), .A4(NA_n), .ZN(n2281) );
OAI21_X2 U3907 ( .B1(NA_n), .B2(n3929), .A(n2274), .ZN(n2280) );
SDFFR_X2 uWord_reg_14_ ( .D(n3857), .SI(n4132), .SE(test_se), .CK(CLOCK), .RN(n3798), .Q(uWord[14]), .QN(test_so) );
FA_X1 dp_cluster_2_add_2_root_add_402_7_U1_24 ( .A(N2885), .B(1'b0), 
        .CI(dp_cluster_2_add_2_root_add_402_7_carry[24]),
        .CO(dp_cluster_2_add_2_root_add_402_7_carry[25]),
        .S(dp_cluster_2_N3299) );
```
実行結果
1. net が、外部入力である場合
2. net が、wireである場合
3. net が、外部出力である場合
4. net が、定数論理である場合

```text
dc_shell> puts [get_driver_pin test_se]

dc_shell>
dc_shell> puts [get_driver_pin n2280]
U3907/ZN
dc_shell>
dc_shell> puts [get_driver_pin test_so]
uWord_reg_14_/QN
dc_shell>
dc_shell> puts [get_driver_pin Datao[31]]
Logic0/**logic_0**
dc_shell>
```


# 実行手順
1. STILを分割し、1パターン/1STILファイルに変形

```text
% cd dc_netlist_parser
% python3 python/b14_Basic_CB_Partition_to_STIL.py
```

2. 分割後のSTILを使用して、1パターンごとのテストベンチ作成

```text
% cd dc_netlist_parser
% mkdir -p b14/Partitioning_Stil_Testbench
% set pattern = 0
# 663 には、STILファイル数+1 を使用(0から番号付けされているため)
% while ( $pattern <= 663 )
while? stil2verilog b14/Partitioning_Stil/b14_pn${pattern}.stil b14/Partitioning_Stil_Testbench/b14_pn${pattern}_tb
while? @ pattern++
while? end



3. 論理シミュレーションから取得したい内部論理値を決める

```text
# 出力先は、b14/b14_signal_list.txt
% cd dc_netlist_parser
% dc_shell
dc_shell> source tcl/src/write_signal_list.tcl
dc_shell> read_verilog ../b14/_b14.v
dc_shell> write_signal_list b14/b14_signal_list.txt
```


4. パターンごとの正常値論理シミュレーション

```text
% cd dc_netlist_parser
% mkdir -p b14/Partitioning_Stil_Testbench_VCD
% set pattern = 0

# 663 には、STILファイル数+1 を使用(0から番号付けされているため)
% while ( $pattern <= 663 )

# Verilog コンパイルコマンド 
# - b14_pn1_tb.v : STIL2Verilog が生成した testbench
# - b14_dump.v : VCD dump 用 module
while? vlogan -full64 b14/Partitioning_Stil_Testbench/b14_pn${pattern}_tb.v ../b14/_b14.v b14/b14_dump.v -v library ~ohtake/cad/lib/Synthesis/nangate45nm.v

# simulation executable生成
# - b14_test : STIL2Verilog が生成した testbench module
# - b14_dump : VCD dump module
while? vcs -full64 -debug_all b14_test b14_dump 
while? ./simv +VCD=b14/Partitioning_Stil_Testbench_VCD/b14_pn${pattern}.vcd
while? rm -rf simv simv.daidir csrc ucli.key AN.DB
while? @ pattern++
while? end 
```




3. STILファイル数を指定し、1パタン毎の故障シミュレーションを実行

```text
# 出力先は、/gdsfs/gdsfs/yoshihara/XID/b14/${Partitioning_Flt}
% cd b14
% tmax -shell b14_FaultSim_Per_Pattern.tmx > b14_FaultSim_Per_Pattern.tmx.log
```
