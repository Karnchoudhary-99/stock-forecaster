#' Load and validate a price series from a CSV file.
#'
#' The CSV must have a `date` column (YYYY-MM-DD) and a `close` column.
#' Extra columns are ignored. Rows are returned sorted by date.
#'
#' @param path Path to the CSV file.
#' @return A data.frame with columns `date` (Date) and `close` (numeric),
#'   sorted ascending by date.
#' @examples
#' \dontrun{
#' prices <- load_prices("data/sample-prices.csv")
#' }

validate_series <- function(x) {
  if (!is.numeric(x) || length(x) < 1 || !all(is.finite(x))) {
    stop("series must be a non-empty numeric vector with no NA/NaN/Inf values")
  }
  x
}

load_prices <- function(path) {
  if (!file.exists(path)) {
    stop("price file not found: ", path)
  }
  df <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (nrow(df) < 1) {
    stop("price file has no data rows: ", path)
  }
  lowered <- tolower(names(df))
  date_col <- which(lowered == "date")[1]
  close_col <- which(lowered == "close")[1]
  if (is.na(date_col) || is.na(close_col)) {
    stop("price file must have 'date' and 'close' columns; found: ",
         paste(names(df), collapse = ", "))
  }
  raw_date <- df[[date_col]]
  dates <- if (inherits(raw_date, "Date")) raw_date else as.Date(raw_date)
  if (any(is.na(dates))) {
    stop("unparseable date in price file (expected YYYY-MM-DD)")
  }
  raw_close <- df[[close_col]]
  if (!is.numeric(raw_close)) {
    converted <- suppressWarnings(as.numeric(raw_close))
    if (any(is.na(converted))) {
      stop("non-numeric value in 'close' column")
    }
    raw_close <- converted
  }
  if (any(!is.finite(raw_close))) {
    stop("non-finite value in 'close' column")
  }
  if (anyDuplicated(dates)) {
    stop("duplicate dates in price file")
  }
  ord <- order(dates)
  data.frame(date = dates[ord], close = raw_close[ord], row.names = NULL)
}
