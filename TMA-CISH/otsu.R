
#' Otsu's thresholding
#' 
#' @param x A vector of data values.
#' @param w A compatible vector of sample weights.
#' @return Threshold t such that the classes are x>t.
#'
otsu <- function(x, w = 1.) {
	# get moments
	m0 <- rowsum( w * rep(1., length(x)), x )
	m1 <- rowsum( w*x, x )
	m2 <- rowsum( w*(x*x), x )
	# get values
	u <- m1/m0

	# split moments
	m0.lhs <- cumsum(m0); m0.rhs <- sum(m0)-m0.lhs
	m1.lhs <- cumsum(m1); m1.rhs <- sum(m1)-m1.lhs
	m2.lhs <- cumsum(m2); m2.rhs <- sum(m2)-m2.lhs

	# compute sum-of-squared errors
	cost <- ( m2.lhs - m1.lhs/m0.lhs * m1.lhs ) + 
		( m2.rhs - m1.rhs/m0.rhs * m1.rhs )

	# pick best
	q <- which.min(cost)

	return (u[q])
}
