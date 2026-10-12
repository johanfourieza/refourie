# 01_data.R -- P27_RW S6: build inventory and opgaaf samples (card section 3) and run the verification checks.
# Reuses the variable construction of repro_r/01_clean.R (opgaaf slaves = cols 34+36+38+40; NA -> 0).
suppressMessages({library(haven); library(readxl); library(dplyr)})
source("tools/paths.R")
raw <- dpath("P27_RW", "original", "Data"); scr <- dscratch("P27_RW", "modern")
wmean <- function(y, w) sum(w * y) / sum(w)
b <- read_dta(file.path(raw, "Statafiles", "numbersandwealth.dta")) |> filter(!is.na(date))
stopifnot(nrow(b) == 2577)
items <- c("slavesnumb","beesten","paarden","schapen","ploeg","koornharp","schuijt","emmers","graaven","geweer",
           "brandewijnskeetels","waagen","aambeeld","bankschroef","balans","tang","stoven","kadels","stoel","broek",
           "strijkijsters","boeken","horlogie","snuijfdoos","schilderij","spiegel","vogelkooi","ring")
key <- do.call(paste, c(b[, c("date", items)], sep = "|")); nz <- rowSums(b[, items]) > 0
I <- data.frame(y = as.numeric(b$wealthrijks), yns = as.numeric(b$wealthrijks - b$slawerijks), s = as.numeric(b$slavesnumb),
                decade = as.numeric(b$decade), date = as.numeric(b$date), yr = floor(as.numeric(b$date)),
                group = as.numeric(b$group), cattle = as.numeric(b$beesten), horses = as.numeric(b$paarden),
                sheep = as.numeric(b$schapen), dup = duplicated(key) & nz, allzero = !nz)
o <- suppressMessages(read_excel(file.path(raw, "Opgaafrolle 1 Des 2010.xlsx"), sheet = "Data", .name_repair = "minimal"))
o <- o[!is.na(o$Jaar) & o$Jaar >= 1700 & o$Jaar <= 1773, ]
num <- function(j) { v <- suppressWarnings(as.numeric(unlist(o[, j]))); v[is.na(v)] <- 0; v }
nk <- function(x) { x <- iconv(ifelse(is.na(x), "", as.character(x)), to = "ASCII//TRANSLIT"); x[is.na(x)] <- ""; gsub("[^a-z]", "", tolower(x)) }
O <- data.frame(yr = as.numeric(o$Jaar), s = num(34) + num(36) + num(38) + num(40), wife = num(26),
                horses = num(42), cattle = num(44), sheep = num(46), key = paste(nk(o[[1]]), nk(o[[2]]), sep = "_"))
d2 <- read_dta(file.path(raw, "Statafiles", "opgaafrolle.dta")) |> filter(jaar >= 1700, jaar <= 1773)
z <- function(v) { v <- as.numeric(v); v[is.na(v)] <- 0; v }
O2 <- data.frame(yr = as.numeric(d2$jaar), s = z(d2$sm) + z(d2$sv) + z(d2$ss) + z(d2$sd))
saveRDS(list(I = I, O = O, O2 = O2), file.path(scr, "samples.rds"))

# verification checks: corrections off -> reproduce S2/S3 and the S5 two-class reweighting
pre <- I$decade <= 1800; own <- O$s >= 1
p0 <- 1 - mean(own); i0 <- mean(I$s == 0); w2 <- ifelse(I$s == 0, p0 / i0, (1 - p0) / (1 - i0))
chk <- data.frame(check = c("T5_1700_mean", "T5_1790_mean", "T5_total_mean", "T4_inv_slaves_mean_owners", "opg_n", "opg_owners",
                            "opg_slaves_mean_owners", "inv_share_owners", "opg_share_owners", "S5_rw_total", "S5_rw_1700", "S5_rw_1790",
                            "n_dup", "n_allzero", "T5_total_n"),
  target = c(759.3, 1978.7, 1650.2, 7.486, 15587, 6932, 7.42, 0.6574, 0.4447, 1325.1, 496.8, 1594.9, 10, 49, 2228),
  value = c(mean(I$y[I$decade == 1700]), mean(I$y[I$decade == 1790]), mean(I$y[pre]), mean(I$s[I$s >= 1]), nrow(O), sum(own),
            mean(O$s[own]), mean(I$s >= 1), mean(own), wmean(I$y[pre], w2[pre]), wmean(I$y[I$decade == 1700], w2[I$decade == 1700]),
            wmean(I$y[I$decade == 1790], w2[I$decade == 1790]), sum(I$dup), sum(I$allzero), sum(pre)))
chk$pass <- abs(chk$value - chk$target) <= pmax(0.051, 0.0006 * abs(chk$target))
write.csv(chk, "P27_RW/modern/output/verification.csv", row.names = FALSE); print(chk)
# descriptives the card asks for (section 4)
yc <- table(factor(O$yr, levels = 1700:1773)); ks <- table(O$key)
desc <- c(opg_years_occupied = sum(yc > 0), hh_per_year_min = min(yc), hh_per_year_med = median(yc), hh_per_year_max = max(yc),
          largest_year_share = max(yc) / sum(yc), opg2_n = nrow(O2), name_keys = length(ks), key_size_med = median(ks),
          key_size_p90 = unname(quantile(ks, 0.9)), key_size_max = max(ks))
print(desc); write.csv(data.frame(stat = names(desc), value = desc), "P27_RW/modern/output/descriptives_opgaaf.csv", row.names = FALSE)
print(table(group = I$group, s = cut(I$s, c(-1, 0, 4, 5, 15, 16, 1e4))))
print(table(I$date == I$yr))
