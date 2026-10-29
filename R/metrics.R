#' Forecast error metrics.
#'
#' All functions take an `actual` vector and a `forecast` vector of the
#' same length (oldest first). MAPE is undefined when any actual value
#' is zero, so it errors in that case instead of silently returning Inf.

check_forecast_pair <- function(actual, forecast) {
  actual <- validate_series(actual)
  if (!is.numeric(forecast) || length(forecast) < 1 ||
      !all(is.finite(forecast))) {
    stop("forecast must be a non-empty numeric vector with no NA/NaN/Inf values")
  }
  if (length(actual) != length(forecast)) {
    stop("actual and forecast must have the same length")
  }
  list(actual = actual, forecast = forecast)
}

#' Mean absolute error.
mae <- function(actual, forecast) {
  pair <- check_forecast_pair(actual, forecast)
  mean(abs(pair$actual - pair$forecast))
}

#' Root mean squared error.
rmse <- function(actual, forecast) {
  pair <- check_forecast_pair(actual, forecast)
  sqrt(mean((pair$actual - pair$forecast)^2))
}

#' Mean absolute percentage error, as a fraction (0.10 = 10%).
mape <- function(actual, forecast) {
  pair <- check_forecast_pair(actual, forecast)
  if (any(pair$actual == 0)) {
    stop("MAPE is undefined when an actual value is zero")
  }
  mean(abs((pair$actual - pair$forecast) / pair$actual))
}

#' Directional accuracy: the fraction of steps where the forecast moves
#' in the same direction as the actual, relative to `last` (the last
#' observed value before the forecast window). A flat step counts as its
#' own direction, so a flat forecast on a moving series scores 0 for
#' those steps rather than getting credit for "no move".
directional_accuracy <- function(actual, forecast, last) {
  pair <- check_forecast_pair(actual, forecast)
  if (length(last) != 1 || !is.numeric(last) || !is.finite(last)) {
    stop("last must be a single finite number")
  }
  actual_dir <- sign(diff(c(last, pair$actual)))
  forecast_dir <- sign(diff(c(last, pair$forecast)))
  mean(actual_dir == forecast_dir)
}

#' All metrics for one forecast as a single-row data.frame. When `last`
#' is supplied, directional accuracy is included; otherwise it is NA.
evaluate_forecast <- function(actual, forecast, last = NULL) {
  pair <- check_forecast_pair(actual, forecast)
  directional <- if (is.null(last)) NA_real_ else {
    directional_accuracy(pair$actual, pair$forecast, last)
  }
  data.frame(
    n = length(pair$actual),
    mae = mae(pair$actual, pair$forecast),
    rmse = rmse(pair$actual, pair$forecast),
    mape = mape(pair$actual, pair$forecast),
    directional_accuracy = directional
  )
}
