#!/usr/bin/env python3
import sys
from collections import defaultdict

if len(sys.argv) != 5:
    print("Usage:")
    print("  python3 vcd_to_logic_tsv_at_time.py <vcd> <signal_list.txt> <target_time> <out.tsv>")
    print("")
    print("Example:")
    print("  python3 vcd_to_logic_tsv_at_time.py b14_pn1_good.vcd signal_list.txt 400 b14_pn1_logic.tsv")
    sys.exit(1)

vcd_file = sys.argv[1]
signal_list_file = sys.argv[2]
target_time = int(sys.argv[3])
out_tsv = sys.argv[4]

# DC側で取得した対象信号
with open(signal_list_file) as f:
    targets = [line.strip() for line in f if line.strip()]

id_to_vcd_signals = defaultdict(list)
value_at_time = {}
scope_stack = []

current_time = 0
in_def = True
stop_value_parse = False

with open(vcd_file, "r", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue

        # -------------------------
        # definition section
        # -------------------------
        if in_def:
            if line.startswith("$scope"):
                fields = line.split()
                scope_stack.append(fields[2])
                continue

            if line.startswith("$upscope"):
                if scope_stack:
                    scope_stack.pop()
                continue

            if line.startswith("$var"):
                fields = line.split()
                vcd_id = fields[3]
                sig_name = fields[4]
                full_name = "/".join(scope_stack + [sig_name])
                id_to_vcd_signals[vcd_id].append(full_name)
                continue

            if line.startswith("$enddefinitions"):
                in_def = False
                continue

            continue

        # -------------------------
        # value change section
        # -------------------------
        if line.startswith("#"):
            current_time = int(line[1:])

            if current_time > target_time:
                break

            continue

        if current_time > target_time:
            break

        # scalar value change: 0:r, 1:r, x:r, z:r
        first = line[0]
        if first in ("0", "1", "x", "X", "z", "Z"):
            vcd_id = line[1:]
            value_at_time[vcd_id] = first.lower()
            continue

        # vector value change: b1010 !
        if line.startswith("b"):
            fields = line.split()
            if len(fields) == 2:
                value = fields[0][1:].lower()
                vcd_id = fields[1]
                value_at_time[vcd_id] = value
            continue

# VCD full signal name -> value
vcd_signal_to_value = {}
for vcd_id, sigs in id_to_vcd_signals.items():
    if vcd_id not in value_at_time:
        continue

    val = value_at_time[vcd_id]

    for sig in sigs:
        vcd_signal_to_value[sig] = val

# DC signal name と VCD signal name を suffix match で対応
with open(out_tsv, "w") as out:
    out.write("signal\tvalue\n")

    for target in targets:
        matched_value = None

        for vcd_sig, val in vcd_signal_to_value.items():
            if vcd_sig == target or vcd_sig.endswith("/" + target):
                matched_value = val
                break

        if matched_value is not None:
            out.write(f"{target}\t{matched_value}\n")
