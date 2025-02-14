#' @include set_coef.R
#' @rdname set_coef
#' @keywords internal
#' @export
set_coef.merMod <- function(model, coefs, ...) {
    # in 'merMod', predictions work the slot called "beta", which is unnamed
    # `fixef(model)` returns the same thing named
    beta <- methods::slot(model, "beta")
    beta[match(names(coefs), names(lme4::fixef(model)))] <- as.numeric(coefs)
    methods::slot(model, "beta") <- beta
    model
}


#' @include get_coef.R
#' @rdname get_coef
#' @export
get_coef.merMod <- function(model, ...) {
    lme4::fixef(model)
}


#' @rdname get_predict
#' @export
get_predict.merMod <- function(model,
                               newdata = insight::get_data(model),
                               vcov = FALSE,
                               conf_level = 0.95,
                               type = "response",
                               ...) {

    get_predict.default(model,
                        newdata = newdata,
                        vcov = vcov,
                        conf_level = conf_level,
                        type = type,
                        ...)
}


#' @rdname set_coef
#' @export
set_coef.lmerModLmerTest <- set_coef.merMod


#' @rdname get_coef
#' @export
get_coef.lmerModLmerTest <- get_coef.merMod


#' @rdname get_predict
#' @export
get_predict.lmerModLmerTest <- get_predict.merMod


#' @rdname set_coef
#' @export
set_coef.lmerMod <- set_coef.merMod


#' @rdname get_coef
#' @export
get_coef.lmerMod <- get_coef.merMod


#' @rdname get_predict
#' @export
get_predict.lmerMod <- get_predict.merMod


