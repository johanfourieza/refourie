# P15_FvZ S3 recreation -- 03_figures.R : analogues of Figs 1, 2, 3, 7 (PDF + PNG 300 dpi)
suppressPackageStartupMessages(library(tidyverse))
args <- commandArgs(FALSE)
this <- normalizePath(sub("--file=", "", args[grep("--file=", args)]))
root <- dirname(dirname(this)); out <- file.path(root, "repro_r", "output")
d <- read_csv(file.path(out, "series_annual.csv"), show_col_types = FALSE)

pal <- c("#1b3a5c", "#c8553d", "#7a9e7e", "#d4a72c")
th <- theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", legend.title = element_blank(), panel.grid.minor = element_blank())
save2 <- function(p, name, w = 7, h = 4) {
  ggsave(file.path(out, paste0(name, ".pdf")), p, width = w, height = h)
  ggsave(file.path(out, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
}

f1 <- d %>% select(year, Slaves = slaves, Khoesan = khoesan, Europeans = europeans) %>%
  pivot_longer(-year) %>% mutate(name = factor(name, c("Slaves", "Khoesan", "Europeans"))) %>%
  ggplot(aes(year, value, fill = name)) + geom_area() + scale_fill_manual(values = pal) +
  scale_y_continuous(labels = scales::comma) + labs(x = NULL, y = "Persons") + th
save2(f1, "fig1_population")

g <- d %>% filter(!is.na(gdp_nom))
f2 <- g %>% select(year, Agriculture = agriculture, VOC = voc, `Secondary and tertiary sector` = rest) %>%
  pivot_longer(-year) %>% mutate(name = factor(name, c("Agriculture", "VOC", "Secondary and tertiary sector"))) %>%
  ggplot(aes(year, value / 1000, fill = name)) + geom_area() + scale_fill_manual(values = pal) +
  labs(x = NULL, y = "Thousand guilders, current prices") + th
save2(f2, "fig2_gdp_nominal")

f3 <- g %>% select(year, `GDP per capita` = gdppc, `GDP per capita, Europeans only` = gdppc_eur,
                   `GDP per capita (balanced)` = gdppc_bal) %>%
  pivot_longer(-year) %>% ggplot(aes(year, value, colour = name)) + geom_line() +
  scale_colour_manual(values = pal) + labs(x = NULL, y = "Guilders of 1701") + th
save2(f3, "fig3_gdppc_1701guilders")

f7 <- g %>% select(year, `Cape Colony` = usd, `Cape Colony: Europeans` = usd_eur, `GDP per "balanced" capita` = usd_bal) %>%
  pivot_longer(-year) %>% ggplot(aes(year, value, colour = name)) + geom_line() +
  scale_colour_manual(values = pal) + scale_y_continuous(labels = scales::comma) +
  labs(x = NULL, y = "1990 international dollars",
       caption = "Holland and GB series not reproduced (inputs unavailable). Level rests on a conversion factor typed from the paper.") + th
save2(f7, "fig7_gdppc_1990usd")
cat("03_figures.R done\n")
