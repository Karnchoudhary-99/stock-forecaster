# Stock Price Forecaster

A stock price forecasting toolkit in R: time-series models, honest
backtesting, and forecast evaluation — built to be read, run, and
compared, not just fitted.

## Roadmap

- [x] Project scaffold (README roadmap, baseline models, smoke test, CI)
- [ ] Data loading: CSV price series + validation
- [ ] Models: naive, moving average, ETS, ARIMA
- [ ] Backtesting: rolling-origin evaluation
- [ ] Metrics: MAE, RMSE, MAPE, directional accuracy
- [ ] Forecast plots + report, then self-review checklist, then public

## Quick start

```sh
Rscript tests/smoke.R   # baseline forecasts + assertions
```

## Baseline models

`R/baseline.R` provides the two simplest forecasts, which every fancier
model must beat to earn its place:

- `naive_forecast(x, h)` — repeats the last observed price `h` steps.
- `mean_forecast(x, h)` — repeats the mean of the observed prices.

Both take a numeric vector of prices and return a numeric vector of
length `h`.

## License

MIT — see [LICENSE](LICENSE).
