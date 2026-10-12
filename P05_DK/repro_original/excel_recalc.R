# S2 check: recalculate the formula chain in the 1936 census workbooks with tidyxl and compare with the cached values
# that read_excel() feeds into census_1936_cleanedversion_ddk.R (Table 3). Writes logs/excel_recalc.csv (cell addresses only).
library(tidyxl)
library(dplyr)
source(file.path(Sys.getenv("P05_ROOT", "."), "tools", "paths.R"))
dir_in <- dpath("P05_DK", "original", "Spanish_flu_group_folder", "data", "original", "census", "census1936")
files <- list.files(dir_in, "[.]xlsx$", full.names = TRUE)

col2n <- function(s) { s <- utf8ToInt(toupper(s)) - 64L; sum(s * 26^(rev(seq_along(s)) - 1)) }
expand <- function(tok) {             # "B11" or "B11:C11" -> vector of addresses
  tok <- gsub("[$]", "", tok)
  if (!grepl(":", tok)) return(tok)
  ab <- strsplit(tok, ":")[[1]]
  p <- function(a) list(c = col2n(sub("[0-9]+$", "", a)), r = as.integer(sub("^[A-Z]+", "", a)))
  a <- p(ab[1]); b <- p(ab[2])
  n2c <- function(n) { s <- ""; while (n > 0) { m <- (n - 1) %% 26; s <- paste0(LETTERS[m + 1], s); n <- (n - 1) %/% 26 }; s }
  g <- expand.grid(c = a$c:b$c, r = a$r:b$r)
  paste0(vapply(g$c, n2c, ""), g$r)
}

out <- list()
for (f in files) {
  cl <- xlsx_cells(f) |> filter(!is_blank)
  for (sh in unique(cl$sheet)) {
    s <- cl |> filter(sheet == sh)
    val <- setNames(ifelse(is.na(s$numeric), NA_real_, s$numeric), s$address)
    fml <- setNames(s$formula, s$address)
    fcells <- names(fml)[!is.na(fml)]
    stopifnot(all(grepl("^SUM[(][A-Z0-9:$,]+[)]$|^[A-Z]+[0-9]+([+][A-Z]+[0-9]+)+$", fml[fcells])))   # only SUM(...) and A1+B1+... occur
    memo <- new.env()
    ev <- function(a) {
      if (!is.null(memo[[a]])) return(memo[[a]])
      if (is.na(fml[a]) || is.na(match(a, names(fml)))) { v <- val[a]; v <- if (is.na(v)) 0 else unname(v) }
      else {
        toks <- if (grepl("^SUM", fml[a])) strsplit(sub("^SUM[(](.*)[)]$", "\\1", fml[a]), ",")[[1]] else strsplit(fml[a], "[+]")[[1]]
        v <- sum(vapply(unlist(lapply(toks, expand)), ev, 0))
      }
      memo[[a]] <- v; v
    }
    rec <- vapply(fcells, ev, 0)
    out[[length(out) + 1]] <- tibble(file = basename(f), sheet = sh, address = fcells,
                                     cached = unname(val[fcells]), recalculated = unname(rec))
  }
}
res <- bind_rows(out) |> mutate(match = abs(coalesce(cached, 0) - recalculated) < 1e-9)
dir.create(file.path(Sys.getenv("P05_REPRO", "."), "logs"), showWarnings = FALSE)
write.csv(res, file.path(Sys.getenv("P05_REPRO", "."), "logs", "excel_recalc.csv"), row.names = FALSE)
print(res |> group_by(file) |> summarise(formulas = n(), mismatches = sum(!match)))
