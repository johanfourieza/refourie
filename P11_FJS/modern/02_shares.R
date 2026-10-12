# P11_FJS S6 02: primary top-decile shares S00, S73 and Delta (card §3, §4A-B), the descriptives reported with the
# primary (§4), and E-prog point values (§3; different-estimand).
# Outputs: output/primary_h1.csv, output/primary_descriptives.csv, output/eprog_point.csv
source("./P11_FJS/modern/00_common.R")
hh <- readRDS(file.path(SCR, "households.rds"))

yr <- function(y) hh |> filter(jaar == y) |> arrange(rid)
S <- sapply(c(`1700` = 1700, `1773` = 1773), function(y) { x <- yr(y); share_top(x$tslaves, x$tax) })
prim <- tibble(quantity = c("S00", "S73", "Delta"), value = c(S["1700"], S["1773"], S["1773"] - S["1700"]))
write_csv(prim, file.path(OUT, "primary_h1.csv"))

desc <- bind_rows(lapply(c(1700, 1773), function(y) {
  x <- yr(y); w <- top_w(x$tslaves)
  dsl <- ifelse(is.na(x$ds), "missing", as.character(x$ds))
  bind_rows(
    tibble(year = y, item = c("n", "k = n/10", "cut-point c (slaves)", "records tied at c", "weight per tied record",
                              "records with tslaves > c", "zero-slave records", "hearth uncertain set |U_t|"),
           value = c(nrow(x), nrow(x) / 10, attr(w, "c"), attr(w, "n_tied"), w[x$tslaves == attr(w, "c")][1],
                     sum(x$tslaves > attr(w, "c")), sum(x$tslaves == 0), sum(x$uset))),
    tibble(year = y, ds = c("1", "2", "3", "4", "missing")) |> rowwise() |>
      mutate(records = sum(dsl == ds), top_weight = sum(w[dsl == ds])) |> ungroup() |>
      pivot_longer(c(records, top_weight), names_to = "what") |>
      transmute(year, item = paste0(what, " ds=", ds), value))
}))
write_csv(desc, file.path(OUT, "primary_descriptives.csv"))

# E-prog point values (all seven Image 9 years; R and K reported for 1700 and 1773, decile rates for all)
ep <- bind_rows(lapply(IMG9, function(y) { x <- yr(y); e <- eprog(x$tslaves, x$tax, x$outO)
  tibble(year = y, quantity = names(e), value = unname(e)) }))
ep <- bind_rows(ep, tibble(year = NA, quantity = "dR (R1773 - R1700)",
                           value = ep$value[ep$year == 1773 & ep$quantity == "R"] - ep$value[ep$year == 1700 & ep$quantity == "R"]))
write_csv(ep, file.path(OUT, "eprog_point.csv"))
print(prim); print(as.data.frame(desc)); print(ep |> filter(quantity %in% c("S", "OS", "R", "K")) |> pivot_wider(names_from = quantity))
