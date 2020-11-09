
#
# lmnf -- Linear models for nested factor models 
#   This fits & compares large nested multifactor models when lm() fails
#

#' Anova for a nested factor model
#'
#' @param X The design matrix. Columns are variables, specifying nested factors
#'          such that the more specific factors are on the right.
#' @param y Response.
#' @param w (Optional) sample counts.
#'
#' @return The anova table, as in anova(). 
#'
lmnf.anova <- function(X, y, w = 1.) {
	# get dimensions
	m <- NROW(X)
	k <- NCOL(X)
	# set names
	if (is.null(colnames(X)))
		colnames(X) <- sprintf('X.%d', seq_len(NCOL(X)))

	# set up initial bucketing
	P <- seq_len(m)
	S <- data.frame( sum = w*y, sum.sq = w*(y*y), w = w )

	# compute summary statistics of a state
	summarize <- function(S) {
		# get coefficients
		coefs <- S$sum / S$w
		coefs[!(S$w > 0)] <- 0.   # NB. degenerate

		# get SSE
		cost <- sum( S$sum.sq - coefs * S$sum )
		dofs <- sum( S$w > 0. )

		return (data.frame("Sum Sq" = cost, "Df" = dofs, check.names = F))
	}

	# get first level-- each sample as unique
	stats <- summarize(S)

	# loop
	for (j in rev(seq_len(ncol(X)))) {
		# get new bucketing
		new.P <- match( X[, j], unique(X[, j]) )

		# check that we had a nested bucketing
		 # in this case the mapping map[P] is unambiguous
		map <- rep(0L, max(P))
		map[P] <- new.P
		stopifnot(identical(map[P], new.P))

		# gather
		P <- new.P
		S <- aggregate(S, by = data.frame(P = map), FUN = sum)

		# append
		stats <- rbind( summarize(S), stats )
	}

	# apply final level
	S0 <- aggregate(S, by = data.frame(P = rep(1L, nrow(S))), FUN = sum)
	stats <- rbind( summarize(S0), stats )
	rownames(stats) <- c('Bias', colnames(X), 'Residuals')

	# TODO: strip dupes e.g. if X[,1] ~ Bias or X[,n] ~ Residuals
	 # this can be detected using Df, keep the later row
	keep <- c( diff(stats$Df) > 0L, T )
	names(keep) <- rownames(stats)
	keep[(k+1):(k+2)] <- keep[(k+2):(k+1)]    # NB. keep user-tagged residual
	keep0 <- which(keep)[-sum(keep)]
	keep1 <- which(keep)[-1]

	# get statistics
	ss_fit <- stats$"Sum Sq"[keep0] - stats$"Sum Sq"[keep1]
	 df_fit <- stats$Df[keep1] - stats$Df[keep0]
	ss_err <- ss_fit[length(ss_fit)]
	 df_err <- df_fit[length(df_fit)]
	fstat <- exp( log(ss_fit) - log(df_fit) - (( log(ss_err) - log(df_err) )) )
	 fstat[length(fstat)] <- NA
	log_p <- pf( fstat, df_fit, df_err, lower.tail = F, log.p = T )

	# NOTE: this does current row vs residual of full model
	 # that's what anova() does

	# get ANOVA table
	anova <- data.frame("Df" = df_fit, "Sum Sq" = ss_fit, check.names = F)
	anova$"Mean Sq" <- ss_fit / df_fit
	anova$"F value" <- fstat
	anova$"Pr(>F)" <- exp(log_p)

	# set names
	rownames(anova) <- names(keep)[keep1]

	return (anova)
}

#' Flatten nested factors
#'
#' @param V A matrix or data.frame of factors.
#' @return A new matrix U with least u=U[i,j] such that all(V[i,1:j]==V[u,1:j])
#'
lmnf.flatten.nested <- function(V) {
	# convert V into indices
	U <- matrix(0L, NROW(V), NCOL(V))
	top <- rep(0L, NCOL(V))
	for (j in seq_len(NCOL(V))) {
		U[, j] <- match( V[, j], V[, j] )
		top[j] <- max(U[, j])
	}

	# TODO: I get integer overflow quite easily
	 # for integer math, you can have ~50K items, for double ~94M

	# apply nesting
	r <- 1L
	for (j in seq_len(NCOL(V))) {
		limit <- .Machine$double.base ^ .Machine$double.digits
		stopifnot(all( r - 1L < (( limit - (( U[, j] - 1L )) )) / top[j] ))   # NB. check for loss of precision
		r <- top[j] * (( r - 1. )) + (( U[, j] - 1L ))
		#                ^^^^^^ NB. cast to double here, we get 53 bits
		r <- match( r, r )
		U[, j] <- r
	}

	# set names
	colnames(U) <- colnames(V)

	return (U)
}
