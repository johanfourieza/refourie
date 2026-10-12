# S5 check 1: which Table 1 cells are italic (= manual counts) in the surviving Tables and figures.docx
import zipfile, re, sys
p = r"./P26_NF/original/2. DEMOCRACY AND DISENFRANCHISEMENT/Tables and figures.docx"
x = zipfile.ZipFile(p).read("word/document.xml").decode("utf8")
for ti, tbl in enumerate(re.findall(r"<w:tbl>.*?</w:tbl>", x, re.S)):
    print("== table", ti)
    for row in re.findall(r"<w:tr[ >].*?</w:tr>", tbl, re.S):
        cells = []
        for c in re.findall(r"<w:tc>.*?</w:tc>", row, re.S):
            runs = re.findall(r"<w:r[ >].*?</w:r>", c, re.S)
            txt = "".join("".join(re.findall(r"<w:t(?: [^>]*)?>(.*?)</w:t>", r)) for r in runs)
            it = any(re.search(r"<w:i/>|<w:i w:val=\"(1|true)\"/>", r) for r in runs if re.findall(r"<w:t(?: [^>]*)?>(.*?)</w:t>", r))
            cells.append(txt + ("*" if it and txt.strip() else ""))
        print(" | ".join(cells))
