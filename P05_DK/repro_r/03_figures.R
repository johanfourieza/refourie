# P05_DK -- S3 independent recreation
# 03_figures.R: Fig. 1 (mortality map), Fig. 2 (covariate maps), Fig. 3 (loess scatters),
#               Fig. 4 (1960/1970 census counts by year of birth; aggregate counts only).
# Figs 5 and 6 need the voters' roll and 1980/1996/2011 microdata, which are not on the allow-list.

suppressPackageStartupMessages({
  library(tidyverse); library(sf); library(patchwork); library(data.table); library(haven)
})
root <- here::here("P05_DK")
source(here::here("tools", "paths.R"))
out_dir <- file.path(root, "repro_r", "output"); dir.create(out_dir, showWarnings = FALSE)
src <- dpath("P05_DK", "original", "Spanish_flu_group_folder", "data", "original")

# LEAP visual identity
LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", margin = margin(b = 12), hjust = 0),
          axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 9, color = "#5A5A5A"),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
          legend.background = element_blank(), legend.key = element_blank(),
          plot.background = element_rect(fill = "#FFFFFF", color = NA),
          panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = margin(10, 10, 10, 10),
          strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D"))
}
theme_map <- function() theme_void(base_size = 10) +
  theme(plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D"),
        plot.background = element_rect(fill = "#FFFFFF", color = NA))
save_fig <- function(name, plot, width = 10, height = 6) {
  ggsave(file.path(out_dir, paste0(name, ".png")), plot, width = width, height = height, dpi = 300)
  ggsave(file.path(out_dir, paste0(name, ".pdf")), plot, width = width, height = height)
}
seq_fill <- scale_fill_gradient(low = "#F3E9EF", high = "#5C2346")

u <- readRDS(dscratch("P05_DK", "repro_r", "districts_1918.rds"))
regions <- u |> group_by(region) |> summarise(.groups = "drop")

# ---------------------------------------------------------------- Fig. 1
f1 <- ggplot() +
  geom_sf(data = u, aes(fill = rate), colour = "white", linewidth = 0.1) +
  geom_sf(data = regions, fill = NA, colour = "#2D2D2D", linewidth = 0.5) +
  scale_fill_gradient(low = "#F3E9EF", high = "#5C2346", trans = "sqrt",
                      breaks = c(5, 20, 40, 80, 120), name = "Influenza deaths\nper 1,000") +
  labs(title = "1918 influenza mortality by magisterial district, with 1918 regions") + theme_map()
save_fig("fig1_mortality_map", f1, 8, 7)

# ---------------------------------------------------------------- Fig. 2
cmap <- function(var, ttl) ggplot(u) + geom_sf(aes(fill = .data[[var]]), colour = "white", linewidth = 0.1) +
  seq_fill + labs(title = ttl, fill = NULL) + theme_map()
f2 <- (cmap("black_sh", "(a) Black pop. share, 1911") | cmap("col_sh", "(b) Coloured pop. share, 1911")) /
  (cmap("ldens", "(c) Log(1 + pop. density, 1911)") | cmap("lrail", "(d) Log(1 + km to 1907 railway)"))
save_fig("fig2_covariate_maps", f2, 10, 8)

# ---------------------------------------------------------------- Fig. 3
sc <- function(var, xl) ggplot(st_drop_geometry(u), aes(.data[[var]], rate)) +
  geom_point(colour = "#3D8EB9", alpha = 0.6, size = 1.4) +
  geom_smooth(method = "loess", formula = y ~ x, colour = "#5C2346", fill = "#AAAAAA", linewidth = 1) +
  labs(x = xl, y = "Influenza deaths per 1,000") + theme_leap()
f3 <- (sc("black_sh", "Black population share, 1911") | sc("col_sh", "Coloured population share, 1911")) /
  (sc("ldens", "Log(1 + population density, 1911)") | sc("lrail", "Log(1 + distance to railway, km, 1907)"))
save_fig("fig3_loess", f3, 10, 8)

# ---------------------------------------------------------------- Fig. 4 (aggregate counts only)
c60 <- file.path(src, "census", "census1960")
yob60 <- map_dfr(list.files(c60, "rdata$", full.names = TRUE), \(f) {
  e <- new.env(); n <- load(f, e); o <- get(setdiff(n, ".Traceback")[1], e)
  tibble(yob = 1960 - as.integer(o$Age)) |> count(yob)
}) |> group_by(yob) |> summarise(n = sum(n), .groups = "drop") |> mutate(census = "1960")
c70 <- file.path(src, "census", "census1970")
a70 <- fread(file.path(c70, "sa census 1970 whitescolouredsasians_full_v1.2.csv"), select = "AGE")
afr70 <- read_dta(file.path(c70, "SA Census 1970 African 5% v01.2.dta"), col_select = "AGE")
yob70 <- bind_rows(tibble(yob = 1970 - as.integer(a70$AGE)), tibble(yob = 1970 - as.integer(afr70$AGE))) |>
  count(yob) |> mutate(census = "1970")
rm(a70, afr70)
cnt <- bind_rows(yob60, yob70) |> filter(between(yob, 1910, 1930))
write_csv(cnt, file.path(out_dir, "fig4_counts_by_birthyear.csv"))   # aggregate counts
f4 <- ggplot(cnt, aes(yob, n)) +
  geom_line(colour = "#5C2346", linewidth = 0.9) + geom_point(colour = "#5C2346", size = 1.6) +
  geom_vline(xintercept = 1919, colour = "#AAAAAA", linetype = "dashed") +
  facet_wrap(~census, scales = "free_y", labeller = labeller(census = c(
    "1960" = "(a) 1960 census: White, Coloured, Indian/Asian samples",
    "1970" = "(b) 1970 census: African 5% + W/C/A full count"))) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "Year of birth (census year minus age)", y = "Number of individuals (unweighted)") + theme_leap()
save_fig("fig4_cohort_counts", f4, 10, 5)
cat("Figures written to", out_dir, "\n")
