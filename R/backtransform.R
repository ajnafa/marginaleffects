backtransform <- function(x, transform_post) {

    # transform_post can be a function or a named list of length 1 with a function, but could be NULL
    if (!is.function(transform_post)) {
        if (is.null(transform_post[[1]])) {
            return(x)
        } else {
            transform_post <- transform_post[[1]]
        }
    }
   

    checkmate::assert_data_frame(x)
    checkmate::assert_function(transform_post)
    cols <- intersect(colnames(x), c("estimate", "conf.low", "conf.high"))
    draws <- attr(x, "posterior_draws")

    if (!is.null(draws)) {
        draws <- transform_post(draws)
    }

    for (col in cols) {
        x[[col]] <- transform_post(x[[col]])
    }
    for (col in c("std.error", "statistic")) {
        x[[col]] <- NULL
    }

    attr(x, "posterior_draws") <- draws

    return(x)
}
