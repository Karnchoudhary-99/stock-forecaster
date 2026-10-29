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

#' Serialise scaled points as one SVG `<polyline>` element.
polyline_svg <- function(points, stroke, stroke_width = 2,
                         dashed = FALSE) {
  if (nrow(points) < 1) {
    stop("polyline needs at least one point")
  }
  coords <- paste(sprintf("%.1f,%.1f", points$x, points$y),
                  collapse = " ")
  dash <- if (dashed) ' stroke-dasharray="6,4"' else ""
  sprintf('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s"%s />',
          coords, svg_escape(stroke), stroke_width, dash)
}

#' Colour palette for forecast methods (colour-blind-friendly order).
#' Unknown methods cycle through the palette by position.
plot_palette <- c("#1f77b4", "#d62728", "#2ca02c", "#9467bd",
                  "#ff7f0e", "#17becf", "#8c564b")

method_color <- function(method, index) {
  known <- c(naive = "#1f77b4", mean = "#7f7f7f", ma = "#2ca02c",
             ses = "#ff7f0e", holt = "#d62728", ar = "#9467bd",
             arima = "#17becf")
  if (method %in% names(known)) {
    return(unname(known[[method]]))
  }
  plot_palette[((index - 1) %% length(plot_palette)) + 1]
}

#' Build a complete SVG chart: history (solid) plus forecasts (dashed).
#'
#' @param history Numeric price vector, oldest first.
#' @param forecasts Named list of numeric forecast vectors, each the
#'   same length; every forecast continues from the last history point.
#' @param title Chart title (escaped before embedding).
#' @param width,height Canvas size in pixels.
#' @return A single SVG document string.
forecast_plot_svg <- function(history, forecasts = list(),
                              title = "Price forecast",
                              width = 800, height = 400) {
  history <- validate_series(history)
  if (!is.list(forecasts)) {
    stop("forecasts must be a named list of numeric vectors")
  }
  if (length(forecasts) > 0) {
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
  }
  n <- length(history)
  h <- if (length(forecasts) == 0) 0 else length(forecasts[[1]])
  total <- n + h
  all_y <- c(history, unlist(forecasts, use.names = FALSE))
  margin <- list(left = 60, right = 20, top = 30, bottom = 40)
  # One shared y range so history and forecasts are directly comparable.
  y_range <- range(all_y)
  y_pad <- if (diff(y_range) == 0) abs(y_range[1]) * 0.05 + 1 else diff(y_range) * 0.05
  y_range <- y_range + c(-y_pad, y_pad)
  to_px <- function(xs, ys) {
    plot_w <- width - margin$left - margin$right
    plot_h <- height - margin$top - margin$bottom
    x_px <- if (total == 1) rep(margin$left + plot_w / 2, length(xs)) else {
      margin$left + (xs - 1) / (total - 1) * plot_w
    }
    y_px <- margin$top + (1 - (ys - y_range[1]) / diff(y_range)) * plot_h
    data.frame(x = x_px, y = y_px)
  }
  parts <- c(
    sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">',
            width, height, width, height),
    sprintf('<text x="%s" y="18" font-family="sans-serif" font-size="15" font-weight="bold">%s</text>',
            margin$left, svg_escape(title))
  )
  # Y gridlines + labels.
  for (tick in y_ticks(y_range)) {
    y_px <- to_px(1, tick)$y
    parts <- c(parts,
      sprintf('<line x1="%s" y1="%.1f" x2="%s" y2="%.1f" stroke="#e0e0e0" />',
              margin$left, y_px, width - margin$right, y_px),
      sprintf('<text x="%s" y="%.1f" font-family="sans-serif" font-size="11" text-anchor="end">%.2f</text>',
              margin$left - 6, y_px + 4, tick))
  }
  # Forecast-origin divider.
  if (h > 0) {
    origin_x <- to_px(n, history[n])$x
    parts <- c(parts,
      sprintf('<line x1="%.1f" y1="%s" x2="%.1f" y2="%s" stroke="#999999" stroke-dasharray="4,4" />',
              origin_x, margin$top, origin_x, height - margin$bottom),
      sprintf('<text x="%.1f" y="%s" font-family="sans-serif" font-size="11" fill="#666666">forecast</text>',
              origin_x + 4, margin$top + 12))
  }
  parts <- c(parts, polyline_svg(to_px(seq_len(n), history), "#222222", 2))
  legend_y <- height - 12
  legend_x <- margin$left
  parts <- c(parts,
    sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#222222" stroke-width="2" />',
            legend_x, legend_y, legend_x + 24, legend_y),
    sprintf('<text x="%s" y="%s" font-family="sans-serif" font-size="12">history</text>',
            legend_x + 28, legend_y + 4))
  legend_x <- legend_x + 28 + 52
  for (i in seq_along(forecasts)) {
    name <- names(forecasts)[i]
    color <- method_color(name, i)
    fc <- forecasts[[i]]
    pts <- to_px(c(n, (n + 1):(n + h)), c(history[n], fc))
    parts <- c(parts, polyline_svg(pts, color, 2, dashed = TRUE))
    parts <- c(parts,
      sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2" stroke-dasharray="6,4" />',
              legend_x, legend_y, legend_x + 24, legend_y, color),
      sprintf('<text x="%s" y="%s" font-family="sans-serif" font-size="12">%s</text>',
              legend_x + 28, legend_y + 4, svg_escape(name)))
    legend_x <- legend_x + 28 + 52 + nchar(name) * 7
  }
  parts <- c(parts, "</svg>")
  paste(parts, collapse = "\n")
}

#' Write a forecast plot SVG to a file (creating parent dirs as needed).
write_forecast_svg <- function(path, history, forecasts = list(),
                               title = "Price forecast",
                               width = 800, height = 400) {
  svg <- forecast_plot_svg(history, forecasts, title, width, height)
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  writeLines(svg, path)
  invisible(path)
}
