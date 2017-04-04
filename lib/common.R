
read_suite <- function (filename) {
    df <- read.delim(
        filename,
        header = TRUE,
        sep = "\t",
        colClasses = c("timestamp" = "character"))
    df$passed <- as.logical(df$passed)
    df$timestamp <- as.POSIXct(sub("T", " ", df$timestamp))
    return (df)
}

read_job_summary <- function(filename) {
    df <-  read.table(
        job_file("job-details.tsv"),
        header = TRUE,
        sep = "\t",
        colClasses = c("timestamp" = "character"))

    return (df[order(df$job_id), ])
}


is.prime <- function(num) {
    if (num == 2) {
        true
    } else if (any(num %% 2:(num-1) == 0)) {
        FALSE
    } else {
        TRUE
    }
}

greatest.prime <- function(n) {
    for (i in as.integer(n):3) {
        if (is.prime(i)) return (i)
    }
    return (NA)
}
