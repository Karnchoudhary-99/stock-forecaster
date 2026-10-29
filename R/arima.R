#' Autoregressive forecasts: AR(p) and ARIMA(p, d, 0).
#'
#' Coefficients are fitted by ordinary least squares on lagged values
#' (base R `stats::lm`, no extra packages). Moving-average terms (q > 0)
#' are not supported: the `order` argument must have q = 0.
#'
#' @param x Numeric vector of observed prices (oldest first).
#' @param h Number of steps to forecast (positive integer).
#' @param p AR order: a positive integer.
#' @param d Differencing order: 0 or 1.
#' @param order Integer vector `c(p, d, q)` for `arima_forecast`; q must be 0.

check_p <- function(p) {
  if (length(p) != 1 || is.na(p) || p < 1 || p != as.integer(p)) {
    stop("p must be a positive integer")
  }
  as.integer(p)
}

ar_fit <- function(x, p = 1, d = 0) {
  x <- validate_series(x)
  p <- check_p(p)
  if (!(length(d) == 1 && d %in% c(0, 1))) {
    stop("d must be 0 or 1")
  }
  m <- if (d == 1) diff(x) else x
  if (length(m) <= p) {
    stop("series too short for AR(", p, ") after differencing")
  }
  rows <- length(m) - p
  y <- m[(p + 1):length(m)]
  lag_mat <- matrix(NA_real_, nrow = rows, ncol = p)
  for (j in seq_len(p)) {
    lag_mat[, j] <- m[(p + 1 - j):(length(m) - j)]
  }
  colnames(lag_mat) <- paste0("lag", seq_len(p))
  df <- data.frame(y = y, lag_mat, check.names = FALSE)
  fit <- stats::lm(y ~ ., data = df)
  coefs <- stats::coef(fit)
  if (any(is.na(coefs))) {
    stop("AR fit is rank-deficient: series has too little variation for AR(",
         p, ")")
  }
  list(intercept = unname(coefs[1]), phi = unname(coefs[-1]), p = p, d = d,
       last_diff = utils::tail(m, p),
       last_level = if (d == 1) x[length(x)] else NULL,
       fitted = unname(stats::fitted(fit)),
       residuals = unname(stats::residuals(fit)))
}

ar_forecast <- function(x, h, p = 1, d = 0) {
  x <- validate_series(x)
  h <- check_h(h)
  fit <- ar_fit(x, p, d)
  history <- fit$last_diff
  diff_forecast <- numeric(h)
  for (step in seq_len(h)) {
    lags <- rev(utils::tail(history, fit$p))
    next_value <- fit$intercept + sum(fit$phi * lags)
    diff_forecast[step] <- next_value
    history <- c(history, next_value)
  }
  if (fit$d == 1) {
    fit$last_level + cumsum(diff_forecast)
  } else {
    diff_forecast
  }
}

arima_forecast <- function(x, h, order = c(1, 0, 0)) {
  if (length(order) != 3) {
    stop("order must be c(p, d, q)")
  }
  if (order[3] != 0) {
    stop("only ARIMA(p, d, 0) is supported (q must be 0)")
  }
  ar_forecast(x, h, p = order[1], d = order[2])
}
