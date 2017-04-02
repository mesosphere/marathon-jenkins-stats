
read_suite <- function (filename) {
    df <- read.delim(
        filename,
        header = TRUE,
        sep = "\t",
        colClasses = c("timestamp" = "character"))
    job_ids <- unique(df$job_id)
    df$job_idx <- match(df$job_id, job_ids)
    df$passed <- as.logical(df$passed)
    df$timestamp <- as.POSIXct(sub("T", " ", df$timestamp))
    return (df)
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
