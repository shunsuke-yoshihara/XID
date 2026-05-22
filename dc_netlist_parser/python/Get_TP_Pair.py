import os
import json
import io
import contextlib
from src.Stil import *

Circuit = "b14"
Partitioning_Stil_File = f"{Circuit}.stil"

Partitioning_Stil_File_Path = os.path.join(
    "/gdsfs", "gdsfs", "yoshihara", "XID",
    Circuit,
    Partitioning_Stil_File
)

# parse_stil_from_file_1 内部の print を捨てる
with contextlib.redirect_stdout(io.StringIO()):
    TP_Pair = parse_stil_from_file_1(Partitioning_Stil_File_Path)

# stdout には JSON だけ出す
print(json.dumps(TP_Pair, separators=(",", ":")))
