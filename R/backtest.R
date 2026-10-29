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

#' Direction-aware evaluation of a `rolling_origin()` result.
#'
#' Directional accuracy needs the previous step *within the same fold*:
#' for horizon 1 that is the fold's `last_train`, otherwise the previous
#' horizon's actual (for the actual direction) or forecast (for the
#' forecast direction). Pooling rows across folds without this would
#' compare a fold's first step against the previous fold's last step,
#' which never happened.
#'
#' @param bt A data.frame from `rolling_origin()`.
#' @return A list with `overall` (one-row data.frame of metrics over all
#'   backtest rows) and `by_horizon` (one row per horizon step).

evaluate_backtest <- function(bt) {
  required <- c("fold", "horizon", "actual", "forecast", "last_train")
  if (!all(required %in% names(bt))) {
    stop("backtest result must have columns: ",
         paste(required, collapse = ", "))
  }
  bt <- bt[order(bt$fold, bt$horizon), ]
  prev_actual <- numeric(nrow(bt))
  prev_forecast <- numeric(nrow(bt))
  for (i in seq_len(nrow(bt))) {
    if (bt$horizon[i] == 1) {
      prev_actual[i] <- bt$last_train[i]
      prev_forecast[i] <- bt$last_train[i]
    } else {
      prev_actual[i] <- bt$actual[i - 1]
      prev_forecast[i] <- bt$forecast[i - 1]
    }
  }
  direction_ok <- sign(bt$actual - prev_actual) ==
    sign(bt$forecast - prev_forecast)
  overall <- data.frame(
    n = nrow(bt),
    mae = mae(bt$actual, bt$forecast),
    rmse = rmse(bt$actual, bt$forecast),
    mape = mape(bt$actual, bt$forecast),
    directional_accuracy = mean(direction_ok)
  )
  by_horizon <- do.call(rbind, lapply(sort(unique(bt$horizon)),
                                      function(k) {
    rows <- bt$horizon == k
    data.frame(
      horizon = k,
      n = sum(rows),
      mae = mae(bt$actual[rows], bt$forecast[rows]),
      rmse = rmse(bt$actual[rows], bt$forecast[rows]),
      mape = mape(bt$actual[rows], bt$forecast[rows]),
      directional_accuracy = mean(direction_ok[rows])
    )
  }))
  list(overall = overall, by_horizon = by_horizon)
}
