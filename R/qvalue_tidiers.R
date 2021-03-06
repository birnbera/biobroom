#' Tidying methods for a qvalue object
#'
#' These are methods for turning a qvalue object, from the qvalue package for
#' false discovery rate control, into a tidy data frame. \code{augment}
#' returns a data.frame of the original p-values combined with the computed
#' q-values and local false discovery rates, \code{tidy} constructs a table
#' showing how the estimate of pi0 (the proportion of true nulls) depends
#' on the choice of the tuning parameter lambda, and \code{glance} returns a
#' data.frame with only the chosen pi0 value.
#'
#' @param x qvalue object
#' @param data Original data
#' @param ... extra arguments (not used)
#'
#' @return All tidying methods return a \code{data.frame} without rownames.
#' The structure depends on the method chosen.
#'
#' \code{tidy} returns one row for each choice of the tuning
#' parameter lambda that was considered (argument \code{lambda} to qvalue),
#' containing
#' \item{lambda}{the tuning parameter}
#' \item{pi0}{corresponding estimate of pi0}
#' \item{smoothed}{whether the estimate has been spline-smoothed)}
#'
#' If \code{pi0.method="smooth"}, the pi0 estimates and smoothed values both
#' appear in the table. If \code{pi0.method="bootstrap"}, \code{smoothed}
#' is FALSE for all entries.
#'
#' @name qvalue_tidiers
#'
#' @examples
#'
#' library(ggplot2)
#' if (require("qvalue")) {
#' set.seed(2014)
#'
#' # generate p-values from many one sample t-tests: half of them null
#' oracle <- rep(c(0, .5), each=1000)
#' pvals <- sapply(oracle, function(mu) t.test(rnorm(15, mu))$p.value)
#' qplot(pvals)
#'
#' q <- qvalue(pvals)
#'
#' tidy(q)
#' head(augment(q))
#' glance(q)
#'
#' # use augmented data to compare p-values to q-values
#' ggplot(augment(q), aes(p.value, q.value)) + geom_point()
#'
#' # use tidy see how pi0 estimate changes with lambda, comparing
#' # to smoothed version
#' g <- ggplot(tidy(q), aes(lambda, pi0, color=smoothed)) + geom_line()
#' g
#'
#' # show the chosen value
#' g + geom_hline(yintercept=q$pi0, lty=2)
#' }
#' @import broom dplyr
#' @importFrom tidyr gather spread
#' @S3method tidy qvalue
#' @export tidy.qvalue
tidy.qvalue <- function(x, ...) {
    ret <- as.data.frame(compact(x[c("lambda", "pi0.lambda", "pi0.smooth")]))
    ret <- ret %>% tidyr::gather(smoothed, pi0, -lambda) %>%
    dplyr::mutate(smoothed=(smoothed == "pi0.smooth"))
    finish(ret)
}

#' @rdname qvalue_tidiers
#'
#' @return \code{augment} returns a data.frame with
#'     \item{p.value}{the original p-values given to \code{qvalue}}
#'     \item{q.value}{the computed q-values}
#'     \item{lfdr}{the local false discovery rate}
#' @S3method augment qvalue
#' @export augment.qvalue
augment.qvalue <- function(x, data, ...) {
    df <- data.frame(p.value=x$pvalues, q.value=x$qvalues, lfdr=x$lfdr, ...)
    if (!missing(data)) {
        df <- cbind(as.data.frame(data), df)
    }
    df <- df[, !duplicated(colnames(df))]
    finish(df)
}


#' @rdname qvalue_tidiers
#'
#' @return \code{glance} returns a one-row data.frame containing
#'     \item{pi0}{the estimated pi0 (proportion of nulls)}
#'     \item{lambda}{lambda used to compute pi0. Note that if pi0 is 1,
#'     this may be NA since it can be ambiguous which lambda was used}
#'
#' @S3method glance qvalue
#' @export glance.qvalue
glance.qvalue <- function(x, ...) {
    # find choice of lambda
    if (!is.null(x$pi0.smooth)) {
        lambda <- x$lambda[which(x$pi0.smooth == x$pi0)[1]]
    } else {
        lambda <- x$lambda[which(x$pi0.lambda == x$pi0)[1]]
    }
    df <- data.frame(pi0 = x$pi0, lambda = lambda)
    finish(df)
}
