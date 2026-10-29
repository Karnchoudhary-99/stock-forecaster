#' Forecast plots as standalone SVG (base R only, no packages).
#'
#' The toolkit renders plots as SVG text rather than opening a graphics
#' device, so a plot can be produced in CI, embedded in a Markdown
#' report, and unit-tested character by character. Coordinates are
#' computed in plain R and serialised as `<polyline>` elements.

#' Escape text for inclusion in SVG/XML attribute or element content.
svg_escape <- function(text) {
  text <- as.character(text)
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  text <- gsub('"', "&quot;", text, fixed = TRUE)
  text
}

#' Map data coordinates onto SVG pixel coordinates.
#'
#' @param x Numeric x positions (e.g. time indices, oldest first).
#' @param y Numeric y values (prices).
#' @param width,height SVG canvas size in pixels.
#' @param margin Named list with `left`, `right`, `top`, `bottom` insets.
#' @return A data.frame with `x` and `y` pixel coordinates, plus the
#'   `y_range` used (padded by 5% at each end so points never sit on
#'   the frame) as attributes.
scale_to_svg <- function(x, y, width = 800, height = 400,
                         margin = list(left = 60, right = 20,
                                       top = 30, bottom = 40)) {
  if (!is.numeric(x) || !is.numeric(y) || length(x) != length(y) ||
      length(x) < 1 || !all(is.finite(x)) || !all(is.finite(y))) {
    stop("x and y must be non-empty finite numeric vectors of equal length")
  }
  plot_w <- width - margin$left - margin$right
  plot_h <- height - margin$top - margin$bottom
  if (plot_w <= 0 || plot_h <= 0) {
    stop("canvas too small for the requested margins")
  }
  x_range <- range(x)
  y_range <- range(y)
  y_pad <- if (diff(y_range) == 0) abs(y_range[1]) * 0.05 + 1 else diff(y_range) * 0.05
  y_range <- y_range + c(-y_pad, y_pad)
  x_px <- if (diff(x_range) == 0) {
    rep(margin$left + plot_w / 2, length(x))
  } else {
    margin$left + (x - x_range[1]) / diff(x_range) * plot_w
  }
  # SVG y grows downwards, so invert the value axis.
  y_px <- margin$top + (1 - (y - y_range[1]) / diff(y_range)) * plot_h
  out <- data.frame(x = x_px, y = y_px)
  attr(out, "y_range") <- y_range
  attr(out, "x_range") <- x_range
  out
}

#' Y-axis tick values for a value range (base R `pretty()` breaks).
y_ticks <- function(y_range, n = 5) {
  if (length(y_range) != 2 || !is.numeric(y_range) ||
      !all(is.finite(y_range)) || y_range[1] >= y_range[2]) {
    stop("y_range must be two finite numbers, low then high")
  }
  pretty(y_range, n = n)
}
