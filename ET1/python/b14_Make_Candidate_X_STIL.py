# =============================================================================
# Make_Candidate_X_STIL.py
#
# 【概要】
# ET1用STILが存在すればそれを読み込み、
# 存在しなければ元STILを読み込む。
# 指定された pattern番号 / test_si or pi / bit番号 に対して、
# 対象bitのみを N に変更した「候補1パターンSTIL」を生成する。
#
# 【用途】
# TetraMAX Tcl から以下のように呼び出す:
#
#   set stil_file [exec python3 python/b14_Make_Candidate_X_STIL.py 1 test_si 0]
#
# 戻り値:
#   候補STILファイルパス
#   または SKIP
# =============================================================================

import os
import sys
import io
import contextlib
from src.Stil import *

Circuit = "b14"

Original_Stil = os.path.join(
    "..",
    Circuit,
    f"{Circuit}.stil"
)

Current_Stil = os.path.join(
    Circuit,
    f"{Circuit}_ET1.stil"
)

Stil_Format_Path = os.path.join(
    "..",
    "Stil_Format",
    f"{Circuit}_format.txt"
)


def load_tp_pair():
    if os.path.exists(Current_Stil):
        input_stil = Current_Stil
    else:
        input_stil = Original_Stil

    if not os.path.exists(input_stil):
        print(f"Error: input STIL does not exist: {input_stil}", file=sys.stderr)
        sys.exit(1)

    with contextlib.redirect_stdout(io.StringIO()):
        TP_Pair = parse_stil_from_file_1(input_stil)

    return TP_Pair


def main():
    if len(sys.argv) != 4:
        print(
            "Usage: python3 b14_Make_Candidate_X_STIL.py <pattern_num> <test_si|pi> <bit_num>",
            file=sys.stderr
        )
        sys.exit(1)

    pattern_num = int(sys.argv[1])
    column_name = sys.argv[2]
    bit_num = int(sys.argv[3])

    if column_name == "test_si":
        col_idx = 0
    elif column_name == "pi":
        col_idx = 1
    else:
        print("Error: column_name must be test_si or pi", file=sys.stderr)
        sys.exit(1)

    TP_Pair = load_tp_pair()

    if pattern_num < 0 or pattern_num >= len(TP_Pair):
        print(f"Error: pattern_num out of range: {pattern_num}", file=sys.stderr)
        sys.exit(1)

    original_bits = TP_Pair[pattern_num][col_idx]

    if original_bits is None:
        print("SKIP")
        return

    if bit_num < 0 or bit_num >= len(original_bits):
        print(f"Error: bit_num out of range: {bit_num}", file=sys.stderr)
        sys.exit(1)

    if original_bits[bit_num] == "P":
        print("SKIP")
        return

    if original_bits[bit_num] == "N":
        print("SKIP")
        return

    candidate_bits = (
        original_bits[:bit_num]
        + "N"
        + original_bits[bit_num + 1:]
    )

    TP_Pair_x = list(TP_Pair)
    row = list(TP_Pair_x[pattern_num])
    row[col_idx] = candidate_bits
    TP_Pair_x[pattern_num] = tuple(row)

    output_dir = os.path.join(
        Circuit,
        "Partitioning_XID",
        str(pattern_num),
        column_name,
        str(bit_num)
    )

    os.makedirs(output_dir, exist_ok=True)

    output_stil = os.path.join(
        output_dir,
        f"{Circuit}_pn{pattern_num}_{bit_num}.stil"
    )

    CB_Partition(
        pattern_num,
        pattern_num,
        TP_Pair_x,
        Stil_Format_Path,
        output_stil
    )

    print(output_stil)


if __name__ == "__main__":
    main()
