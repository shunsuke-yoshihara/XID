# Compare_Fault_List.py

import sys
import os


def load_faults(fault_file):
    """
    fault list ファイルを読み込み、
    各故障を (縮退故障種別, 故障箇所) の tuple として set に格納する。

    例:
        sa1   DS   U2501/A3   1929206

    この場合:
        ("sa1", "U2501/A3")

    を故障1個として扱う。
    """

    faults = set()

    if not os.path.exists(fault_file):
        return faults

    with open(fault_file, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()

            if line == "":
                continue

            tokens = line.split()

            # fault情報として最低限 0列目, 1列目, 2列目 が必要
            if len(tokens) < 3:
                continue

            fault_type = tokens[0]   # sa0 または sa1
            fault_site = tokens[2]   # 故障箇所

            faults.add((fault_type, fault_site))

    return faults


def main():
    """
    使い方:
        python3 Compare_Fault_List.py candidate_DS.flt base_DS.flt

    判定:
        base_DS.flt に含まれる故障が、
        candidate_DS.flt にすべて含まれていれば 1 を出力。
        1つでも欠けていれば 0 を出力。
    """

    if len(sys.argv) != 3:
        print("0")
        sys.exit(1)

    candidate_fault_file = sys.argv[1]
    base_fault_file = sys.argv[2]

    candidate_faults = load_faults(candidate_fault_file)
    base_faults = load_faults(base_fault_file)

    if base_faults.issubset(candidate_faults):
        print("1")
    else:
        print("0")


if __name__ == "__main__":
    main()
