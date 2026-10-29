#' Exponential smoothing: simple (SES) and Holt linear trend.
#'
#' Parameters are fitted by grid search minimising the one-step-ahead
#' sum of squared errors on the observed series. With `alpha = 1`, SES
#' reduces exactly to the naive forecast; with `alpha = 1, beta = 1`,
#' Holt reproduces a perfect linear trend.
#'
#' @param x Numeric vector of observed prices (oldest first).
#' @param h Number of steps to forecast (positive integer).
#' @param alpha Smoothing parameter in (0, 1]; `NULL` fits it by grid search.
#' @param beta Trend smoothing parameter in (0, 1]; `NULL` fits it by grid search.

check_h <- function(h) {
  if (length(h) != 1 || is.na(h) || h < 1 || h != as.integer(h)) {
    stop("h must be a positive integer")
  }
  as.integer(h)
}

check_param <- function(value, name) {
  if (length(value) != 1 || is.na(value) || value <= 0 || value > 1) {
    stop(name, " must be a single number in (0, 1]")
  }
  value
}

ses_fit <- function(x, alpha = NULL) {
  x <- validate_series(x)
  if (is.null(alpha)) {
    best <- NULL
    for (a in seq(0.01, 0.99, by = 0.01)) {
      level <- x[1]
      sse <- 0
      if (length(x) > 1) {
        for (t in 2:length(x)) {
          sse <- sse + (x[t] - level)^2
          level <- a * x[t] + (1 - a) * level
        }
      }
      if (is.null(best) || sse < best$sse) {
        best <- list(level = level, alpha = a, sse = sse)
      }
    }
    return(best)
  }
  alpha <- check_param(alpha, "alpha")
  level <- x[1]
  sse <- 0
  if (length(x) > 1) {
    for (t in 2:length(x)) {
      sse <- sse + (x[t] - level)^2
      level <- alpha * x[t] + (1 - alpha) * level
    }
  }
  list(level = level, alpha = alpha, sse = sse)
}

ses_forecast <- function(x, h, alpha = NULL) {
  x <- validate_series(x)
  h <- check_h(h)
  fit <- ses_fit(x, alpha)
  rep(fit$level, times = h)
}

holt_fit <- function(x, alpha = NULL, beta = NULL) {
  x <- validate_series(x)
  if (length(x) < 2) {
    stop("Holt smoothing needs at least 2 observations")
  }
  fit_one <- function(a, b) {
    level <- x[1]
    trend <- x[2] - x[1]
    sse <- 0
    for (t in 2:length(x)) {
      sse <- sse + (x[t] - (level + trend))^2
      prev_level <- level
      level <- a * x[t] + (1 - a) * (level + trend)
      trend <- b * (level - prev_level) + (1 - b) * trend
    }
    list(level = level, trend = trend, alpha = a, beta = b, sse = sse)
  }
  if (!is.null(alpha) && !is.null(beta)) {
    return(fit_one(check_param(alpha, "alpha"), check_param(beta, "beta")))
  }
  grid <- seq(0.05, 0.95, by = 0.05)
  alphas <- if (is.null(alpha)) grid else check_param(alpha, "alpha")
  betas <- if (is.null(beta)) grid else check_param(beta, "beta")
  best <- NULL
  for (a in alphas) {
    for (b in betas) {
      fit <- fit_one(a, b)
      if (is.null(best) || fit$sse < best$sse) {
        best <- fit
      }
    }
  }
  best
}

holt_forecast <- function(x, h, alpha = NULL, beta = NULL) {
  x <- validate_series(x)
  h <- check_h(h)
  fit <- holt_fit(x, alpha, beta)
  fit$level + fit$trend * seq_len(h)
}
