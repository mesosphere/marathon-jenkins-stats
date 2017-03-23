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

job_name <- Sys.getenv("JOB", unset = "marathon-unstable-loop")
job_name

job_file <- function(filename) {
    return(paste(job_name, "/", filename, sep = ""))
}

df <- read.delim(job_file("flattened-suite.tsv"), header = TRUE, sep = "\t")

df$passed <- as.logical(df$passed)
df$timestamp <- as.POSIXct(sub("T", " ", df$timestamp))

fails <- df[! df$passed, ]
fails$class_name <- factor(fails$class_name)
fails$package <- factor(fails$package)

## recent <- fails[fails$job_id > 1600, ]
## recent$class_name <- factor(recent$class_name)
## recent$package <- factor(recent$package)
## summary(recent)

svg(job_file("failures.svg"), width=12, height = (length(unique(fails$class_name)) / 4) + 0.5)
(
    ggplot(fails, aes(colour = class_name, x = job_id, y = class_name)) +
    geom_point(size = 3) +
    labs(y = "", x = "Job Id", title = paste("Failed suites for", job_name, "by Job (circle indicates failure)")) +
    guides(colour = FALSE) +
    scale_x_continuous(expand = c(0,2))
)
dev.off()

job_id <- max(df$job_id)
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
