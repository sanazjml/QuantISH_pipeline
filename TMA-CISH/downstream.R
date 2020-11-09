######### compute weighted mean & variance & uncertainty ###########

# this computes the various aggregates we need
# this function is called once for each group, as defined by "by" below
compute.stat <- function(rows) {
  # get area weights
  wts <- rows$Area
  wts <- wts / sum(wts)   # NB. normalize
  
  # get points
  pts <- rows$SumIntensity / rows$Area
  
  # get weighted mean
  m <- sum( wts * pts )
  
  # get weighted variance
  v <- sum( wts * ( pts - m )^2 )
  
  # get variance (uncertainty) of the mean
  var.m <- v / m
  
  return (data.frame( m = m, v = v, var.m = var.m ))
}


# this is a helper that groups data like aggregate and applies the function to 
# each row and returns the result.. aggregate can't work on multiple variables
# so we need to pass in row indices, work on them, and assemble the mess..
aggr.mv <- function(rows, by, FUN) {
  out <- aggregate( seq_len(nrow(rows)), by = by, FUN = function(row.inds)
    return (FUN( rows[row.inds, , drop = F] )), simplify = F )
  out <- cbind( out[, -ncol(out), drop = F], do.call( rbind, out[, ncol(out)] ) )
  return (out)
}

# mean & variance by spot
stat.by.spot <- aggr.mv( CCNE1, by = data.frame( Spot = CCNE1$Spot, Spot = CCNE1$Spot ), compute.stat )

# mean & variance by patient
# TODO: Positive control (PPIB) filtering
bad.spots <- c( )   # names of bad spots from PPIB analysis
keep <- !( CCNE1$Spot %in% bad.spots )
stat.by.pat <- aggr.mv( CCNE1[keep, ], by = data.frame( Patient = CCNE1[keep, ]$Patient ), compute.stat )

