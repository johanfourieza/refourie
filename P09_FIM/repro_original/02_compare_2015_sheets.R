# P09_FIM S2 (EARLIER-VERSION run): compare the rerun 2015 do-file outputs (estout
# .txt) with the regression output sheets saved in Whitelivingstandards_7July.xlsx.
# These sheets are the 2015 authors' own results; they are NOT the 2022 paper.
# Output: compare_2015_sheets.csv (coefficients, t, N only; no individual rows).

suppressMessages({library(tidyxl); library(dplyr); library(stringr); library(purrr); library(here)})
source(here::here("tools", "paths.R"))
root <- here::here("P09_FIM", "repro_original")
f <- dpath("P09_FIM", "original", "FM White living standards", "Whitelivingstandards_7July.xlsx")

# --- estout txt: b row followed by (t) row; equations main/eq1 and sigma -------
read_estout <- function(p) {
  l <- str_split(readLines(p, warn = FALSE), "\t")
  hdr <- l[[1]][-1]; out <- list(); eq <- "main"; i <- 3
  while (i <= length(l)) {
    r <- l[[i]]; nm <- r[1]
    if (nm %in% c("main", "eq1", "sigma")) { eq <- ifelse(nm == "sigma", "sigma", "main"); i <- i + 1; next }
    if (nm %in% c("r2", "N")) {
      out[[length(out) + 1]] <- tibble(spec = seq_along(hdr), term = nm, b = suppressWarnings(as.numeric(r[-1])), t = NA_real_); i <- i + 1; next
    }
    tr <- if (i + 1 <= length(l)) l[[i + 1]] else rep("", length(r))
    term <- ifelse(eq == "sigma", "sigma", nm)
    out[[length(out) + 1]] <- tibble(spec = seq_along(hdr), term = term,
      b = suppressWarnings(as.numeric(str_remove_all(r[-1], "\\*"))),
      t = suppressWarnings(as.numeric(str_remove_all(tr[-1], "[()]"))))
    i <- i + 2
  }
  bind_rows(out) %>% filter(!is.na(b))
}

# --- workbook sheet: label column 1, b row then t row ---------------------------
# Excel parsed "(2.82)" as the number -2.82 (accounting negative), so a numeric t
# cell holds -t; text t cells hold the literal "(-0.56)".
read_sheet <- function(s, first_col = 2) {
  c <- xlsx_cells(f, sheets = s) %>% filter(data_type != "blank")
  val <- function(r, cl) { x <- c %>% filter(row == r, col == cl); if (!nrow(x)) return(list(n = NA, s = NA)); list(n = x$numeric, s = x$character) }
  lab <- c %>% filter(col == 1) %>% select(row, label = character)
  specs <- sort(unique(c$col[c$col >= first_col & c$row == 1]))
  rows <- sort(unique(c$row)); out <- list()
  for (r in rows) {
    lb <- lab$label[lab$row == r]; if (!length(lb) || is.na(lb)) next
    for (k in seq_along(specs)) {
      v <- val(r, specs[k]); b <- if (!is.na(v$n)) v$n else suppressWarnings(as.numeric(str_remove_all(v$s, "\\*")))
      if (is.na(b)) next
      tv <- val(r + 1, specs[k])
      t <- if (!is.na(tv$n)) -tv$n else suppressWarnings(as.numeric(str_remove_all(tv$s, "[()]")))
      st <- if (!is.na(v$s)) str_count(v$s, "\\*") else 0L
      out[[length(out) + 1]] <- tibble(row = r, spec = k, label = lb, b = b, t = t, stars = st)
    }
  }
  res <- bind_rows(out); attr(res, "sig_row") <- min(lab$row[lab$label %in% "sigma"], Inf); res
}

