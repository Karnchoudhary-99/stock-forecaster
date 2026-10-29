# Forecast report: sample series

## Series summary

| metric | value |
| --- | --- |
| observations | 120 |
| minimum | 96.91 |
| maximum | 122.95 |
| mean | 109.16 |
| std_dev | 6.51 |
| last | 122.18 |

## Forecasts (10 steps ahead)

| method | step_1 | step_2 | step_3 | step_4 | step_5 | step_6 | step_7 | step_8 | step_9 | step_10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| naive | 122.18 | 122.18 | 122.18 | 122.18 | 122.18 | 122.18 | 122.18 | 122.18 | 122.18 | 122.18 |
| mean | 109.16 | 109.16 | 109.16 | 109.16 | 109.16 | 109.16 | 109.16 | 109.16 | 109.16 | 109.16 |
| ma | 120.59 | 120.59 | 120.59 | 120.59 | 120.59 | 120.59 | 120.59 | 120.59 | 120.59 | 120.59 |
| ses | 121.98 | 121.98 | 121.98 | 121.98 | 121.98 | 121.98 | 121.98 | 121.98 | 121.98 | 121.98 |
| holt | 123.83 | 124.76 | 125.70 | 126.63 | 127.57 | 128.51 | 129.44 | 130.38 | 131.31 | 132.25 |
| ar | 121.83 | 121.88 | 121.82 | 121.79 | 121.75 | 121.71 | 121.67 | 121.64 | 121.60 | 121.57 |
| arima | 122.11 | 122.37 | 122.53 | 122.72 | 122.90 | 123.08 | 123.26 | 123.44 | 123.62 | 123.80 |

## Backtest ranking (by RMSE)

| method | rmse | mae | mape | directional_accuracy |
| --- | --- | --- | --- | --- |
| naive | 4.27 | 3.24 | 0.03 | 0 |
| holt | 4.27 | 3.30 | 0.03 | 0.60 |
| arima | 4.33 | 3.37 | 0.03 | 0.52 |
| ar | 4.51 | 3.43 | 0.03 | 0.50 |
| ses | 4.58 | 3.47 | 0.03 | 0.06 |
| ma | 5.08 | 4.00 | 0.03 | 0.04 |
| mean | 5.73 | 4.06 | 0.04 | 0.04 |

Best by RMSE: naive (RMSE 4.27). A low RMSE with low directional accuracy means the model gets magnitudes right without predicting direction — report both, never one alone.

Last observed price: 122.18; forecasts continue from there.
