
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
