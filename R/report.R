#' Forecast reports as Markdown (base R only, no packages).
#'
#' A report is a plain string so it can be written to a file, embedded
#' in a README, or inspected in tests without touching the filesystem.
#' Numbers are formatted to a fixed precision so reports are stable
#' across runs on the same data.

#' Format a number to two decimals, or "NA" for a missing value.
fmt_num <- function(x, digits = 2) {
  if (is.na(x)) "NA" else sprintf(paste0("%.", digits, "f"), x)
}

#' Render a data.frame as a Markdown table.
#'
#' Numeric columns are formatted with `fmt_num()`; character columns
#' are passed through. The header separator uses dashes, so the output
#' renders in any Markdown viewer.
md_table <- function(df) {
  if (!is.data.frame(df) || nrow(df) < 1 || ncol(df) < 1) {
    stop("md_table needs a non-empty data.frame")
  }
  cells <- lapply(names(df), function(col) {
    vals <- df[[col]]
    if (is.numeric(vals)) {
      # Per-cell: whole numbers (counts, horizons) read better as
      # integers, even in a column that also holds decimals.
      vapply(vals, function(v) {
        if (is.na(v)) "NA" else if (v == round(v)) sprintf("%d", as.integer(v)) else fmt_num(v)
      }, character(1))
    } else {
      as.character(vals)
    }
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  separator <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- vapply(seq_len(nrow(df)), function(i) {
    paste0("| ", paste(vapply(cells, function(col) col[i], character(1)),
                        collapse = " | "), " |")
  }, character(1))
  paste(c(header, separator, rows), collapse = "\n")
}

#' Summarise a price series: count, range, mean, spread, last value.
series_summary <- function(x) {
  x <- validate_series(x)
  data.frame(
    metric = c("observations", "minimum", "maximum", "mean",
               "std_dev", "last"),
    value = c(length(x), min(x), max(x), mean(x), stats::sd(x),
              x[length(x)]),
    stringsAsFactors = FALSE
  )
}

#' Validate a named list of forecasts: same length, finite, named.
check_forecasts <- function(forecasts) {
  if (!is.list(forecasts) || length(forecasts) < 1) {
    stop("forecasts must be a non-empty named list of numeric vectors")
  }
  if (is.null(names(forecasts)) || any(names(forecasts) == "")) {
    stop("forecasts must be a named list")
  }
  for (name in names(forecasts)) {
    forecasts[[name]] <- validate_series(forecasts[[name]])
  }
  h_lengths <- unique(vapply(forecasts, length, integer(1)))
  if (length(h_lengths) != 1) {
    stop("all forecasts must have the same length")
  }
  forecasts
}

#' Forecast table: one row per method, one column per horizon step.
forecast_table <- function(forecasts) {
  forecasts <- check_forecasts(forecasts)
  h <- length(forecasts[[1]])
  df <- data.frame(method = names(forecasts), stringsAsFactors = FALSE)
  for (step in seq_len(h)) {
    df[[paste0("step_", step)]] <- vapply(forecasts,
                                         function(fc) fc[step], numeric(1))
  }
  df
}

#' Build the full Markdown forecast report.
#'
#' @param history Numeric price vector, oldest first.
#' @param forecasts Named list of forecast vectors (see `forecast_table()`).
#' @param backtest Optional data.frame with `method`, `rmse`, `mae`,
#'   `mape` and `directional_accuracy` columns (as produced by the
#'   backtest example); when supplied it is ranked by RMSE and the
#'   best method is named in the notes.
#' @param title Report title.
#' @return A single Markdown string.
build_forecast_report <- function(history, forecasts,
                                  backtest = NULL,
                                  title = "Forecast report") {
  history <- validate_series(history)
  forecasts <- check_forecasts(forecasts)
  h <- length(forecasts[[1]])
  sections <- c(
    paste0("# ", title, "\n"),
    "## Series summary\n",
    md_table(series_summary(history)),
    "",
    sprintf("## Forecasts (%d steps ahead)\n", h),
    md_table(forecast_table(forecasts))
  )
  if (!is.null(backtest)) {
    required <- c("method", "rmse", "mae", "mape", "directional_accuracy")
    if (!is.data.frame(backtest) || !all(required %in% names(backtest))) {
      stop("backtest must be a data.frame with columns: ",
           paste(required, collapse = ", "))
    }
    ranked <- backtest[order(backtest$rmse), ]
    sections <- c(sections, "",
                  "## Backtest ranking (by RMSE)\n",
                  md_table(ranked[, required, drop = FALSE]),
                  "",
                  sprintf("Best by RMSE: %s (RMSE %s). A low RMSE with low directional accuracy means the model gets magnitudes right without predicting direction — report both, never one alone.",
                          ranked$method[1], fmt_num(ranked$rmse[1])))
  }
  sections <- c(sections, "",
                sprintf("Last observed price: %s; forecasts continue from there.",
                        fmt_num(history[length(history)])))
  paste(sections, collapse = "\n")
}

#' Write a forecast report to a file (creating parent dirs as needed).
write_forecast_report <- function(path, history, forecasts,
                                  backtest = NULL,
                                  title = "Forecast report") {
  report <- build_forecast_report(history, forecasts, backtest, title)
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  writeLines(report, path)
  invisible(path)
}
