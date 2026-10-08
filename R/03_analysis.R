# Descriptive table, univariable and multivariable logistic regression, forest plot
d <- readRDS("data/clean.rds")
vars <- c("age_group", "sex", "hiv", "prev_tx", "contact", "smoking", "alcohol")
labels <- c(age_group = "Age group", sex = "Sex", hiv = "HIV status", prev_tx = "Previous TB treatment",
            contact = "Contact with DR-TB case", smoking = "Smoking", alcohol = "Alcohol use")

# ---- Table 1: characteristics by resistance status ---------------------------------
tab1 <- do.call(rbind, lapply(vars, function(v) {
  t <- table(d[[v]], d$resistant)
  p <- suppressWarnings(chisq.test(t)$p.value)
  data.frame(variable = labels[[v]], level = rownames(t),
             susceptible = sprintf("%d (%.1f%%)", t[, "0"], 100 * prop.table(t, 2)[, "0"]),
             resistant   = sprintf("%d (%.1f%%)", t[, "1"], 100 * prop.table(t, 2)[, "1"]),
             p_value = c(sprintf("%.3f", p), rep("", nrow(t) - 1)), row.names = NULL)
}))
write.csv(tab1, "outputs/table1_characteristics.csv", row.names = FALSE)

# ---- Logistic regression -----------------------------------------------------------
or_table <- function(fit) {
  est <- coef(summary(fit))[-1, , drop = FALSE]
  ci  <- suppressMessages(confint.default(fit))[-1, , drop = FALSE]
  data.frame(term = rownames(est), OR = exp(est[, 1]), lower = exp(ci[, 1]), upper = exp(ci[, 2]),
             p = est[, 4], row.names = NULL)
}
cc <- d[complete.cases(d[, c(vars, "resistant")]), ]
uni <- do.call(rbind, lapply(vars, function(v) or_table(glm(reformulate(v, "resistant"), binomial, cc))))
multi_fit <- glm(reformulate(vars, "resistant"), binomial, cc)
multi <- or_table(multi_fit)

res <- merge(setNames(uni, c("term", "cOR", "cOR_lower", "cOR_upper", "cOR_p")),
             setNames(multi, c("term", "aOR", "aOR_lower", "aOR_upper", "aOR_p")), by = "term", sort = FALSE)
num <- sapply(res, is.numeric); res[num] <- lapply(res[num], round, 3)
write.csv(res, "outputs/odds_ratios.csv", row.names = FALSE)

cat(sprintf("Complete cases: %d of %d | resistant: %d (%.1f%%)\n", nrow(cc), nrow(d),
            sum(cc$resistant), 100 * mean(cc$resistant)))
cat(sprintf("Multivariable model AIC: %.1f\n\n", AIC(multi_fit)))
print(res[, c("term", "aOR", "aOR_lower", "aOR_upper", "aOR_p")], row.names = FALSE)

# ---- Forest plot of adjusted odds ratios -------------------------------------------
png("outputs/forest_plot_aOR.png", width = 1600, height = 1000, res = 200)
par(mar = c(4, 13, 3, 2))
k <- nrow(multi); y <- rev(seq_len(k))
plot(multi$OR, y, log = "x", xlim = range(c(multi$lower, multi$upper)), pch = 19, col = "#0f766e",
     yaxt = "n", ylab = "", xlab = "Adjusted odds ratio (95% CI, log scale)",
     main = "Factors associated with drug resistance (simulated data)")
segments(multi$lower, y, multi$upper, y, col = "#0f766e", lwd = 2)
abline(v = 1, lty = 2, col = "grey40")
axis(2, at = y, labels = multi$term, las = 1, cex.axis = .8)
invisible(dev.off())
