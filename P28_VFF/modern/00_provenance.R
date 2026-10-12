# P28_VFF S6 Step 0: night-lights provenance (card §4 Step 0).
# Inputs: public DMSP-OLS v4 stable-lights composites F121996.v4b and F182011.v4c (NOAA NGDC tar files,
# retrieved from the Internet Archive's captures of the original NOAA URLs because NOAA/EOG now requires a login;
# see DEVIATIONS.md D1), the EOG intercalibration coefficient table, and the authors' 1911 polygons.
# Downloads are untrusted data: only tar (list/extract), gzip decompression and GDAL raster reads touch them.
# Writes: modern/provenance.csv, output/lights_extracted.csv, output/step0.csv.
source("./P28_VFF/modern/common.R")
suppressPackageStartupMessages({ library(terra); library(digest) })
DL <- dpath("P28_VFF", "modern", "_downloads"); EX <- file.path(DL, "extracted"); dir.create(EX, showWarnings = FALSE)   # A6: downloads on D:

# ---------------- 1. provenance of the downloaded files ----------------
b32 <- function(raw) {                      # RFC 4648 base32 (Wayback CDX digest = base32(SHA-1(payload)))
  alph <- c(LETTERS, as.character(2:7)); bits <- as.integer(rawToBits(raw)); bits <- matrix(bits, 8)[8:1, ]
  bits <- as.vector(bits); pad <- (5 - length(bits) %% 5) %% 5; bits <- c(bits, rep(0L, pad))
  paste(alph[colSums(matrix(bits, 5) * c(16, 8, 4, 2, 1)) + 1], collapse = "")
}
src <- data.frame(
  file = c("F121996.v4.tar", "F182011.v4.tar", "v4c_2nd_order_sicily_x1to62_y1to63.20160114.csv", "radcal_readme.txt"),
  url = c("http://web.archive.org/web/20170530155417id_/https://www.ngdc.noaa.gov/eog/data/web_data/v4composites/F121996.v4.tar",
          "http://web.archive.org/web/20170530183827id_/https://www.ngdc.noaa.gov/eog/data/web_data/v4composites/F182011.v4.tar",
          "https://eogdata.mines.edu/dmsp/v4c_2nd_order_sicily_x1to62_y1to63.20160114.csv",
          "https://eogdata.mines.edu/dmsp/radcal_readme.txt"),
  original_url = c("https://www.ngdc.noaa.gov/eog/data/web_data/v4composites/F121996.v4.tar",
                   "https://www.ngdc.noaa.gov/eog/data/web_data/v4composites/F182011.v4.tar", "(same)", "(same)"),
  wayback_cdx_sha1_b32 = c("BMFQ5FXPOJWWOV25TC3S7ZOODCMEXPXK", "4TZMVGLYCQ4HBVT2DWY4RHJTOBZ5BUN4", NA, NA),
  wayback_note = c("same payload digest in 19 Wayback captures 2017-05-30 to 2026-04-26 (CDX query 2026-10-11)",
                   "same payload digest in 19 Wayback captures 2017-05-30 to 2026-04-27 (CDX query 2026-10-11)",
                   "public on EOG without login; linked from https://eogdata.mines.edu/products/dmsp/ (Intercalibration)", "public on EOG"),
  retrieved = "2026-10-11")
src$size_bytes <- file.size(file.path(DL, src$file))
src$sha256 <- sapply(src$file, function(f) digest(file = file.path(DL, f), algo = "sha256"))
src$sha1_b32 <- sapply(src$file, function(f) b32(digest(file = file.path(DL, f), algo = "sha1", raw = TRUE)))
src$digest_match <- ifelse(is.na(src$wayback_cdx_sha1_b32), NA, src$sha1_b32 == src$wayback_cdx_sha1_b32)
print(src[, c("file", "size_bytes", "sha256", "digest_match")])
stopifnot(all(src$digest_match[1:2]))

# ---------------- 2. extract the stable_lights.avg_vis layer (tar, then gunzip) ----------------
tif <- c()
for (yr in c("F121996", "F182011")) {
  tarf <- file.path(DL, paste0(yr, ".v4.tar"))
  mem <- system2("tar", c("-tf", shQuote(tarf)), stdout = TRUE)
  m <- mem[grepl("stable_lights\\.avg_vis\\.tif(\\.gz)?$", mem) & !grepl("intercal", mem)]
  stopifnot(length(m) == 1)
  tfw <- mem[mem == sub("\\.tif(\\.gz)?$", ".tfw", m)]       # world file, if shipped
  for (x in c(m, tfw)) if (!file.exists(file.path(EX, x))) system2("tar", c("-xf", shQuote(tarf), "-C", shQuote(EX), shQuote(x)))
  f <- file.path(EX, m)
  if (grepl("\\.gz$", f)) {
    out <- sub("\\.gz$", "", f)
    if (!file.exists(out)) { zin <- gzfile(f, "rb"); zout <- file(out, "wb")
      repeat { b <- readBin(zin, "raw", 2^24); if (!length(b)) break; writeBin(b, zout) }
      close(zin); close(zout) }
    f <- out
  }
  src <- rbind(src, data.frame(file = file.path("extracted", basename(f)), url = paste0("member '", m, "' of ", basename(tarf)),
    original_url = NA, wayback_cdx_sha1_b32 = NA, wayback_note = paste("tar members:", paste(mem, collapse = "; ")),
    retrieved = "2026-10-11", size_bytes = file.size(f), sha256 = digest(file = f, algo = "sha256"), sha1_b32 = NA, digest_match = NA))
  tif[yr] <- f
}
write.csv(src, file.path(MOD, "provenance.csv"), row.names = FALSE)

