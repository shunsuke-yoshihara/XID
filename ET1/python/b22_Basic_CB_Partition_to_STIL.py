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
Circuit = "b22"
Partitioning_Stil_File = f"{Circuit}.stil"
Stil_Format = f"{Circuit}_format.txt"
Output_Stil_File = f"{Circuit}_pn"
##############################################################

Partitioning_Stil_File_Path = os.path.join("..", Circuit,  Partitioning_Stil_File)
Stil_Format_Path = os.path.join("..", "Stil_Format", Stil_Format)
Output_Stil_File_Path = os.path.join(Circuit, "Partitioning_Stil")

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
for n in range (0, len(TP_Pair)) :
  if(n % 500 == 0):
    print(n ,"pattern ended.")
  After_Partition_file = f"{Output_Stil_File_Path}/{Output_Stil_File}{n}.stil"
  CB_Partition(n, n, TP_Pair, Stil_Format_Path, After_Partition_file)

