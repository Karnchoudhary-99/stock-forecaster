# Run the whole suite from the repo root: Rscript tests/run_all.R
test_files <- sort(list.files("tests", pattern = "^test-.*\\.R$",
                              full.names = TRUE))
for (f in test_files) {
  cat("running", f, "\n")
  source(f)
}
source("tests/smoke.R")
cat("all tests ok\n")
