import os
from src.Stil import *

Circuit = "b14"

Current_Stil = os.path.join(
    "/gdsfs", "gdsfs", "yoshihara", "XID",
    Circuit,
    f"{Circuit}.stil"
)

Stil_Format_Path = os.path.join(
    "/gdsfs", "gdsfs", "yoshihara", "XID",
    "Stil_Format",
    f"{Circuit}_format.txt"
)

TP_Pair = parse_stil_from_file_1(Current_Stil)

CB_Partition(
    0,
    len(TP_Pair) - 1,
    TP_Pair,
    Stil_Format_Path,
    "test_all.stil"
)

print("done")
