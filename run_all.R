# Run the full pipeline from the repository root: Rscript run_all.R
for (f in c("R/01_simulate_data.R", "R/02_clean.R", "R/03_analysis.R")) {
  cat("\n==>", f, "\n"); source(f, echo = FALSE)
}
