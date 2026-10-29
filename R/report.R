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
      # Whole-number columns (counts, horizons) read better as integers.
      if (all(vals == round(vals), na.rm = TRUE)) {
        vapply(vals, function(v) if (is.na(v)) "NA" else sprintf("%d", as.integer(v)),
               character(1))
      } else {
        vapply(vals, fmt_num, character(1))
      }
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
