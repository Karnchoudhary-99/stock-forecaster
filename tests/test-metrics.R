# Tests for R/metrics.R. Run from the repo root: Rscript tests/run_all.R
source("R/data.R")
source("R/metrics.R")

expect_error <- function(expr) {
  err <- tryCatch({ force(expr); NULL }, error = function(cond) cond)
  stopifnot(!is.null(err))
}

near <- function(a, b, tol = 1e-9) all(abs(a - b) < tol)

# MAE / RMSE / MAPE on a hand-computed pair.
actual <- c(100, 200)
forecast <- c(110, 180)
stopifnot(near(mae(actual, forecast), 15))
stopifnot(near(rmse(actual, forecast), sqrt(250)))
stopifnot(near(mape(actual, forecast), 0.1))

# A perfect forecast scores zero on every error metric.
stopifnot(mae(actual, actual) == 0, rmse(actual, actual) == 0,
          mape(actual, actual) == 0)

# Directional accuracy: both steps right, then one step right.
stopifnot(directional_accuracy(c(102, 101), c(103, 100), last = 100) == 1)
stopifnot(directional_accuracy(c(102, 101), c(103, 104), last = 100) == 0.5)
# A flat forecast on a moving series gets no directional credit.
stopifnot(directional_accuracy(c(102, 101), c(100, 100), last = 100) == 0)

# evaluate_forecast bundles the metrics; directional is NA without `last`.
row <- evaluate_forecast(actual, forecast)
stopifnot(row$n == 2, near(row$mae, 15), near(row$rmse, sqrt(250)),
          near(row$mape, 0.1), is.na(row$directional_accuracy))
row_dir <- evaluate_forecast(c(102, 101), c(103, 100), last = 100)
stopifnot(row_dir$directional_accuracy == 1)

# Validation: mismatched lengths, non-finite values, zero actual for MAPE.
expect_error(mae(c(1, 2), c(1)))
expect_error(rmse(c(1, 2), c(1, NA)))
expect_error(mape(c(0, 100), c(1, 100)))
expect_error(directional_accuracy(c(101), c(102), last = c(100, 100)))
cat("test-metrics ok\n")
