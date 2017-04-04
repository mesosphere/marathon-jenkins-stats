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

plot_index <- as.logical(Sys.getenv("PLOT_IDX", "false"))
if (plot_index) {
    job_column <- quote(job_idx)
    job_column_name <- "Job Index"
} else {
    job_column <- quote(job_id)
    job_column_name <- "Job Id"
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


job_summary <- read_job_summary(job_file("job-details.tsv"))
job_summary <- job_summary[!is.na(job_summary$rev) & !(job_summary$rev == ""),]
job_summary$rev <- factor(job_summary$rev)
levels(job_summary$rev) <- mapply(function(s) substring(s, 1,7), levels(job_summary$rev))

job_summary <- job_summary[!is.na(match(job_summary$job_id, job_ids)), ]
if (nrow(job_summary) > 0) {
    job_summary$prior_rev <- unlist(list(job_summary$rev[1], job_summary$rev[-nrow(job_summary)]))
} else {
    job_summary$prior_rev <- job_summary$rev
}


job_summary <- merge(job_summary, job_idxs, sort = FALSE)

calc_jitter_factor <- function(nrows, failure_class_name_count) {
    if (nrows == 0) {
        return (as.numeric(NULL))
    } else if (failure_class_name_count < 3) {
        return ((c(1:nrows)) %% (failure_class_name_count) + 1)
    } else {
        return ((c(1:nrows) * 2) %% (failure_class_name_count) + 1)
    }
}

failure_class_name_count <- length(unique(fails$class_name))
changes <- job_summary[job_summary$rev != job_summary$prior_rev, ]
changes$idx <- if (nrow(changes) >= 1) c(1:nrow(changes)) else as.numeric(NULL)
changes$offset <- calc_jitter_factor(nrow(changes), failure_class_name_count)

render.twice <- function (fn, file.prefix, width, height) {
    pdf(paste(file.prefix, "pdf", sep="."), width=width, height=height)
    print(fn())
    dev.off()
    svg(paste(file.prefix, "svg", sep="."), width=width, height=height)
    print(fn())
    dev.off()
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
        geom_text(data = changes, angle = 90, size = 2, alpha = 0.9, aes_(label = quote(rev), x = job_column, y = quote(offset)))
    )
}, job_file("failures"), width=12, height = (length(unique(fails$class_name)) / 4) + 1)

job_id <- max(job_ids)
# change this job_id to visualize a different job!
job <- df[df$job_id == job_id, ]
job <- job[order(job$timestamp), ]
job$suite <- factor(paste(job$package, job$class_name, sep = "."))
job$idx <- seq.int(nrow(job))
job$integration <- grepl("integration", job$package)

svg(job_file("timeline.svg"), width=12, height=10)
(
    ggplot(job, aes(xmin = timestamp, xmax = timestamp + duration, ymin = idx - 0.20, ymax = idx + 0.20)) +
    geom_rect(aes(fill = integration)) +
    ## guides(fill = FALSE) +
    scale_y_reverse() +
    geom_text(aes(x = timestamp, y = idx - 0.5, label = suite), size=0.5, hjust="left", color = "grey") +
    labs(y = "suite", title = paste("Timeline - Job #", job_id, " for ", job_name, sep = ""))
)
dev.off()

svg(job_file("durations.svg"), width=8, height=8)
(
    ggplot(job, aes(area = duration, label = class_name, fill = tests_total)) +
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
dev.off()
