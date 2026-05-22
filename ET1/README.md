# ET1 の説明

# 使用方法
1. ATPGが生成したSTILを分割し、1パターン/1STILファイルに変形

```text
# 出力先は、${Circuit}/${Partitioning_Stil_File_Path}
% cd ET1
% python3 python/b14_Basic_CB_Partition_to_STIL.py
```


2. STIL分割したテストパターンに対し、生成順にドロッピング故障シミュレーションを行い、  
各パターンのDS故障(= `-detected_pattern_strage` でパタン番号が出る故障)を特定する。 

```text
% cd ET1
% tmax -shell b14/b14_FaultSim_Per_Patetrn_Dropping.tmx > b14/b14_FaultSim_Per_Patetrn_Dropping.tmx.log
```


```text
% cd ET1
% tmax -shell tcl/b14_ET1.tcl > tcl/b14_ET1.tcl.log
```
