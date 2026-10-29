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
