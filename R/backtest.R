#' Rolling-origin (expanding-window) backtesting.
#'
#' Each fold trains on `x[1:origin]` and forecasts the next `h` values,
#' which are then compared against what actually happened. Origins start
#' at `initial` and advance by `step`, so folds overlap when `step < h`
#' and are disjoint when `step >= h`. Only complete folds are kept: an
#' origin is used only when `origin + h <= length(x)`.
#'
#' @param x Numeric vector of observed prices (oldest first).
#' @param h Forecast horizon (positive integer).
#' @param initial Size of the first training window (positive integer).
#' @param step How far the origin advances between folds (positive integer).
#' @param method Model name passed to `forecast_price`.
#' @param ... Model parameters passed to `forecast_price`.
#' @return A data.frame with one row per fold and horizon step:
#'   `fold`, `origin`, `horizon`, `actual`, `forecast`, `last_train`
#'   (the last training value of that fold, needed for directional
#'   accuracy).

rolling_origin <- function(x, h, initial, step = 1, method, ...) {
  x <- validate_series(x)
  h <- check_h(h)
  if (length(initial) != 1 || is.na(initial) || initial < 1 ||
      initial != as.integer(initial)) {
    stop("initial must be a positive integer")
  }
  if (length(step) != 1 || is.na(step) || step < 1 ||
      step != as.integer(step)) {
    stop("step must be a positive integer")
  }
  initial <- as.integer(initial)
  step <- as.integer(step)
  n <- length(x)
  if (initial + h > n) {
    stop("no complete folds: initial + h must not exceed the series length")
  }
  origins <- seq(initial, n - h, by = step)
  rows <- lapply(seq_along(origins), function(fold) {
    origin <- origins[fold]
    train <- x[1:origin]
    fc <- forecast_price(train, h, method, ...)
    data.frame(
      fold = fold,
      origin = origin,
      horizon = 1:h,
      actual = x[(origin + 1):(origin + h)],
      forecast = fc,
      last_train = train[origin]
    )
  })
  do.call(rbind, rows)
}
