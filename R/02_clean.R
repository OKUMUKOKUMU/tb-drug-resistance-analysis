# Data cleaning with a logged audit trail of every change
raw <- read.csv("data/presumptive_mdrtb_simulated.csv", stringsAsFactors = FALSE)
log <- character()
note <- function(...) log <<- c(log, paste0(...))

d <- raw
dups <- duplicated(d$patient_id)
note("Removed ", sum(dups), " duplicate patient records")
d <- d[!dups, ]

bad_age <- !is.na(d$age) & (d$age < 15 | d$age > 100)
note("Set ", sum(bad_age), " implausible ages to missing")
d$age[bad_age] <- NA
note("Missing age after cleaning: ", sum(is.na(d$age)))

sex_map <- c(Male = "Male", male = "Male", M = "Male", Female = "Female", F = "Female")
recoded <- sum(!d$sex %in% c("Male", "Female"))
d$sex <- unname(sex_map[d$sex])
note("Harmonised ", recoded, " non-standard sex codes (", sum(is.na(d$sex)), " left missing)")

d$age_group <- cut(d$age, c(14, 24, 34, 44, 54, Inf), labels = c("15-24", "25-34", "35-44", "45-54", "55+"))
for (v in c("sex", "hiv", "prev_tx", "contact", "smoking", "alcohol", "county")) d[[v]] <- factor(d[[v]])
d$sex     <- relevel(d$sex, "Female")
d$hiv     <- relevel(d$hiv, "Negative")
d$age_group <- relevel(d$age_group, "35-44")

saveRDS(d, "data/clean.rds")
dir.create("outputs", showWarnings = FALSE)
writeLines(log, "outputs/cleaning_log.txt")
cat(log, sep = "\n")
