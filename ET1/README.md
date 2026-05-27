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



# ヒューリスティックによるケアビットの削減

## 概要

ATPG により生成された X 含みテストパターンに対して、
ヒューリスティックにケアビット削減を行うフローを示す。

- パターンを逆順に処理
- 各ビットを `X` 化可能か故障シミュレーションで判定
- 検出故障集合 (DT Faults) が変化しない場合のみ更新
- 最終的な Dropped Faults を更新しながら全パターンへ適用

---

# フローチャート

```mermaid
flowchart TD

%% =========================
%% 左側：初期DT故障集合取得
%% =========================

A([開始]) --> B[ATPGによりX無しテスト生成<br/>(0100010011110101010)]

B --> C[i ≠ 0 パターン目の<br/>DT故障集合 A_i を取得]

C --> D[故障 A_i を落とす]

D --> E[i++]

E --> F{最終パタン到達?}

F -- No --> C
F -- Yes --> G([終了])

%% =========================
%% 右側：ケアビット削減
%% =========================

subgraph Heuristic_CareBit_Reduction
    H[iパターン目のjビット目をXに変更し<br/>iパターン目のみ記述されたSTILを作成]

    H --> I[故障集合 A_i - Dropped Faults に対して<br/>故障シミュレーションし<br/>DT故障集合 A_i' を取得]

    I --> J{A_i - Dropped Faults == A_i'?}

    J -- Yes --> K[全パターンが記述されたSTILの<br/>iパターン目のjビット目をXに更新]

    K --> L[j++]

    J -- No --> L

    L --> M{最終ビット到達?}

    M -- No --> H

    M -- Yes --> N[最適化されたiパターン目を使用して<br/>全故障に対して故障シミュレーションし<br/>DT故障集合をDropped Faultsに追加]

    N --> O[i--]

    O --> P{最終パタン未到達?}

    P -- No --> H
end

