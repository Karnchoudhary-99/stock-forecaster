# Tests for R/data.R. Run from the repo root: Rscript tests/run_all.R
source("R/data.R")

expect_error <- function(expr) {
  err <- tryCatch({ force(expr); NULL }, error = function(cond) cond)
  stopifnot(!is.null(err))
}

# Valid file, unsorted rows come back sorted with prices aligned.
tmp <- tempfile(fileext = ".csv")
writeLines(c("date,close",
             "2025-01-03,103",
             "2025-01-02,100",
             "2025-01-06,105"), tmp)
df <- load_prices(tmp)
stopifnot(all(df$date == as.Date(c("2025-01-02", "2025-01-03", "2025-01-06"))))
stopifnot(all(df$close == c(100, 103, 105)))

# Case-insensitive headers and extra columns are tolerated.
tmp2 <- tempfile(fileext = ".csv")
writeLines(c("Date,Close,Volume",
             "2025-01-02,100,500",
             "2025-01-03,101,600"), tmp2)
df2 <- load_prices(tmp2)
stopifnot(nrow(df2) == 2, all(df2$close == c(100, 101)))

# Missing file, missing column, NA close, non-numeric close, duplicate date.
expect_error(load_prices("/nonexistent/missing.csv"))
tmp3 <- tempfile(fileext = ".csv")
writeLines(c("date,open", "2025-01-02,100"), tmp3)
expect_error(load_prices(tmp3))
tmp4 <- tempfile(fileext = ".csv")
writeLines(c("date,close", "2025-01-02,100", "2025-01-03,"), tmp4)
expect_error(load_prices(tmp4))
tmp5 <- tempfile(fileext = ".csv")
writeLines(c("date,close", "2025-01-02,abc"), tmp5)
expect_error(load_prices(tmp5))
tmp6 <- tempfile(fileext = ".csv")
writeLines(c("date,close", "2025-01-02,100", "2025-01-02,101"), tmp6)
expect_error(load_prices(tmp6))

# validate_series rejects bad input.
expect_error(validate_series(numeric(0)))
expect_error(validate_series(c(100, NA)))
expect_error(validate_series(c(100, Inf)))
expect_error(validate_series(c("100", "101")))

cat("test-data ok\n")
