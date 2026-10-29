#' Moving-average smoothing and forecasts.
#'
#' @param x Numeric vector of observed prices (oldest first).
#' @param window Window size: a positive integer no larger than `length(x)`.
#' @param h Number of steps to forecast (positive integer).
#' @return `moving_average` returns the trailing means (length
#'   `length(x) - window + 1`); `ma_forecast` repeats the last trailing
#'   mean `h` times.

moving_average <- function(x, window) {
  x <- validate_series(x)
  if (length(window) != 1 || is.na(window) || window != as.integer(window) ||
      window < 1 || window > length(x)) {
    stop("window must be a positive integer no larger than the series length")
  }
  window <- as.integer(window)
  n <- length(x)
  cs <- c(0, cumsum(x))
  (cs[(window + 1):(n + 1)] - cs[1:(n - window + 1)]) / window
}

ma_forecast <- function(x, h, window = 5) {
  x <- validate_series(x)
  if (length(h) != 1 || is.na(h) || h < 1 || h != as.integer(h)) {
    stop("h must be a positive integer")
  }
  ma <- moving_average(x, window)
  rep(ma[length(ma)], times = as.integer(h))
}
