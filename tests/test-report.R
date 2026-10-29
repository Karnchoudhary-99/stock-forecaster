# Tests for R/report.R. Run from the repo root: Rscript tests/run_all.R
source("R/data.R")
source("R/report.R")

expect_error <- function(expr) {
  err <- tryCatch({ force(expr); NULL }, error = function(cond) cond)
  stopifnot(!is.null(err))
}

# Series summary on a hand-computed series.
s <- series_summary(c(100, 102, 101))
stopifnot(s$value[s$metric == "observations"] == 3)
stopifnot(s$value[s$metric == "minimum"] == 100)
stopifnot(s$value[s$metric == "maximum"] == 102)
stopifnot(s$value[s$metric == "last"] == 101)
stopifnot(abs(s$value[s$metric == "mean"] - 101) < 1e-9)

# Markdown tables: header, separator, one row per data row.
tbl <- md_table(data.frame(method = c("naive", "holt"), rmse = c(2.5, 2.1)))
lines <- strsplit(tbl, "\n")[[1]]
stopifnot(lines[1] == "| method | rmse |", lines[2] == "| --- | --- |")
stopifnot(length(lines) == 4, grepl("naive", lines[3]), grepl("2.10", lines[4]))
# Whole-number columns render as integers, not "3.00".
tbl_int <- md_table(data.frame(n = c(10, 20), x = c(1.5, 2.5)))
stopifnot(grepl("| 10 |", tbl_int, fixed = TRUE))

# Forecast table shape: one row per method, one column per step.
ft <- forecast_table(list(naive = c(103, 103), holt = c(104, 105)))
stopifnot(nrow(ft) == 2, all(c("method", "step_1", "step_2") %in% names(ft)))
stopifnot(ft$step_2[ft$method == "holt"] == 105)

# Full report: sections, summary, forecasts, and RMSE-ranked backtest.
rep <- build_forecast_report(
  c(100, 102, 101), list(naive = c(101, 101), holt = c(102, 103)),
  backtest = data.frame(method = c("naive", "holt"), rmse = c(2.5, 2.1),
                         mae = c(2, 1.8), mape = c(0.02, 0.018),
                         directional_accuracy = c(0, 0.6)))
stopifnot(grepl("# Forecast report", rep, fixed = TRUE))
stopifnot(grepl("## Series summary", rep, fixed = TRUE))
stopifnot(grepl("## Forecasts (2 steps ahead)", rep, fixed = TRUE))
stopifnot(grepl("## Backtest ranking", rep, fixed = TRUE))
stopifnot(grepl("Best by RMSE: holt", rep, fixed = TRUE))
# Holt (lower RMSE) must rank above naive in the backtest table.
holt_pos <- regexpr("holt", rep, fixed = TRUE)[1]
naive_bt <- regexpr("naive", rep, fixed = TRUE)
# Find naive's occurrence after the backtest heading, not in forecasts.
bt_start <- regexpr("## Backtest ranking", rep, fixed = TRUE)[1]
bt_section <- substr(rep, bt_start, nchar(rep))
stopifnot(regexpr("holt", bt_section, fixed = TRUE)[1] <
          regexpr("naive", bt_section, fixed = TRUE)[1])

cat("test-report ok\n")
