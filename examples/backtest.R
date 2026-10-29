# Backtest every model on the bundled sample series and rank by RMSE.
# Run from the repo root: Rscript examples/backtest.R
source("R/baseline.R")
source("R/data.R")
source("R/moving_average.R")
source("R/smoothing.R")
source("R/arima.R")
source("R/forecast.R")
source("R/metrics.R")
source("R/backtest.R")

prices <- load_prices("data/sample-prices.csv")
x <- prices$close
h <- 5
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

cat(sprintf("sample series: %d days; backtest h = %d, initial = %d, step = %d\n\n",
            length(x), h, initial, step))
results <- do.call(rbind, lapply(names(methods), function(name) {
  bt <- do.call(rolling_origin,
                c(list(x, h, initial, step, name), methods[[name]]))
  ev <- evaluate_backtest(bt)
  data.frame(method = name, ev$overall)
}))
results <- results[order(results$rmse), ]
print(results, row.names = FALSE, digits = 4)
cat("\nBest by RMSE:", results$method[1], "\n")
