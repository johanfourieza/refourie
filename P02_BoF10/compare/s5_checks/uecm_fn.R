# UECM bounds F, case III; p = lag order (p-1 lagged differences of y and x, plus dx_t); theta = -b_x/b_y with OLS delta SE
uecm <- function(Y, X, p = 4) { ok <- !is.na(Y) & !is.na(X); r <- range(which(ok)); Y <- Y[r[1]:r[2]]; X <- X[r[1]:r[2]]
  n <- length(Y); k <- p - 1; dY <- diff(Y); dX <- diff(X); idx <- (k + 1):(n - 1)
  df <- data.frame(dy = dY[idx], ylag = Y[idx], xlag = X[idx], dx0 = dX[idx])
  for (i in seq_len(k)) { df[[paste0("dyl", i)]] <- dY[idx - i]; df[[paste0("dxl", i)]] <- dX[idx - i] }
  m1 <- lm(dy ~ ., df); m0 <- lm(dy ~ . - ylag - xlag, df); b <- coef(m1); V <- vcov(m1)[c("ylag","xlag"), c("ylag","xlag")]
  g <- c(b["xlag"]/b["ylag"]^2, -1/b["ylag"])
  c(F = anova(m0, m1)$F[2], theta = unname(-b["xlag"]/b["ylag"]), se = sqrt(drop(t(g) %*% V %*% g)), n = nrow(df)) }
