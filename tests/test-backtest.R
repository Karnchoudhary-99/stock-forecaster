# Tests for R/backtest.R. Run from the repo root: Rscript tests/run_all.R
source("R/baseline.R")
source("R/data.R")
source("R/moving_average.R")
source("R/smoothing.R")
source("R/arima.R")
source("R/forecast.R")
source("R/metrics.R")
source("R/backtest.R")

expect_error <- function(expr) {
  err <- tryCatch({ force(expr); NULL }, error = function(cond) cond)
  stopifnot(!is.null(err))
}

near <- function(a, b, tol = 1e-9) all(abs(a - b) < tol)

# Naive on the exact trend 1:20, origins 10 and 15, horizon 2.
bt <- rolling_origin(1:20, 2, 10, 5, "naive")
stopifnot(nrow(bt) == 4, all(bt$fold == c(1, 1, 2, 2)),
          all(bt$origin == c(10, 10, 15, 15)),
          all(bt$horizon == c(1, 2, 1, 2)),
          all(bt$actual == c(11, 12, 16, 17)),
          all(bt$forecast == c(10, 10, 15, 15)),
          all(bt$last_train == c(10, 10, 15, 15)))

# Step 1 gives every origin; step >= h gives disjoint folds.
bt_step1 <- rolling_origin(1:20, 2, 10, 1, "naive")
stopifnot(all(unique(bt_step1$origin) == 10:18), nrow(bt_step1) == 18)
bt_mean <- rolling_origin(1:12, 3, 6, 3, "mean")
stopifnot(all(unique(bt_mean$origin) == c(6, 9)), nrow(bt_mean) == 6)

# Evaluation: naive overall MAE 1.5, per-horizon MAE 1 then 2, and a flat
# forecast on a rising series scores 0 directional accuracy.
ev <- evaluate_backtest(bt)
stopifnot(ev$overall$n == 4, near(ev$overall$mae, 1.5),
          near(ev$overall$rmse, sqrt(2.5)),
          ev$overall$directional_accuracy == 0)
stopifnot(all(ev$by_horizon$horizon == c(1, 2)),
          all(ev$by_horizon$mae == c(1, 2)),
          all(ev$by_horizon$directional_accuracy == 0))

# Holt reproduces the exact trend, so its backtest error is zero and its
# directional accuracy is perfect; per-fold first steps use last_train,
# not the previous fold's last row.
ev_holt <- evaluate_backtest(rolling_origin(1:20, 2, 10, 5, "holt"))
stopifnot(ev_holt$overall$mae == 0,
          ev_holt$overall$directional_accuracy == 1)

# Validation: no complete fold, bad initial/step, missing columns.
expect_error(rolling_origin(1:10, 3, 8, 1, "naive"))
expect_error(rolling_origin(1:20, 2, 0, 1, "naive"))
expect_error(rolling_origin(1:20, 2, 10, 0, "naive"))
expect_error(evaluate_backtest(data.frame(fold = 1, actual = 1)))
cat("test-backtest ok\n")
