# 02_analysis.R -- compute claim values; writes results_r.csv (complete file, unavailable by default)
library(tidyverse); library(here)
source(here::here("tools", "paths.R"))
x <- readRDS(dscratch("P17_FvFH", "repro_r", "clean.rds"))
cl <- read_csv(here::here("P17_FvFH", "claims", "claims.csv"), col_types = cols(.default = "c"))
res <- tibble(claim_id = cl$claim_id, source = "r", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable")
set <- function(id, v, n = NA) { i <- match(id, res$claim_id); if (!is.na(i) && length(v) == 1 && is.finite(v)) { res$value[i] <<- v; res$n[i] <<- n; res$status_override[i] <<- NA_character_ } ; invisible() }
cols <- c("adult_males","adult_females","boys","girls","burgher_total","knecht","male_slave","female_slave","boy_slave","girl_slave","slave_total_burgher","voc_slaves")
# T1
for (g in c("grain","wine","cattle","horses","pig","sheep")) for (y in c(1700, 1724, 1757)) {
  u <- x$pr %>% filter(year == y, grepl(paste0("^", g), unit, ignore.case = TRUE)); if (nrow(u) == 1) set(paste0("T1_", g, "_", y), u$price) }
# T2 vdr and cur
for (y in c(1702, 1723, 1757)) for (cc in cols) set(paste0("T2_vdr_", y, "_", cc), x$vdr[[cc]][x$vdr$year == y])
for (y in c(1700, 1702, 1723, 1757)) for (cc in c(cols, "voc_slaves")) set(paste0("T2_cur_", y, "_", cc), x$cur[[cc]][x$cur$year == y])
set("T2_cur_1700_voc_burgher", 0); for (y in c(1702,1723,1757)) set(paste0("T2_cur_", y, "_voc_burgher"), 0)
# T2 proportion captured and weights (burgher, knecht, non-VOC-adjusted); slave weights need VOC slave totals (not found)
pcs <- c("burgher_total","knecht","male_slave","female_slave","boy_slave","girl_slave")
pcv <- list()
for (y in c(1702, 1723, 1757)) for (cc in pcs) {
  r <- x$cur[[cc]][x$cur$year == y] / x$vdr[[cc]][x$vdr$year == y]; pcv[[paste(y, cc)]] <- r
  set(paste0("T2_pc_", y, "_", cc), r); if (cc %in% c("burgher_total", "knecht")) set(paste0("T2_wf_", y, "_", cc), 1 / r) }
# T3 VOC establishment counts
set("T3_1724_vdr", x$ce$n[x$ce$year == 1724]); set("T3_1756_vdr", x$ce$n[x$ce$year == 1756])
# T4 knecht represented population (sample count x weight; 1700 uses the 1702 weight, per Table 2 note)
for (y in c(1700, 1723, 1757)) { wy <- if (y == 1700) 1702 else y
  set(paste0("T4_", y, "_knechts_pop"), x$cur$knecht[x$cur$year == y] / pcv[[paste(wy, "knecht")]]) }
write_csv(res, here::here("P17_FvFH", "repro_r", "results_r.csv"), na = "")
cat(sum(is.na(res$status_override)), "of", nrow(res), "claims computed\n")
saveRDS(pcv, dscratch("P17_FvFH", "repro_r", "pcv.rds"))
