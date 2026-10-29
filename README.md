# Stock Price Forecaster

A stock price forecasting toolkit in R: time-series models, honest
backtesting, and forecast evaluation — built to be read, run, and
compared, not just fitted.

## Roadmap

- [x] Project scaffold (README roadmap, baseline models, smoke test, CI)
- [x] Data loading: CSV price series + validation
- [x] Models: naive, moving average, SES/Holt smoothing, AR/ARIMA(p,d,0)
- [ ] Backtesting: rolling-origin evaluation
- [ ] Metrics: MAE, RMSE, MAPE, directional accuracy
- [ ] Forecast plots + report, then self-review checklist, then public

## Quick start

```sh
Rscript tests/run_all.R    # full test suite (base R only, no packages)
Rscript examples/compare.R # every model forecasting the sample series
```

## Data loading

```r
source("R/data.R")
prices <- load_prices("data/sample-prices.csv")  # date, close
```

`load_prices()` requires `date` (YYYY-MM-DD) and `close` columns,
rejects missing files, missing columns, unparseable dates, non-numeric
or non-finite closes, and duplicate dates, and returns rows sorted by
date. `data/sample-prices.csv` is a bundled 120-day synthetic series,
regenerable with `python3 examples/make_sample.py` (seeded).

## Models

All models take a numeric price vector (oldest first) and return `h`
forecasts; `forecast_price(x, h, method, ...)` dispatches to any of them.

| Method | Function | Notes |
| --- | --- | --- |
| `naive` | `naive_forecast(x, h)` | Repeats the last price. |
| `mean` | `mean_forecast(x, h)` | Repeats the series mean. |
| `ma` | `ma_forecast(x, h, window = 5)` | Repeats the last trailing mean. |
| `ses` | `ses_forecast(x, h, alpha = NULL)` | Simple exponential smoothing; `alpha` grid-searched when omitted. |
| `holt` | `holt_forecast(x, h, alpha = NULL, beta = NULL)` | Holt linear trend; parameters grid-searched when omitted. |
| `ar` | `ar_forecast(x, h, p = 1, d = 0)` | AR(p) fitted by OLS on lagged values. |
| `arima` | `arima_forecast(x, h, order = c(p, d, 0))` | ARIMA(p, d, 0); MA terms (q > 0) are not supported. |

## Baseline models

`R/baseline.R` provides the two simplest forecasts, which every fancier
model must beat to earn its place:

- `naive_forecast(x, h)` — repeats the last observed price `h` steps.
- `mean_forecast(x, h)` — repeats the mean of the observed prices.

Both take a numeric vector of prices and return a numeric vector of
length `h`.

## License

MIT — see [LICENSE](LICENSE).
