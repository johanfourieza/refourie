# P23_MBF S6: shared definitions for Table 5 (card §3, §4B). Sourced by 02_t5_firth.R and 04_sensitivities_t5.R.
GEO4 <- c("lat", "lon", "coast", "river", "meanalt", "tsi", "meantemp")
PRE  <- c("centralization", "agricintensity", "d_settlement", "hierarchy", "pop1800", "d_slavery")
C4_VARS <- c("d_birth", "d_mission", GEO4, PRE, "d_capital", "iso2")
mkf <- function(rhs) as.formula(paste("d_birth ~", paste(rhs, collapse = " + ")))
F_C4     <- mkf(c("d_mission", GEO4, PRE, "d_capital", "factor(iso2)"))          # printed col 4 (A')
F_C4_NOC <- mkf(c("d_mission", GEO4, PRE, "factor(iso2)"))                       # surviving code col 4 (S18)
F_C1     <- mkf("d_mission")                                                     # printed col 1
F_C2     <- mkf(c("d_mission", "factor(iso2)"))                                  # printed col 2
F_C3     <- mkf(c("d_mission", "lat", "lon", "coast", "river", "tsi", "factor(iso2)"))  # printed col 3 (A')
TABLE1_ISO <- c(BEN = 3, GHA = 8, GIN = 9, KEN = 11, MLI = 13, MWI = 15, SEN = 19, SLE = 20, TZA = 23, UGA = 24, ZMB = 25)

# printed col 4 sample: complete cases on all model variables, then drop countries where d_birth is constant
t5_samples <- function(d) {
  cc <- d |> dplyr::select(dplyr::any_of(c("fid", "name")), dplyr::all_of(C4_VARS)) |> tidyr::drop_na(dplyr::all_of(C4_VARS))
  s64 <- cc |> dplyr::group_by(iso2) |> dplyr::filter(dplyr::n_distinct(d_birth) > 1) |> dplyr::ungroup()
  list(cc = cc, s64 = s64)
}

# Firth with PL inference for one coefficient, convergence checks and the prespecified recovery (card §4B)
firth_pl <- function(f, dat, var = "d_mission", log_prefix = "") {
  rec <- character(0)
  ctl <- logistf::logistf.control(maxit = 1000)
  plc <- logistf::logistpl.control(maxit = 1000)
  fit <- logistf::logistf(f, data = dat, firth = TRUE, pl = TRUE, control = ctl, plcontrol = plc)
  i <- which(names(coef(fit)) == var)
  conv_full_fn <- function(fx, ctl) {
    is.finite(coef(fx)[i]) && fx$iter[["full"]] < ctl$maxit &&
      fx$conv[1] <= ctl$lconv && fx$conv[2] <= ctl$gconv && fx$conv[3] <= ctl$xconv
  }
  if (!conv_full_fn(fit, ctl)) {           # R1
    rec <- c(rec, "R1")
    ctl <- logistf::logistf.control(maxit = 10000, maxstep = ctl$maxstep / 2)
    fit <- logistf::logistf(f, data = dat, firth = TRUE, pl = TRUE, control = ctl, plcontrol = plc)
  }
  conv_full <- conv_full_fn(fit, ctl)
  pli <- fit$pl.iter[i, ]
  conv_null <- pli[["Null model"]] < plc$maxit
  conv_lo <- is.finite(fit$ci.lower[i]) && pli[["Lower"]] < plc$maxit
  conv_hi <- is.finite(fit$ci.upper[i]) && pli[["Upper"]] < plc$maxit
  if (!conv_lo || !conv_hi) {              # R2: profile for var only
    rec <- c(rec, "R2")
    plc2 <- logistf::logistpl.control(maxit = 10000, maxstep = plc$maxstep / 2)
    fit2 <- logistf::logistf(f, data = dat, firth = TRUE, pl = TRUE, control = ctl, plcontrol = plc2, plconf = i)
    pli2 <- fit2$pl.iter[1, ]
    fit$ci.lower[i] <- fit2$ci.lower[i]; fit$ci.upper[i] <- fit2$ci.upper[i]
    conv_lo <- is.finite(fit2$ci.lower[i]) && pli2[["Lower"]] < plc2$maxit
    conv_hi <- is.finite(fit2$ci.upper[i]) && pli2[["Upper"]] < plc2$maxit
  }
  res <- list(beta = unname(coef(fit)[i]), ci_lo = unname(fit$ci.lower[i]), ci_hi = unname(fit$ci.upper[i]),
              p = unname(fit$prob[i]), wald_se = unname(sqrt(diag(vcov(fit)))[i]),
              conv_full = conv_full, conv_null = conv_null, conv_lo = conv_lo, conv_hi = conv_hi,
              n = nrow(dat), events = sum(dat$d_birth))
  if (length(rec)) message(log_prefix, ": recovery ", paste(rec, collapse = ","))
  list(fit = fit, res = res, recovery = if (length(rec)) paste(rec, collapse = ",") else "none")
}

# verdict rules, card §8 (H3-OR uses b0 = 9.10, floor 4.55)
verdict_h3or <- function(beta, p, lo, hi, supported = TRUE) {
  floor <- 0.5 * 9.10
  if (!supported) return(c("not-testable", "0"))
  if (beta < 0 && p < .05) return(c("overturned (reversed)", "1"))
  if (lo > -floor && hi < floor) return(c("overturned (credible null)", "2"))
  if (beta > 0 && p < .05 && beta >= floor) return(c("confirmed", "3"))
  if (beta > 0 && p < .05 && beta < floor) return(c("qualified (magnitude below the floor)", "4"))
  if (beta > 0 && p >= .05) return(c("weakened", "5"))
  c("weakened (direction lost)", "6")
}
verdict_h3p <- function(beta, p, supported = TRUE) {
  if (!supported) return(c("not-testable", "0"))
  if (beta > 0 && p < .05) return(c("confirmed", "1"))
  if (beta < 0 && p < .05) return(c("overturned (reversed)", "2"))
  if (beta > 0 && p >= .05) return(c("weakened", "3"))
  c("weakened (direction lost)", "4")
}
