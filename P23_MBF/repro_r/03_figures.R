# P23_MBF S3 independent recreation - 03_figures.R
# Figure 2 (leader entry year by country, ALTT) and Figure 3 (weighted years of schooling by
# birth decade, leader birth regions vs others). Figure 1 (map) needs shapefiles: not attempted.
suppressMessages({
  library(here); library(dplyr); library(readr); library(ggplot2)
})
proj <- here::here()
source(file.path(proj, "tools", "paths.R"))
P <- "P23_MBF"
scr <- function(...) dscratch(P, "repro_r", ...)
out <- file.path(proj, "P23_MBF", "repro_r", "output")

leap_cols <- c(others = "#7F7F7F", birth = "#A51C30")   # LEAP palette: grey vs maroon accent
theme_leap <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom",
        strip.text = element_text(face = "bold"))
save_fig <- function(p, name, w, h) {
  ggsave(file.path(out, paste0(name, ".pdf")), p, width = w, height = h)
  ggsave(file.path(out, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
}

cc <- c("Benin", "Ghana", "Guinea", "Kenya", "Malawi", "Mali", "Senegal", "Sierra Leone",
        "Tanzania", "Uganda", "Zambia")
alt <- read_delim(dpath(P, "original", "ld",
                        "agi__african_leadership_transitions_tracker_april_2018_sample_lmb12.csv"),
                  delim = ";", show_col_types = FALSE, locale = locale(encoding = "latin1")) |>
  mutate(name = trimws(name)) |>
  filter(name %in% cc, !is.na(leader), year_enter >= 1960, year_enter <= 1990)
leaders <- alt |> group_by(name, leader) |>
  summarise(year_enter = min(year_enter), independence = first(independence), .groups = "drop")
write_csv(leaders |> count(name, name = "n_leaders"), file.path(out, "leaders_by_country.csv"))
indep <- leaders |> distinct(name, independence)

p2 <- ggplot(leaders, aes(year_enter, name)) +
  geom_point(aes(shape = "Leader, year enter office"), colour = leap_cols["birth"], size = 2) +
  geom_point(data = indep, aes(independence, name, shape = "Independence"), colour = "black",
             size = 2) +
  scale_shape_manual(values = c("Leader, year enter office" = 16, "Independence" = 4), name = NULL) +
  labs(x = NULL, y = NULL) + theme_leap
save_fig(p2, "fig2_leader_entry", 6.5, 4)

# Figure 3: weighted mean years of schooling (region x decade cells, perwt) - aggregate only
agg <- readRDS(scr("region_decade.rds"))
f3 <- agg |>
  mutate(grp = ifelse(d_birth_all == 1, "birth", "others"), wsum = yrschool_w * n_ind) |>
  filter(!is.na(yrschool_w)) |>
  group_by(cntry_name, bdec_r, grp) |>
  summarise(yrs = sum(wsum) / sum(n_ind), .groups = "drop")
write_csv(f3, file.path(out, "fig3_yrschool.csv"))
p3 <- ggplot(f3, aes(bdec_r, yrs, colour = grp)) +
  geom_line() + geom_point(size = 1) +
  facet_wrap(~cntry_name, scales = "free_y", ncol = 4) +
  scale_colour_manual(values = leap_cols, labels = c(birth = "leader's birth region", others = "others"),
                      name = NULL) +
  labs(x = "Birth decade", y = "Years of schooling") + theme_leap
save_fig(p3, "fig3_yrschool", 7.5, 6)

# "6 of 11": birth-region mean above others in every pre- and every post-independence decade
ind_year <- read_csv(file.path(out, "table1_sample.csv"), show_col_types = FALSE) |>
  select(cntry_name, indep = independence)
six <- f3 |> tidyr::pivot_wider(names_from = grp, values_from = yrs) |>
  left_join(ind_year, by = "cntry_name") |>
  filter(!is.na(birth), !is.na(others)) |>
  mutate(pre = bdec_r + 13 < indep) |>
  group_by(cntry_name) |>
  summarise(pre_higher = all((birth > others)[pre]), post_higher = all((birth > others)[!pre]),
            both = pre_higher & post_higher, .groups = "drop")
write_csv(six, file.path(out, "fig3_countries_higher.csv"))
cat("countries higher pre and post:", sum(six$both), "\n")