lab_map <- c("SAC" = "0.sourcedum", "CMP" = "1.sourcedum", "AOF" = "2.sourcedum",
  "Eastern Cape" = "1.regiondum", "Northern Cape" = "2.regiondum", "Natal" = "3.regiondum",
  "Orange Free State" = "4.regiondum", "Transvaal" = "5.regiondum", "Age" = "age",
  "Afrikaans" = "afrikaans", "Boer-surname" = "afrikaans", "Urban" = "urban", "Black" = "black",
  "1871-1875" = "by2", "1876-1880" = "by3", "1881-1885" = "by4", "1886-1890" = "by5", "1891-1895" = "by6",
  "Constant" = "_cons", "Sigma" = "sigma", "sigma" = "sigma", "Sigma constant" = "sigma", "N" = "N",
  "R-squared" = "r2", "American" = "1.nationalitydum", "Australian" = "2.nationalitydum",
  "European" = "3.nationalitydum", "South African" = "4.nationalitydum", "Black South African" = "5.nationalitydum")
map_lab <- function(x) { m <- lab_map[x]; h <- str_match(x, "^HISCO (\\d)$")[, 2]; ifelse(!is.na(m), m, ifelse(!is.na(h), paste0(h, ".hisco"), x)) }

pairs <- tribble(
  ~sheet,            ~run,                 ~file,                 ~note,
  "Regressionfinal", "wls15July",          "whiteliv.txt",        "15 July file, lines 80-86 (+header)",
  "Sheet3",          "wls26July_Aprime",   "whiteliv.txt",        "26 July file, lines 80-86 (A' run; not reached in the original run, which halts at line 49)",
  "Sheet4",          "wls26July_Aprime",   "whitebirthyears.txt", "26 July file, lines 105-109 (A' run; not reached in the original run)",
  "Martine",         "wls26July_Aprime",   "martine.txt",         "26 July file, lines 115-117 (A' run; not reached in the original run)",
  "Regression 1",    "wls8July_Aprime",    "whiteliving.txt",     "8 July file, estout whiteliving (A' run; not reached in the original run)",
  "Regression 2",    "wls8July_Aprime",    "whiteliving2.txt",    "8 July file, estout whiteliving2 (A' run; not reached in the original run)")

res <- pmap_dfr(pairs, function(sheet, run, file, note) {
  wb0 <- read_sheet(sheet); wb <- wb0 %>% mutate(term = map_lab(label)); attr(wb, "sig_row") <- attr(wb0, "sig_row")
  # 8 July file uses i.sourcedum (base 0 = SAC): "CMP" = 1.sourcedum, "Other forces" = 2.sourcedum
  if (sheet %in% c("Regression 1", "Regression 2")) wb <- wb %>% mutate(term = recode(term, "Other forces" = "2.sourcedum"))
  # Sheet4 is a raw estout paste (est1-est4 in columns 2-5; columns 9-10 re-label est1);
  # its second "_cons" row is the sigma equation.
  if (sheet == "Sheet4") {
    sig_row <- attr(wb, "sig_row")
    wb <- wb %>% filter(spec <= 4) %>% mutate(term = ifelse(label == "_cons" & row > sig_row, "sigma", label))
  }
  ours <- read_estout(file.path(root, "logs", run, file))
  wb %>% select(-row) %>% left_join(ours, by = c("spec", "term"), suffix = c("_2015", "_rerun")) %>%
    mutate(sheet = sheet, run = run, file = file, note = note, .before = 1)
})
res <- res %>% filter(!str_detect(term, "\\.(birthyear|year)$")) %>%
  mutate(abs_diff_b = abs(b_rerun - b_2015),
         match_b = case_when(is.na(b_rerun) ~ "missing_in_rerun", abs_diff_b <= 0.0015 ~ "exact_3dp", TRUE ~ "differs"))
write.csv(res, file.path(root, "compare_2015_sheets.csv"), row.names = FALSE)
print(res %>% count(sheet, spec, match_b) %>% tidyr::pivot_wider(names_from = match_b, values_from = n, values_fill = 0), n = 50)
