import re

def parse_stil_from_file_1(file_path: str):
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        stil_text = f.read()

    # --- "pattern N" ブロックをゆるく拾う（次の pattern までを包含） ---
    # 例: pattern 12: / "pattern 12": など大小文字・引用符を許容
    pattern_iter = re.finditer(
        r'[\"“”]?\bpattern\s+(\d+)[\"“”]?\s*:\s*(.*?)\s*(?=(?:[\"“”]?\bpattern\s+\d+[\"“”]?\s*:)|\Z)',
        stil_text,
        re.DOTALL | re.IGNORECASE
    )

    def extract_first(key, text):
        m = re.search(rf'["“”]?{re.escape(key)}["“”]?\s*=\s*([^;]+);', text, re.IGNORECASE)
        return re.sub(r'\s+', '', m.group(1)) if m else None

    pattern_data = {}
    for m in pattern_iter:
        pat_num = int(m.group(1))
        body = m.group(2)  # この pattern の全文（load/capture の順序や Call 名は不問）

        pattern_data[pat_num] = {
            "test_si": extract_first("test_si", body),
            # ここで拾う test_so は参照用（最終的には N+1 側 or end N unload を使用）
            "test_so": extract_first("test_so", body),
            "_pi":     extract_first("_pi", body),
            "_po":     extract_first("_po", body),
        }

    # --- "end N unload" から test_so を補完（ケース無視・引用符任意） ---
    test_so_map = {}  # { N+1: test_so }
    for mm in re.finditer(
        r'[\"“”]?\bend\s+(\d+)\s+unload[\"“”]?\s*:\s*Call\s*"[^\"]*"\s*{[^}]*?["“”]?test_so["“”]?\s*=\s*([^;]+);',
        stil_text, re.DOTALL | re.IGNORECASE
    ):
        pat_plus_1 = int(mm.group(1)) + 1
        test_so = re.sub(r'\s+', '', mm.group(2))
        test_so_map[pat_plus_1] = test_so

    # --- 出力組み立て ---
    all_indices = sorted(pattern_data.keys())
    if not all_indices:
        print("No pattern blocks found.")
        return []

    expected = list(range(all_indices[0], all_indices[-1] + 1))
    missing = sorted(set(expected) - set(all_indices))

    result = []
    for i in all_indices:
        cur = pattern_data[i]
        nxt = pattern_data.get(i + 1, {})
        # 仕様どおり：test_so は「次パターンの test_so or end N unload」
        test_so = nxt.get("test_so") or test_so_map.get(i + 1)

        result.append((cur["test_si"], cur["_pi"], test_so, cur["_po"]))

        if test_so is None:
            print(f"[Warning] test_so not found for pattern {i + 1}")

    if missing:
        print("Skipped pattern(s):", ', '.join(map(str, missing)))
    else:
        print("Correctly parsed")

    return result







def CB_Partition(Pattern_num1, Pattern_num2, TP_Pair, Stil_Format_Path, Output_Stil_File):
    """
    指定されたパターン範囲 [Pattern_num1, Pattern_num2] のTP_Pairから
    STILファイルを生成する関数。

    Parameters:
        Pattern_num1 (int): 開始パターン番号（1始まり）
        Pattern_num2 (int): 終了パターン番号（1始まり）
        TP_Pair (list of tuple): 各パターンの (si, pi, so, po) のタプルリスト
        Stil_Format_Path (str): format1, format2, format3を定義したテキストファイルのパス
        Output_Stil_File (str): 出力されるSTILファイルのパス
    """

    # --- フォーマットファイルの読み込み ---
    with open(Stil_Format_Path, "r", encoding="utf-8") as f:
        content = f.read()

    # format1/2/3 を正規表現で抽出
    import re

    def extract_format(name):
        match = re.search(rf'{name}\s*=\s*("""|\'\'\')([\s\S]*?)\1', content)
        return match.group(2) if match else ""

    format1 = extract_format("format1")
    format2 = extract_format("format2")
    format3 = extract_format("format3")

    if not (format1 and format2 and format3):
        raise ValueError("format1 / format2 / format3 がファイルから正しく読み込めませんでした。")

    # --- 書き出し処理 ---
    with open(Output_Stil_File, "w", encoding="utf-8") as f:
        # ヘッダ部分
        f.write(format1)
        f.write("\n")

        # 各パターンを書き出し
        j = 0
        for i in range(Pattern_num1, Pattern_num2 + 1):
            j = j + 1
            si = TP_Pair[i][0]
            so = TP_Pair[j-1][2]
            pi = TP_Pair[i][1]
            po = TP_Pair[i][3]
            f.write(format3.format(
                #Chain Test なし
                pattern_num=j-1,
                #Chain Test あり
                #pattern_num=j,
                test_si=si,
                #Chain Test なしのため、test_so は最後だけでよい
                #test_so=so,
                pi=pi,
                po=po
            ))
            f.write("\n")

        # 終了処理
        _, _, last_so, _ = TP_Pair[Pattern_num2]
        f.write(format2.format(
            # Chain Test あり
            #total=(Pattern_num2) - (Pattern_num1) + 1,
            # Chain Test なし
            total = 0 ,
            test_so=last_so
        ))

