# =============================================================================
# Apply_X_To_Current_STIL.py
#
# 【概要】
# ET1用STIL内の指定 pattern / test_si or pi / bit番号 を N に更新する。
#
# 【用途】
# fault simulation の結果、候補STILで検出故障集合を維持できた場合にのみ呼び出す。
#
# 例:
#   python3 python/b14_Apply_X_To_Current_STIL.py 0 test_si 3
#
# 【注意】
# ・STIL全体は再生成しない
# ・指定 pattern ブロック内の test_si または _pi の値だけを置換する
# ・test_so, _po, end unload, コメント等は変更しない
# ・初回のみ ../b14/b14.stil を b14/b14_ET1.stil にコピーする
# =============================================================================

import os
import sys
import re
import shutil

Circuit = "b22"

Original_Stil = os.path.join(
    "..",
    Circuit,
    f"{Circuit}.stil"
)

Current_Stil = os.path.join(
    Circuit,
    f"{Circuit}_ET1.stil"
)


def prepare_current_stil():
    if not os.path.exists(Current_Stil):
        if not os.path.exists(Original_Stil):
            print(f"Error: Original_Stil does not exist: {Original_Stil}", file=sys.stderr)
            sys.exit(1)

        os.makedirs(os.path.dirname(Current_Stil), exist_ok=True)
        shutil.copyfile(Original_Stil, Current_Stil)


def replace_bit_to_n(value: str, bit_num: int) -> str:
    if bit_num < 0 or bit_num >= len(value):
        raise ValueError(f"bit_num out of range: {bit_num}")

    if value[bit_num] == "P":
        return value

    if value[bit_num] == "N":
        return value

    return value[:bit_num] + "N" + value[bit_num + 1:]


def main():
    if len(sys.argv) != 4:
        print(
            "Usage: python3 b14_Apply_X_To_Current_STIL.py <pattern_num> <test_si|pi> <bit_num>",
            file=sys.stderr
        )
        sys.exit(1)

    pattern_num = int(sys.argv[1])
    column_name = sys.argv[2]
    bit_num = int(sys.argv[3])

    if column_name == "test_si":
        key = "test_si"
    elif column_name == "pi":
        key = "_pi"
    else:
        print("Error: column_name must be test_si or pi", file=sys.stderr)
        sys.exit(1)

    prepare_current_stil()

    with open(Current_Stil, "r", encoding="utf-8", errors="replace") as f:
        stil_text = f.read()

    pattern_re = re.compile(
        rf'(["“”]?pattern\s+{pattern_num}["“”]?\s*:\s*.*?)(?=(["“”]?pattern\s+\d+["“”]?\s*:)|\Z)',
        re.DOTALL | re.IGNORECASE
    )

    m = pattern_re.search(stil_text)
    if not m:
        print(f"Error: pattern {pattern_num} not found", file=sys.stderr)
        sys.exit(1)

    block = m.group(1)

    target_re = re.compile(
        rf'(["“”]?{re.escape(key)}["“”]?\s*=\s*)([^;]+)(;)',
        re.DOTALL | re.IGNORECASE
    )

    tm = target_re.search(block)
    if not tm:
        print(f"Error: {key} not found in pattern {pattern_num}", file=sys.stderr)
        sys.exit(1)

    prefix = tm.group(1)
    value = re.sub(r"\s+", "", tm.group(2))
    suffix = tm.group(3)

    new_value = replace_bit_to_n(value, bit_num)

    if new_value == value:
        print("SKIP")
        return

    new_block = (
        block[:tm.start()]
        + prefix
        + new_value
        + suffix
        + block[tm.end():]
    )

    new_stil_text = stil_text[:m.start()] + new_block + stil_text[m.end():]

    with open(Current_Stil, "w", encoding="utf-8") as f:
        f.write(new_stil_text)

    print(Current_Stil)


if __name__ == "__main__":
    main()
