# S5 check 4: surviving Tables and figures.docx vs published claims (copy errors); 1889 column sum
import zipfile, re, csv
p = r"./P26_NF/original/2. DEMOCRACY AND DISENFRANCHISEMENT/Tables and figures.docx"
x = zipfile.ZipFile(p).read("word/document.xml").decode("utf8")
yrs = ["1886","1887","1889","1891","1893","1895"]
pub = {r["claim_id"]: r["reported_value"] for r in csv.DictReader(open("claims/claims.csv", encoding="utf8"))}
code = lambda n: re.sub(r"[^A-Za-z]", "", n.replace("Vic East","Victoria").replace("Graaf","Graaff"))[:8]
nd = 0; n = 0
for t, tbl in zip(["T1","T2"], re.findall(r"<w:tbl>.*?</w:tbl>", x, re.S)):
    for row in re.findall(r"<w:tr[ >].*?</w:tr>", tbl, re.S)[1:]:
        cells = ["".join(re.findall(r"<w:t(?: [^>]*)?>(.*?)</w:t>", c)) for c in re.findall(r"<w:tc>.*?</w:tc>", row, re.S)]
        if not cells[0].strip(): continue
        for y, v in zip(yrs, cells[1:]):
            cid = f"{t}_{code(cells[0])}_{y}"
            if cid not in pub and v.strip() != "N/A": print("no claim", cid, v); continue
            if cid in pub: n += 1
            if cid in pub and pub[cid].replace(",","") != v.replace(",",""): nd += 1; print("DIFF", cid, "docx", v, "pub", pub[cid])
print("cells compared", n, "differences", nd)
