# P07_FG S6 step 4: Theil readings for I3b / I3c (card 4.4) and sensitivity 11 (total Theil level).
# Inputs: Dataset.xlsx 'Inequality' (Khoesan-added values, pasted cells) and FvF (2011) Tables 6-7
# (wiki/papers/JF_EtAl_AHistoryWith.md, the P17 wiki). Writes output/theil.csv and output/theil_basis.csv.
source(file.path(here::here(), "P07_FG", "modern", "00_engine.R"))
suppressPackageStartupMessages(library(tidyxl))
x <- xlsx_cells(dpath("P07_FG", "original", "14 FG Missing People", "Dataset.xlsx"), sheets = "Inequality")
cellv <- function(a) x$numeric[x$address == a]
D12 <- cellv("D12"); D19 <- cellv("D19"); D20 <- cellv("D20"); H3J3 <- c(cellv("H3"), cellv("I3"), cellv("J3"))

# FvF (2011) Table 6 'Whole population' Gini and Table 7 'Whole population' Theil, Between, Within (1700/1723/1757)
fvf <- tibble(basis = c("deflation by price index", "1700 prices", "1757 prices"),
              gini1700 = c(0.792, 0.792, 0.837), gini1723 = c(0.761, 0.757, 0.816), gini1757 = c(0.742, 0.713, 0.744),
              T0 = c(1.240, 1.057, 1.273), b0 = c(0.338, 0.382, 0.331), w0 = c(0.662, 0.618, 0.669))
# verify the transcription against the wiki text
wk <- readLines(file.path(ROOT, "wiki", "papers", "JF_EtAl_AHistoryWith.md"), warn = FALSE)
stopifnot(any(grepl("\\|0.792\\|0.761\\|0.742\\|0.792\\|0.757\\|0.713\\|0.837\\|0.816\\|0.744\\|", wk)),
          any(grepl("\\|1.422\\|1.161\\|1.240\\|1.423\\|1.127\\|1.057\\|1.763\\|1.484\\|1.273\\|", wk)),
          any(grepl("Betweend\\|0.445\\|0.375\\|0.338\\|0.445\\|0.391\\|0.382\\|0.380\\|0.324\\|0.331\\|", wk)),
          any(grepl("Withind\\|0.555\\|0.625\\|0.662\\|0.555\\|0.609\\|0.618\\|0.620\\|0.676\\|0.669\\|", wk)))
fvf <- fvf |> mutate(match_H3J3 = abs(gini1700 - round(H3J3[1], 3)) < 1e-9 & abs(gini1723 - round(H3J3[2], 3)) < 1e-9 & abs(gini1757 - round(H3J3[3], 3)) < 1e-9)
write_csv(fvf, file.path(OUT, "theil_basis.csv"))
bases <- if (any(fvf$match_H3J3)) fvf |> filter(match_H3J3) else fvf |> filter(basis %in% c("1757 prices", "deflation by price index"))
cat("Gini column matching 'Inequality'!H3:J3 (", H3J3, "):", paste(bases$basis, collapse = ", "), "\n")

dirn <- function(new, old) ifelse(new > old, "up", ifelse(new < old, "down", "zero"))
rows <- list()
for (i in seq_len(nrow(bases))) { b <- bases[i, ]
  rows[[length(rows) + 1]] <- tibble(
    claim = c("I3b-share", "I3b-level", "I3c-share", "I3c-level"), basis = b$basis,
    old = c(b$b0, b$b0 * b$T0, b$w0, b$w0 * b$T0), new = c(D19 / D12, D19, D20 / D12, D20),
    authors = c("increases / underestimated", "increases / underestimated", "decreases significantly", "decreases significantly")) }
th <- bind_rows(rows) |> mutate(direction = dirn(new, old))
th <- th |> group_by(claim) |> mutate(direction = if (n_distinct(direction) > 1) "basis-dependent" else first(direction)) |> ungroup() |>
  mutate(agrees_with_authors = ifelse(grepl("^I3b", claim), direction == "up", direction == "down"))
th11 <- tibble(claim = "I3a (sensitivity 11)", basis = bases$basis[1], old = bases$T0[1], new = D12,
               authors = "Gini 0.74 -> 0.50 (no code)", direction = dirn(D12, bases$T0[1]), agrees_with_authors = NA)
th <- bind_rows(th, th11)
write_csv(th, file.path(OUT, "theil.csv"))
print(as.data.frame(th |> mutate(across(c(old, new), ~ round(.x, 4)))))
