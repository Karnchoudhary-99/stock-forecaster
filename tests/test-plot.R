# Tests for R/plot.R. Run from the repo root: Rscript tests/run_all.R
source("R/data.R")
source("R/plot.R")

expect_error <- function(expr) {
  err <- tryCatch({ force(expr); NULL }, error = function(cond) cond)
  stopifnot(!is.null(err))
}

near <- function(a, b, tol = 1e-9) all(abs(a - b) < tol)

# Scaling: higher prices map to smaller SVG y (axis is inverted),
# and the first/last x land on the left/right margins.
pts <- scale_to_svg(c(1, 2, 3), c(100, 110, 105))
stopifnot(near(pts$x, c(60, 420, 780)))
stopifnot(pts$y[2] < pts$y[1], pts$y[2] < pts$y[3])
# A flat series still scales (no division by zero) and centres vertically.
flat <- scale_to_svg(1:3, c(50, 50, 50))
stopifnot(all(is.finite(flat$x)), all(is.finite(flat$y)))
stopifnot(near(flat$y, rep(flat$y[1], 3)))

# Escaping keeps markup out of titles and legend labels.
stopifnot(svg_escape('a<b & "c"') == 'a&lt;b &amp; &quot;c&quot;')

# Polyline serialisation: dashed flag only when requested.
solid <- polyline_svg(data.frame(x = c(0, 10), y = c(0, 10)), "#222222")
stopifnot(grepl('points="0.0,0.0 10.0,10.0"', solid, fixed = TRUE))
stopifnot(!grepl("dasharray", solid, fixed = TRUE))
dashed <- polyline_svg(data.frame(x = c(0, 10), y = c(0, 10)), "#ff0000",
                       dashed = TRUE)
stopifnot(grepl("dasharray", dashed, fixed = TRUE))

# A full chart contains history + each forecast + a legend entry,
# and the forecast origin divider.
svg <- forecast_plot_svg(c(100, 102, 101, 103),
                         list(naive = c(103, 103), holt = c(104, 105)),
                         title = "Test <plot>")
stopifnot(grepl("<svg", svg, fixed = TRUE), grepl("</svg>", svg, fixed = TRUE))
stopifnot(grepl("history", svg, fixed = TRUE), grepl("naive", svg, fixed = TRUE),
          grepl("holt", svg, fixed = TRUE), grepl("forecast", svg, fixed = TRUE))
stopifnot(grepl("Test &lt;plot&gt;", svg, fixed = TRUE))
# History is one solid polyline; each forecast is a dashed polyline
# starting at the last history point (3 points for h = 2).
polylines <- regmatches(svg, gregexpr("<polyline[^>]+>", svg))[[1]]
stopifnot(length(polylines) == 3)
stopifnot(sum(grepl("dasharray", polylines)) == 2)

cat("test-plot ok\n")

# Validation + file writer (appended cases, same suite file).
expect_error(scale_to_svg(1:2, c(100)))
expect_error(scale_to_svg(1:2, c(100, NA)))
expect_error(forecast_plot_svg(c(100, 101), list(c(102, 103))))  # unnamed
expect_error(forecast_plot_svg(c(100, 101),
                               list(a = c(102), b = c(102, 103))))  # lengths differ
expect_error(forecast_plot_svg(numeric(0), list()))
expect_error(y_ticks(c(100, 100)))
expect_error(polyline_svg(data.frame(x = numeric(0), y = numeric(0)), "#000"))

# write_forecast_svg creates parent dirs and writes a readable SVG.
tmp <- file.path(tempdir(), "sf-plot", "chart.svg")
write_forecast_svg(tmp, c(100, 102), list(naive = c(102, 102)))
stopifnot(file.exists(tmp))
back <- paste(readLines(tmp), collapse = "\n")
stopifnot(grepl("<svg", back, fixed = TRUE), grepl("naive", back, fixed = TRUE))

# No-forecast chart: history only, no origin divider.
svg0 <- forecast_plot_svg(c(100, 101, 102))
stopifnot(!grepl('>forecast<', svg0, fixed = TRUE))
stopifnot(length(regmatches(svg0, gregexpr("<polyline[^>]+>", svg0))[[1]]) == 1)

cat("test-plot validation ok\n")
