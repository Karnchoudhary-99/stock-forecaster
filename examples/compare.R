# Compare every model on the bundled sample series.
# Run from the repo root: Rscript examples/compare.R
source("R/baseline.R")
source("R/data.R")
source("R/moving_average.R")
source("R/smoothing.R")
source("R/arima.R")
source("R/forecast.R")

prices <- load_prices("data/sample-prices.csv")
x <- prices$close
h <- 5
cat("sample series:", length(x), "days, last close =", x[length(x)], "\n\n")

methods <- list(
  naive = list(),
  mean = list(),
  ma = list(window = 5),
  ses = list(),
  holt = list(),
  ar = list(p = 2),
  arima = list(order = c(1, 1, 0))
)
for (name in names(methods)) {
  fc <- do.call(forecast_price,
                c(list(x, h, name), methods[[name]]))
  cat(sprintf("%-6s %s\n", name, paste(round(fc, 2), collapse = "  ")))
}
