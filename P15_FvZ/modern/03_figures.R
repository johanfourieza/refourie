# P15_FvZ  S6 modern reanalysis, step 3: figures (LEAP style).
#   fig_s6_fan:     GDP per capita 1701-1793 (1990 GK$) across the 144 central-layer scenarios
#                   (min-max and 10-90% envelopes), the central scenario, the as-coded workbook
#                   and the published Table A1 series.
#   fig_s6_tornado: sensitivity 3, each unresolved item varied alone around the central case.
# Outputs: modern/output/fig_s6_fan.{pdf,png}, fig_s6_tornado.{pdf,png} (PNG 300 dpi).

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(ggplot2); library(stringr)})
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P15_FvZ"
out <- file.path(root, "modern", "output")

theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(text = element_text(family = "sans"),
          plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", margin = margin(b = 12), hjust = 0),
          axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 9, color = "#5A5A5A"),
          legend.text = element_text(size = 9),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8), panel.border = element_blank(),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5), panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(), axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
          axis.ticks.length = unit(3, "pt"), legend.background = element_blank(), legend.key = element_blank(),
          plot.background = element_rect(fill = "#FFFFFF", color = NA), panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = margin(10, 10, 10, 10), strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D"))
}
save_fig <- function(stem, plot, width = 10, height = 6) {
  ggsave(file.path(out, paste0(stem, ".png")), plot, width = width, height = height, dpi = 300)
  ggsave(file.path(out, paste0(stem, ".pdf")), plot, width = width, height = height)
}

sc  <- read_csv(file.path(out, "scenarios.csv"), show_col_types = FALSE, col_types = cols(U6 = col_character()))
ser <- read_csv(file.path(out, "scenario_series.csv"), show_col_types = FALSE)
coded <- c(U1 = "lag2_coded", U2 = "div5_coded", U3 = "coded", U4 = "typed_coded", U5 = "P0", U6 = "1.00")
sc <- sc |> mutate(coded_U = U1 == coded[["U1"]] & U2 == coded[["U2"]] & U3 == coded[["U3"]] &
                     U4 == coded[["U4"]] & U5 == coded[["U5"]] & U6 == coded[["U6"]])
id_central <- sc$scenario_id[sc$central_layer == "on" & sc$coded_U]
id_asis    <- sc$scenario_id[sc$central_layer == "off" & sc$coded_U]
on_ids <- sc$scenario_id[sc$central_layer == "on" & sc$finite]

env <- ser |> filter(scenario_id %in% on_ids) |> group_by(year) |>
  summarise(lo = min(gdppc_gk), hi = max(gdppc_gk), p10 = quantile(gdppc_gk, 0.1), p90 = quantile(gdppc_gk, 0.9), .groups = "drop")
lines <- bind_rows(ser |> filter(scenario_id == id_central) |> mutate(series = "Central scenario (C1-C4 on, U as coded)"),
                   ser |> filter(scenario_id == id_asis) |> mutate(series = "Workbook as coded"))
cl <- read_csv(file.path(root, "claims/claims.csv"), show_col_types = FALSE)
pub <- cl |> filter(str_detect(claim_id, "^A1_1[78][0-9]{2}_cape$")) |>
  transmute(year = as.integer(substr(claim_id, 4, 7)), value = suppressWarnings(as.numeric(reported_value))) |>
  filter(year <= 1793, !is.na(value)) |> mutate(series = "Published, Table A1")

fan <- ggplot() +
  geom_ribbon(data = env, aes(year, ymin = lo, ymax = hi), fill = "#97C5B0", alpha = 0.45) +
  geom_ribbon(data = env, aes(year, ymin = p10, ymax = p90), fill = "#45808B", alpha = 0.45) +
  geom_line(data = lines, aes(year, gdppc_gk, colour = series, linetype = series), linewidth = 0.8) +
  geom_point(data = pub, aes(year, value, colour = series), size = 1.1, shape = 16) +
  scale_colour_manual(values = c("Central scenario (C1-C4 on, U as coded)" = "#5C2346",
                                 "Workbook as coded" = "#3D8EB9", "Published, Table A1" = "#D4A03E")) +
  scale_linetype_manual(values = c("Central scenario (C1-C4 on, U as coded)" = "solid", "Workbook as coded" = "dashed"),
                        guide = "none") +
  scale_x_continuous(breaks = seq(1700, 1790, 10), expand = expansion(mult = 0.01)) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0.02, 0.05))) +
  labs(x = NULL, y = "GDP per capita (1990 GK dollars)", colour = NULL,
       caption = "Shading: min-max (light) and 10-90% (dark) range across the 144 central-layer scenarios (U1-U6, equal weight).") +
  guides(colour = guide_legend(override.aes = list(linetype = c("solid", "blank", "dashed"), shape = c(NA, 16, NA)))) +
  theme_leap() + theme(legend.position = "top", plot.caption = element_text(size = 8, colour = "#5A5A5A", hjust = 0))
save_fig("fig_s6_fan", fan)

tor <- read_csv(file.path(out, "tornado.csv"), show_col_types = FALSE, col_types = cols(level = col_character()))
lab_est <- c(Y1701 = "Y1701 (GK$)", Y1790 = "Y1790 (GK$)", R = "R = Y1790/Y1701", trend_gdp = "GDP trend (%/yr)",
             trend_pop = "Population trend (%/yr)", bal_share_in_band = "Balanced: share in band",
             ratio_GB = "Y1701 / Britain", ratio_NL = "Y1701 / Holland")
lab_item <- c(U1 = "U1 investment price", U2 = "U2 vine divisor", U3 = "U3 silver after 1768", U4 = "U4 CPI 1787/1793",
              U5 = "U5 population", U6 = "U6 rest of economy")
td <- tor |> filter(estimand %in% names(lab_est)) |>
  mutate(estimand = factor(lab_est[estimand], levels = lab_est),
         bar = paste0(lab_item[item], ": ", level), bar = factor(bar, levels = rev(sort(unique(bar)))))
tornado <- ggplot(td, aes(x = delta, y = bar, fill = delta < 0)) +
  geom_col(width = 0.7) + geom_vline(xintercept = 0, colour = "#AAAAAA") +
  facet_wrap(~ estimand, scales = "free_x", ncol = 4) +
  scale_fill_manual(values = c(`TRUE` = "#5C2346", `FALSE` = "#3D8EB9"), guide = "none") +
  labs(x = "Change from the central scenario (C1-C4 on, all U as coded)", y = NULL) +
  theme_leap(9) + theme(panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.4),
                        panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 8))
save_fig("fig_s6_tornado", tornado, width = 12, height = 6.5)
cat("figures written\n")
