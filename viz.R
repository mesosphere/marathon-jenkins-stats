## Note - in order for this script to work, you must install the following packages:
## install.packages("ggplot2")
## install.packages("reshape2")
## install.packages("plyr")
## install.packages("devtools")
## library("devtools")
## install_github("wilkox/ggfittext")
## install_github("wilkox/treemapify")

require("ggplot2")
library("treemapify")
## library("data.table")
source("lib/common.R")

job_name <- Sys.getenv("JOB", unset = "marathon-unstable-loop")
job_name

job_file <- function(filename) {
    return(paste(job_name, "/", filename, sep = ""))
}

calc_jitter_factor <- function(nrows, failure_class_name_count) {
    if (nrows == 0) {
        return (as.numeric(NULL))
    } else if (failure_class_name_count < 3) {
        return ((c(1:nrows)) %% (failure_class_name_count) + 1)
    } else {
        return ((c(1:nrows) * 2) %% (failure_class_name_count) + 1)
    }
}

df <- read_suite(job_file("flattened-suite.tsv"))
job_ids <- sort(unique(df$job_id))
job_idxs <- data.frame(job_id = job_ids, job_idx = c(1:length(job_ids)))
df <- merge(df, job_idxs)

## suite_summary <- df[, .(total_run_count = .N, total_passes = sum(passed), total_fail_rate = (.N - sum(passed)) / .N), by = .(class_name, package)]
fails <- df[! df$passed, ]
fails$class_name <- factor(fails$class_name)
fails$package <- factor(fails$package)
## fails <- merge(fails, suite_summary)

job_details <- read_job_details(job_file("job-details.tsv"))
job_details <- job_details[!is.na(job_details$rev) & !(job_details$rev == ""),]
job_details$rev <- factor(job_details$rev)
levels(job_details$rev) <- mapply(function(s) substring(s, 1,7), levels(job_details$rev))

job_details <- job_details[!is.na(match(job_details$job_id, job_ids)), ]
job_details$prior_rev <- shift(job_details$rev)

job_details <- merge(job_details, job_idxs, sort = FALSE)

failure_class_name_count <- length(unique(fails$class_name))
changes <- job_details[job_details$rev != job_details$prior_rev, ]
changes$idx <- if (nrow(changes) >= 1) c(1:nrow(changes)) else as.numeric(NULL)
changes$offset <- calc_jitter_factor(nrow(changes), failure_class_name_count)

deadzone <- data.frame(
    job_id = c(2900), job_id_end = c(2950), y_min = c(0), y_max = c(failure_class_name_count + 1))

jobs <- read_jobs(job_file("flattened-job.tsv"))
jobs <- merge(jobs, job_idxs, all.x = TRUE)
jobs$prior_non_empty <- shift(jobs$non_empty)
deadzone_boundaries <- jobs[jobs$prior_non_empty != jobs$non_empty, ]
deadzone_boundaries$next_job_id <- unshift(deadzone_boundaries$job_id)
deadzone_boundaries <- deadzone_boundaries[!deadzone_boundaries$non_empty, ]
deadzone <- data.frame(
    job_id = deadzone_boundaries$job_id,
    job_id_end = deadzone_boundaries$next_job_id,
    ymin = rep(0, nrow(deadzone_boundaries)),
    ymax = rep(failure_class_name_count + 1, nrow(deadzone_boundaries)))

for (plot_index in c(TRUE, FALSE)) {
    if (plot_index) {
        job_column <- quote(job_idx)
        job_column_name <- "Job Index"
        plot_name <- "failures-idx"
    } else {
        job_column <- quote(job_id)
        job_column_name <- "Job Id"
        plot_name <- "failures"
    }

    render.twice(function() {
        return
        (
            ggplot(fails) +
            geom_point(size = 3, aes_(colour = quote(class_name), x = job_column, y = quote(class_name))) +
            labs(y = "", x = job_column_name, title = paste("Failed suites for", job_name, "by Job (circle indicates failure)")) +
            guides(colour = FALSE) +
            scale_x_continuous(expand = c(0,2)) +
            geom_vline(data = changes, aes_(xintercept = job_column), linetype = 3, size=0.5, alpha = 0.1) +
            geom_text(data = changes, angle = 90, size = 2, alpha = 0.9, aes_(label = quote(rev), x = job_column, y = quote(offset))) +
            if(plot_index)
                NULL
            else
                geom_rect(data = deadzone, aes(xmin = job_id, xmax = job_id_end, ymin = ymin, ymax = ymax), fill = "red", alpha = 0.2)
        )

    }, job_file(plot_name), width=12, height = (length(unique(fails$class_name)) / 4) + 1)
}




job_id <- as.numeric(Sys.getenv("VIZ_JOB_ID", unset = max(job_ids)))
# change this job_id to visualize a different job!
job <- df[df$job_id == job_id, ]
## job <- job[order(job$timestamp), ]
job$suite <- factor(paste(job$package, job$class_name, sep = "."))
job$idx <- seq.int(nrow(job))
job$integration <- grepl("integration", job$package)

job$suite_with_duration <- paste(job$class_name, "\n", "(", round(job$duration, digits=1), "s", ")", sep = "")

## render.twice(function() {
##     (
##         ggplot(job, aes(xmin = timestamp, xmax = timestamp + duration, ymin = idx - 0.20, ymax = idx + 0.20)) +
##         geom_rect(aes(fill = integration)) +
##         ## guides(fill = FALSE) +
##         scale_y_reverse() +
##         geom_text(aes(x = timestamp, y = idx - 0.5, label = suite), size=0.5, hjust="left", color = "grey") +
##         labs(y = "suite", title = paste("Timeline - Job #", job_id, " for ", job_name, sep = ""))
##     )
## }, job_file("timeline"), width=12, height=10)

render.twice(function() {
    (
        ggplot(job, aes(area = duration, label = suite_with_duration, fill = tests_total)) +
        scale_fill_gradient(name = "tests_total", trans = "log") +
        labs(title = paste("Suite Durations - Job #", job_id, " for ", job_name, sep = "")) +
        geom_treemap(color = "black", size = 3) +
        geom_treemap_text(
            fontface = "italic",
            colour = "white",
            place = "centre",
            grow = TRUE
        )
    )
}, job_file("durations"), width=8, height=8)
