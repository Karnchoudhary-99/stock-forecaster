# Build a full forecast report for the bundled sample series.
# Run from the repo root: Rscript examples/report.R
# Writes docs/forecast-report.md (committed, linked from the README).
source("R/baseline.R")
source("R/data.R")
source("R/moving_average.R")
source("R/smoothing.R")
source("R/arima.R")
source("R/forecast.R")
source("R/metrics.R")
source("R/backtest.R")
source("R/report.R")

prices <- load_prices("data/sample-prices.csv")
x <- prices$close
h <- 10
initial <- 90
step <- 5

methods <- list(
  naive = list(),
  mean = list(),
  ma = list(window = 5),
  ses = list(),
  holt = list(),
  ar = list(p = 2),
  arima = list(order = c(1, 1, 0))
)
forecasts <- lapply(names(methods), function(name) {
  do.call(forecast_price, c(list(x, h, name), methods[[name]]))
})
names(forecasts) <- names(methods)

backtest <- do.call(rbind, lapply(names(methods), function(name) {
  bt <- do.call(rolling_origin,
                c(list(x, h, initial, step, name), methods[[name]]))
  ev <- evaluate_backtest(bt)
  data.frame(method = name, ev$overall)
}))

write_forecast_report("docs/forecast-report.md", x, forecasts, backtest,
                      title = "Forecast report: sample series")
cat("wrote docs/forecast-report.md\n")
cat(sprintf("best by backtest RMSE: %s\n",
            backtest$method[which.min(backtest$rmse)]))