# ---------------- 3. crop to South Africa and compute district means ----------------
shp <- st_read(file.path(ORIG, "1911_dc.shp"), quiet = TRUE)
v <- vect(shp)
bb <- ext(v) + 0.1
cal <- read.csv(file.path(DL, "v4c_2nd_order_sicily_x1to62_y1to63.20160114.csv"), check.names = FALSE)
names(cal) <- trimws(names(cal))
coef_of <- function(key) { r <- cal[startsWith(cal$`X-File`, key), ]; stopifnot(nrow(r) == 1)
  c(c0 = r$Coefficient0, c1 = r$Coefficient1, c2 = r$Coefficient2) }
cc <- list(F121996 = coef_of("F121996.v4b"), F182011 = coef_of("F182011.v4c"))
vals_info <- list(); ex <- data.frame(id = shp$ID, NAME = shp$NAME)
for (yr in names(tif)) {
  r <- rast(tif[[yr]])
  rc <- crop(r, bb)
  writeRaster(rc, file.path(SCR, paste0(yr, "_SA.tif")), overwrite = TRUE)
  u <- freq(rc)
  vals_info[[yr]] <- data.frame(year = yr, n_cells = ncell(rc), n_na = global(is.na(rc), "sum")[1, 1],
    n_gt63 = sum(u$count[u$value > 63]), min = min(u$value), max = max(u$value), crs = crs(rc, describe = TRUE)$name,
    res_deg = res(rc)[1], declared_nodata = paste(NAflag(rc), collapse = ","))
  rc[rc > 63] <- NA                                          # no-data pixels excluded (none expected)
  k <- cc[[yr]]
  rcal <- k[["c0"]] + k[["c1"]] * rc + k[["c2"]] * rc^2
  rcal <- ifel(rc > 0, ifel(rcal > 63, 63, rcal), 0)        # DEVIATIONS D3: DN 0 kept at 0; cap at 63
  # mean over pixels whose centres fall inside each polygon (terra default for polygons), DN 0 included
  m_raw <- terra::extract(rc, v, fun = mean, na.rm = TRUE, ID = FALSE)[, 1]
  m_cal <- terra::extract(rcal, v, fun = mean, na.rm = TRUE, ID = FALSE)[, 1]
  npx   <- terra::extract(!is.na(rc), v, fun = sum, na.rm = TRUE, ID = FALSE)[, 1]
  tag <- if (yr == "F121996") "96" else "11"
  ex[[paste0("ext", tag, "_raw")]] <- m_raw; ex[[paste0("ext", tag, "_cal")]] <- m_cal; ex[[paste0("npix", tag)]] <- npx
}
print(bind_rows(vals_info))
write.csv(bind_rows(vals_info), file.path(SCR, "raster_info.csv"), row.names = FALSE)
write.csv(ex, file.path(OUT, "lights_extracted.csv"), row.names = FALSE)

# ---------------- 4. match to data.csv lig96 / lig11 on the 138 analysis districts ----------------
dcsv <- read.csv(file.path(ORIG, "data.csv"))
d <- load_data()
m <- d[, c("id", "lig96", "lig11")] |> left_join(ex, by = "id")
stopifnot(nrow(m) == 138, !anyNA(m$ext96_raw), !anyNA(m$ext11_raw))
lc <- function(a, b) cor(log(a + 0.01), log(b + 0.01))
r_orig  <- c(lc(m$ext96_raw, m$lig96), lc(m$ext11_raw, m$lig11))
r_cross <- c(lc(m$ext96_raw, m$lig11), lc(m$ext11_raw, m$lig96))
decision <- if (all(r_orig >= 0.99) && all(r_cross < 0.95)) "original" else
            if (all(r_cross >= 0.99) && all(r_orig < 0.95)) "relabel" else "unresolved"
s0 <- data.frame(item = c("cor_log_F121996_vs_lig96", "cor_log_F182011_vs_lig11", "cor_log_F121996_vs_lig11", "cor_log_F182011_vs_lig96",
                          "maxabs_F121996_minus_lig96", "maxabs_F182011_minus_lig11", "maxabs_F121996_minus_lig11", "maxabs_F182011_minus_lig96",
                          "median_ratio_F182011_over_F121996_raw", "median_ratio_F182011_over_F121996_cal", "n_districts", "decision"),
  value = c(r_orig, r_cross,
            max(abs(m$ext96_raw - m$lig96)), max(abs(m$ext11_raw - m$lig11)), max(abs(m$ext96_raw - m$lig11)), max(abs(m$ext11_raw - m$lig96)),
            median(m$ext11_raw / m$ext96_raw), median(m$ext11_cal / m$ext96_cal), nrow(m), decision))
write.csv(s0, file.path(OUT, "step0.csv"), row.names = FALSE)
print(s0)
cat("Calibration coefficients used:\n"); print(cc)
