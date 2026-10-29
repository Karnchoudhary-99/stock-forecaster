# Smoke test for the baseline forecasts (base R only, no testthat).
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("--file=", "", file_arg[1]) else "tests/smoke.R"
source(file.path(dirname(script_path), "..", "R", "baseline.R"))

prices <- c(100, 102, 101, 105, 103)

naive <- naive_forecast(prices, 3)
stopifnot(length(naive) == 3, all(naive == 103))

mean_f <- mean_forecast(prices, 2)
stopifnot(length(mean_f) == 2, all(mean_f == mean(prices)))

cat("smoke ok: naive =", naive[1], ", mean =", mean_f[1], "\n")
