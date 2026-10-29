# Plot every model forecasting the bundled sample series, h = 10.
# Run from the repo root: Rscript examples/plot.R
# Writes docs/forecast-plot.svg (committed, embedded in the README).
source("R/baseline.R")
source("R/data.R")
source("R/moving_average.R")
source("R/smoothing.R")
source("R/arima.R")
source("R/forecast.R")
source("R/plot.R")

prices <- load_prices("data/sample-prices.csv")
x <- prices$close
h <- 10

methods <- list(
  naive = list(),
  ma = list(window = 5),
  ses = list(),
  holt = list(),
  ar = list(p = 2),
  arima = list(order = c(1, 1, 0))
)
forecasts <- lapply(methods, function(args) {
  do.call(forecast_price, c(list(x, h), args))
})
# Keep the chart readable: history + the two most distinct forecasts.
# (All six forecasts are tabulated in the report example instead.)
shown <- forecasts[c("naive", "holt")]
write_forecast_svg("docs/forecast-plot.svg", x, shown,
                   title = "Sample series: history + 10-step forecasts")
cat("wrote docs/forecast-plot.svg\n")
cat(sprintf("last price %.2f; naive 10-step %.2f; holt 10-step %.2f\n",
            x[length(x)], shown$naive[h], shown$holt[h]))
