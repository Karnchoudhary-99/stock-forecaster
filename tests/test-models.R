# Tests for the model suite. Run from the repo root: Rscript tests/run_all.R
source("R/baseline.R")
source("R/data.R")
source("R/moving_average.R")
source("R/smoothing.R")
source("R/arima.R")
source("R/forecast.R")

expect_error <- function(expr) {
  err <- tryCatch({ force(expr); NULL }, error = function(cond) cond)
  stopifnot(!is.null(err))
}

near <- function(a, b, tol = 1e-6) all(abs(a - b) < tol)

# Moving average.
stopifnot(all(moving_average(c(1, 2, 3, 4), 2) == c(1.5, 2.5, 3.5)))
stopifnot(all(ma_forecast(c(10, 20, 30), 2, window = 2) == c(25, 25)))
expect_error(ma_forecast(c(10, 20), 2, window = 5))

# SES with alpha = 1 is exactly the naive forecast; a constant series
# keeps its level and has zero one-step error.
x <- c(100, 102, 101, 105, 103)
stopifnot(all(ses_forecast(x, 3, alpha = 1) == c(103, 103, 103)))
fit_const <- ses_fit(rep(50, 10))
stopifnot(fit_const$level == 50, fit_const$sse == 0)

# Holt with alpha = beta = 1 reproduces a perfect linear trend.
trend <- c(10, 12, 14, 16, 18)
stopifnot(all(holt_forecast(trend, 2, alpha = 1, beta = 1) == c(20, 22)))
# Fitted Holt on the same trend must find a positive trend.
fit_trend <- holt_fit(trend)
stopifnot(fit_trend$trend > 0)
expect_error(holt_forecast(c(5), 2))

# AR(1) recovers an exact noise-free recurrence x_t = 2 + 0.5 * x_{t-1}.
ar_series <- numeric(50)
ar_series[1] <- 10
for (t in 2:50) ar_series[t] <- 2 + 0.5 * ar_series[t - 1]
fit_ar <- ar_fit(ar_series, p = 1)
stopifnot(near(fit_ar$intercept, 2), near(fit_ar$phi, 0.5))
stopifnot(near(ar_forecast(ar_series, 1, p = 1),
               2 + 0.5 * ar_series[50]))

# ARIMA(1, 1, 0) on a cumulated AR(1) difference series.
diffs <- numeric(50)
diffs[1] <- 1
for (t in 2:50) diffs[t] <- 1 + 0.5 * diffs[t - 1]
cum_series <- cumsum(c(100, diffs))
fc <- arima_forecast(cum_series, 2, order = c(1, 1, 0))
next_diff <- 1 + 0.5 * diffs[50]
stopifnot(near(fc[1], cum_series[51] + next_diff))
expect_error(arima_forecast(cum_series, 1, order = c(1, 0, 1)))

# Dispatcher routes every method and rejects unknown ones.
stopifnot(all(forecast_price(x, 2, "naive") == c(103, 103)))
stopifnot(all(forecast_price(x, 2, "mean") == rep(mean(x), 2)))
stopifnot(all(forecast_price(x, 2, "ma", window = 2) == c(104, 104)))
stopifnot(length(forecast_price(x, 3, "ses")) == 3)
stopifnot(length(forecast_price(x, 3, "holt")) == 3)
stopifnot(length(forecast_price(x, 3, "ar", p = 1)) == 3)
expect_error(forecast_price(x, 2, "prophet"))
expect_error(forecast_price(x, 0, "naive"))

cat("test-models ok\n")
