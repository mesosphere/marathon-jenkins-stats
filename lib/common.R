read_jobs <- function(filename) {
    df <- read.delim(
        filename,
        header = TRUE,
        sep = "\t")
    df$non_empty <- as.logical(df$non_empty)
    df$total_count[is.na(df$total_count)] <- 0
    df$pass_count[is.na(df$pass_count)] <- 0
    df$fail_count[is.na(df$fail_count)] <- 0
    df$skip_count[is.na(df$skip_count)] <- 0
    return (df)
}

read_suite <- function (filename) {
    df <- read.delim(
        filename,
        header = TRUE,
        sep = "\t"## ,
        ## colClasses = c("timestamp" = "character")
    )
    df$passed <- as.logical(df$passed)
    df$timestamp <- as.POSIXct(sub("T", " ", df$timestamp))
    return (df)
}

read_job_details <- function(filename) {
    df <-  read.table(
        filename,
        header = TRUE,
        sep = "\t"## ,
        ## colClasses = c("timestamp" = "character")
    )

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

shift <- function(vector) {
    if (length(vector) == 0)
        return (vector)
    else
        return (unlist(list(vector[1], vector[-length(vector)])))
}

unshift <- function(vector) {
    if (length(vector) == 0)
        return (vector)
    else
        return (unlist(list(vector[-1], vector[length(vector)])))
}

render.twice <- function (fn, file.prefix, width, height) {
    pdf(paste(file.prefix, "pdf", sep="."), width=width, height=height)
    print(fn())
    dev.off()
    svg(paste(file.prefix, "svg", sep="."), width=width, height=height)
    print(fn())
    dev.off()
}
