get_se_delta_marginalmeans <- function(model,
                                       variables,
                                       newdata,
                                       type,
                                       eps = 1e-4, # avoid pushing through ...
                                       cross = FALSE,
                                       ...) {
    get_marginalmeans(
        model = model,
        variables = variables,
        newdata = newdata,
        type = type,
        cross = cross,
        ...
    )$estimate
}


get_se_delta_contrasts <- function(model,
                                   variables,
                                   newdata,
                                   type,
                                   contrast_factor,
                                   contrast_numeric,
                                   eps,
                                   hypothesis,
                                   lo,
                                   hi,
                                   original,
                                   cross,
                                   ...) {
    get_contrasts(model,
        newdata = newdata,
        variables = variables,
        type = type,
        eps = eps,
        hypothesis = hypothesis,
        lo = lo,
        hi = hi,
        original = original,
        cross = cross,
        verbose = FALSE,
        deltamethod = TRUE,
        ...
    )$estimate
}



#' Compute standard errors using the delta method
#'
#' @inheritParams slopes
#' @param FUN a function which accepts a `model` and other inputs and returns a
#'   vector of estimates (marginal effects, marginal means, etc.)
#' @param index data.frame over which we aggregate J_mean (matches tidy() output)
#' @return vector of standard errors
#' @noRd
get_se_delta <- function(model,
                         vcov,
                         FUN,
                         type = NULL,
                         newdata = NULL,
                         index = NULL,
                         eps = NULL,
                         J = NULL,
                         hypothesis = NULL,
                         ...) {

    # delta method does not work for these models
    bad <- c("brmsfit", "stanreg")
    if (any(bad %in% class(model))) {
        return(NULL)
    }

    coefs <- get_coef(model, ...)

    # TODO: this is a terrible sanity check
    # some vcov methods return an unnamed matrix, some have duplicate names
    if (!is.null(dimnames(vcov)) && anyDuplicated(colnames(vcov)) == 0 &&
        all(names(coefs) %in% colnames(vcov))) {
        vcov <- vcov[names(coefs), names(coefs), drop = FALSE]
    }

    # input: named vector of coefficients
    # output: gradient
    inner <- function(x) {
        model_tmp <- set_coef(model, stats::setNames(x, names(coefs)) ,...)
        # do not pass NULL arguments. Important for `deltam` to allow users to supply FUN without ...
        args <- c(list(model = model_tmp, hypothesis = hypothesis), list(...))
        if (inherits(model, "gamlss")) args[["safe"]] <- FALSE
        if (!is.null(eps)) args[["eps"]] <- eps
        if (!is.null(type)) args[["type"]] <- type
        if (!is.null(newdata)) args[["newdata"]] <- newdata
        if (!is.null(J)) args[["J"]] <- J
        g <- do.call("FUN", args)
        return(g)
    }

    if (is.null(J) || !is.null(hypothesis)) {
        args <- list(
            func = inner,
            x = coefs)
        if (is.null(eps)) {
            args[["eps"]] <- 1e-4
        } else {
            args[["eps"]] <- eps
        }
        J <- do.call("get_jacobian", args)
        colnames(J) <- names(get_coef(model, ...))
    }

    # align J and V: This might be a problematic hack, but I have not found examples yet.
    V <- vcov
    if (!isTRUE(ncol(J) == ncol(V))) {
        cols <- intersect(colnames(J), colnames(V))
        if (length(cols) == 0) {
           insight::format_error("The jacobian does not match the variance-covariance matrix.")
        }
        V <- V[cols, cols, drop = FALSE]
        J <- J[, cols, drop = FALSE]
    }

    # Var(dydx) = J Var(beta) J'
    # computing the full matrix is memory-expensive, and we only need the diagonal
    # algebra trick: https://stackoverflow.com/a/42569902/342331
    se <- sqrt(colSums(t(J %*% V) * t(J)))
    attr(se, "jacobian") <- J

    return(se)
}
