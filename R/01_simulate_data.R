# Simulate a de-identified-style dataset of presumptive MDR-TB patients.
# The data are SIMULATED for teaching and portfolio purposes. They do not
# reproduce the published study's data or results.
set.seed(2024)
n <- 650

age        <- round(pmin(pmax(rnorm(n, 38, 13), 15), 85))
sex        <- factor(sample(c("Male", "Female"), n, TRUE, prob = c(.62, .38)), levels = c("Female", "Male"))
hiv        <- factor(sample(c("Negative", "Positive", "Unknown"), n, TRUE, prob = c(.58, .34, .08)),
                     levels = c("Negative", "Positive", "Unknown"))
prev_tx    <- factor(sample(c("No", "Yes"), n, TRUE, prob = c(.45, .55)), levels = c("No", "Yes"))
contact    <- factor(sample(c("No", "Yes"), n, TRUE, prob = c(.85, .15)), levels = c("No", "Yes"))
smoking    <- factor(sample(c("No", "Yes"), n, TRUE, prob = c(.72, .28)), levels = c("No", "Yes"))
alcohol    <- factor(sample(c("No", "Yes"), n, TRUE, prob = c(.65, .35)), levels = c("No", "Yes"))
county     <- factor(sample(c("Kisumu", "Siaya", "Homa Bay", "Migori", "Kakamega"), n, TRUE))

# Data-generating model with assumed (illustrative) effects
lp <- -2.6 + 0.012 * (age - 38) + 0.20 * (sex == "Male") + 0.35 * (hiv == "Positive") +
      1.10 * (prev_tx == "Yes") + 0.90 * (contact == "Yes") + 0.30 * (smoking == "Yes") +
      0.10 * (alcohol == "Yes")
resistant <- rbinom(n, 1, plogis(lp))

tb <- data.frame(patient_id = sprintf("P%04d", seq_len(n)), age, sex, hiv, prev_tx, contact,
                 smoking, alcohol, county, resistant)

# Introduce realistic data-quality issues for the cleaning step
tb$age[sample(n, 6)] <- NA
tb$age[sample(n, 2)] <- 999
tb$sex <- as.character(tb$sex); tb$sex[sample(n, 4)] <- c("M", "male", "F", "")
tb <- rbind(tb, tb[sample(n, 3), ])   # duplicate records

dir.create("data", showWarnings = FALSE)
write.csv(tb, "data/presumptive_mdrtb_simulated.csv", row.names = FALSE)
cat("Wrote", nrow(tb), "rows to data/presumptive_mdrtb_simulated.csv\n")
