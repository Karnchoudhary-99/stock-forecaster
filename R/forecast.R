#' One entry point for every model in the toolkit.
#'
#' @param x Numeric vector of observed prices (oldest first).
#' @param h Number of steps to forecast (positive integer).
#' @param method One of `"naive"`, `"mean"`, `"ma"`, `"ses"`, `"holt"`,
#'   `"ar"`, `"arima"`.
#' @param ... Model parameters: `window` for `"ma"`, `alpha` for `"ses"`,
#'   `alpha`/`beta` for `"holt"`, `p`/`d`/`order` for `"ar"`/`"arima"`.

forecast_price <- function(x, h, method = c("naive", "mean", "ma", "ses",
                                            "holt", "ar", "arima"), ...) {
  x <- validate_series(x)
  h <- check_h(h)
  method <- match.arg(method)
  args <- list(...)
  switch(method,
    naive = naive_forecast(x, h),
    mean = mean_forecast(x, h),
    ma = ma_forecast(x, h,
                     window = if (is.null(args$window)) 5 else args$window),
    ses = ses_forecast(x, h,
                       alpha = if (is.null(args$alpha)) NULL else args$alpha),
    holt = holt_forecast(x, h,
                         alpha = if (is.null(args$alpha)) NULL else args$alpha,
                         beta = if (is.null(args$beta)) NULL else args$beta),
    ar = ar_forecast(x, h,
                     p = if (is.null(args$p)) 1 else args$p,
                     d = if (is.null(args$d)) 0 else args$d),
    arima = arima_forecast(x, h,
                           order = if (is.null(args$order)) c(1, 0, 0) else args$order)
  )
}
