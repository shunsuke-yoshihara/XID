# %%
import os
import matplotlib.pyplot as plt
from src.Stil import *

# %%
#####################################################################################################
# 1パターンごとにSTILファイルを分割して、STILファイル形式にするスクリプト
# Partitioning_Stil_File : 分割元STILファイル
# Stil_format : 各回路のStilの信号定義部など書かれたフォーマットとなるテキストファイル(1回路構成につき1フォーマット)
# Output_Stil_File : stilをNパターンごとに書き出す際の、ファイル名固定部
#####################################################################################################

##############################################################
Circuit = "b14"
Partitioning_Stil_File = f"{Circuit}.stil"
Stil_Format = f"{Circuit}_format.txt"
Output_Stil_File = f"{Circuit}_pn"
##############################################################

Partitioning_Stil_File_Path = os.path.join("/gdsfs", "gdsfs", "yoshihara", "XID", Circuit,  Partitioning_Stil_File)
Stil_Format_Path = os.path.join("/gdsfs", "gdsfs", "yoshihara", "XID", "Stil_Format", Stil_Format)
Output_Stil_File_Path = os.path.join("/gdsfs", "gdsfs", "yoshihara", "XID", Circuit, "Partitioning_Stil")

print(f"分割元Stil : {Partitioning_Stil_File}\n"
      f"分割元Stilファイルパス :  {Partitioning_Stil_File_Path}\n"
      f"Stilファイルフォーマット : {Stil_Format}\n"
      f"分割後出力STILファイル名 : {Output_Stil_File}(X).stil\n"
      f"分割後出力STILファイルディレクトリ：{Output_Stil_File_Path}"
      )



# %%
TP_Pair = parse_stil_from_file_1(Partitioning_Stil_File_Path)
print(f"テストパタン数 : {len(TP_Pair)}")
print(f"0パタン目 : {TP_Pair[0]}")
print(f"最終パタン : {TP_Pair[len(TP_Pair) - 1]}")



# %%
os.makedirs(Output_Stil_File_Path, exist_ok=True)

# 反転対象列
# 0列目 -> test_si
# 1列目 -> pi
target_columns = {
    0: "test_si",
    1: "pi",
}

for pattern_num in range(0, len(TP_Pair)):

    if(pattern_num % 500 == 0):
        print(pattern_num, "pattern ended.")

    for col_idx, column_name in target_columns.items():

        original_bits = TP_Pair[pattern_num][col_idx]

        # None対策
        if original_bits is None:
            print(f"[Warning] pattern {pattern_num}, {column_name} is None. skipped.")
            continue

        # 各ビットを1bitずつ反転
        for bit_num in range(len(original_bits)):

            bit = original_bits[bit_num]

            # 0/1以外(P,N,Xなど)は反転対象外
            if bit not in ("0", "1"):
                continue

            # 1bit反転
            flipped_bit = "1" if bit == "0" else "0"

            flipped_bits = (
                original_bits[:bit_num]
                + flipped_bit
                + original_bits[bit_num + 1:]
            )

            # TP_Pairをコピー
            TP_Pair_flip = list(TP_Pair)

            # tuple -> list に変換
            row = list(TP_Pair_flip[pattern_num])

            # 対象列だけ変更
            row[col_idx] = flipped_bits

            # tuple に戻す
            TP_Pair_flip[pattern_num] = tuple(row)

            # 出力ディレクトリ
            output_dir = os.path.join(
                "/gdsfs",
                "gdsfs",
                "yoshihara",
                "XID",
                Circuit,
                "XID_Reverce_Order_FaultSim",
                str(pattern_num),
                column_name,
                str(bit_num)
            )

            # ディレクトリ自動生成
            os.makedirs(output_dir, exist_ok=True)

            # 出力ファイル名
            After_Partition_file = os.path.join(
                output_dir,
                f"{Circuit}_pn{pattern_num}_{bit_num}.stil"
            )

            # STIL出力
            CB_Partition(
                pattern_num,
                pattern_num,
                TP_Pair_flip,
                Stil_Format_Path,
                After_Partition_file
            )
