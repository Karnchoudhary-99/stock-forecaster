#' Baseline forecasts every fancier model must beat.
#'
#' @param x Numeric vector of observed prices (oldest first).
#' @param h Number of steps to forecast (positive integer).
#' @return Numeric vector of length `h`.

naive_forecast <- function(x, h) {
  stopifnot(is.numeric(x), length(x) >= 1, h >= 1)
  rep(x[length(x)], times = h)
}

mean_forecast <- function(x, h) {
  stopifnot(is.numeric(x), length(x) >= 1, h >= 1)
  rep(mean(x), times = h)
}
