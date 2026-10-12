# Annual medians by year for the zero-dummy and owners-only variants (reuses the helpers in s5_checks.R)
ex <- parse(here::here("P21_LFG", "compare", "s5_checks", "s5_checks.R"))
k <- which(sapply(ex, function(e) grepl("^ma5 <-", deparse(e)[1])))
for (e in ex[seq_len(k)]) eval(e, globalenv())
suppressWarnings({
  Bz <- annual(prep(d0, logf = "battese"), TRUE); Ow <- annual(filter(prep(d0), slaves > 0))
  M5 <- ma5(annual(prep(d0)))})
out <- bind_rows(Bz |> mutate(v = "battese"), Ow |> mutate(v = "owners"), M5 |> mutate(v = "ma5_of_medians")) |>
  select(v, year, n, FS, FK, SK, t_ks, t_sf)
readr::write_csv(out, file.path(od, "annual_variants.csv"))
print(out |> select(v, year, FS, FK, SK) |> mutate(across(FS:SK, ~round(.x, 2))) |>
  pivot_wider(names_from = v, values_from = c(FS, FK, SK)), n = 30, width = 250)
