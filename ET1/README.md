# 使用方法
1. ATPGが生成したSTILを分割し、1パターン/1STILファイルに変形

```text
# 出力先は、${Circuit}/${Partitioning_Stil_File_Path}
% cd ET1
% python3 python/b14_Basic_CB_Partition_to_STIL.py
```


2. STIL分割したテストパターンに対し、パターン生成順にドロッピング故障シミュレーションを行い、
各パターンのDT故障を特定する。
(= `-detected_pattern_strage` でパタン番号が出る故障は、DS故障だが、1パターン目でDI故障は落ちるので問題ない) 
(下図のフローチャートの左側の処理)

```text
% cd ET1
% tmax -shell b14/b14_FaultSim_Per_Patetrn_Dropping.tmx > b14/b14_FaultSim_Per_Patetrn_Dropping.tmx.log
```


3. 下図のフローチャートで、右側に示す処理をTetraMAX上で実行
```text
% cd ET1
% nohup tmax -shell tcl/b14_ET1.tcl > tcl/b14_ET1.tcl.log 2>&1 &
```



# ET1. ヒューリスティックによるケアビットの削減

## 概要

ATPG により生成された X 無テストパターンに対して、
ヒューリスティックにケアビット削減を行うフローを示す。

- パターンを逆順に処理
- 各ビットを `X` 化可能か故障シミュレーションで判定
- 元パターンでの検出故障集合の検出が確認できる場合のみXに更新
- ```Xに更新されたパターンで検出保証されていないが、検出される他の故障```は以降のパターンでは、検出保証故障に含めない(当該パターンで検出出来ることを確認しているため)
(1パターンずつ確認)
- ★が最終的な出力ファイル

---

# フローチャート

```mermaid
flowchart TD
A((開始)) --> B["ATPGにより<br/>X無しテスト生成<br/>0100010011110101010"]
B --> C["i ≠ 0 パターン目の<br/>DT故障集合 A_i を取得"]
C --> D["故障 A_i を落とす"]
D --> E["i++"]
E --> F{"最終パタン到達?"}
F -- No --> C
F -- Yes --> G((終了))

B --> H["iパターン目のjビット目をXに変更し<br/>iパターン目のみ記述されたSTILを作成<br/>(同パタンのX変更状況は反映する)"]
H --> I["故障集合 A_i - Dropped Faults に対して<br/>故障シミュレーションし<br/>DT故障集合 A_i' を取得"]
I --> J{"A_i - Dropped Faults = A_i' ?"}
J -- Yes --> K["全パターンが記述されたSTIL★の<br/>iパターン目のjビット目をXに更新"]
J -- No --> L["j++"]
K --> L
L --> M{"最終ビット到達?"}
M -- No --> H
M -- Yes --> N["最適化されたiパターン目を使用して<br/>全故障に対して<br/>故障シミュレーションし<br/>DT故障集合を<br/>Dropped Faultsに追加"]
N --> O["i--"]
O --> P{"最終パタン未到達?"}
P -- Yes --> H
P -- No --> Q((終了))

