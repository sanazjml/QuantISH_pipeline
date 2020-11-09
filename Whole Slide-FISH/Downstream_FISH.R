######### compute weighted mean & variance & uncertainty ###########

# this computes the various aggregates we need
# this function is called once for each group, as defined by "by" below
compute.stat <- function(rows) {
  # get area weights
  wts <- rows$Area
  wts <- wts / sum(wts)   # NB. normalize
  
  # get points
  pts_Cy5 <- rows$SumIntensity_Cy5 / rows$Area
  pts_FITC <- rows$SumIntensity_FITC / rows$Area
  pts_TRITC <- rows$SumIntensity_TRITC / rows$Area
  
  # get weighted mean
  m_Cy5 <- sum( wts * pts_Cy5 )
  m_FITC <- sum( wts * pts_FITC )
  m_TRITC <- sum( wts * pts_TRITC )
  # get weighted variance
  v_Cy5 <- sum( wts * ( pts_Cy5 - m_Cy5 )^2 )
  v_FITC <- sum( wts * ( pts_FITC - m_FITC )^2 )
  v_TRITC <- sum( wts * ( pts_TRITC - m_TRITC )^2 )
  
  # get variance (uncertainty) of the mean
  var.m_Cy5 <- v_Cy5 / m_Cy5
  var.m_FITC <- v_FITC / m_FITC
  var.m_TRITC <- v_TRITC/ m_TRITC
  
  return (data.frame( m_Cy5 = m_Cy5, m_FITC = m_FITC, m_TRITC = m_TRITC, v_Cy5 = v_Cy5, v_FITC = v_FITC, v_TRITC = v_TRITC
                      , var.m_Cy5 = var.m_Cy5, var.m_FITC = var.m_FITC, var.m_TRITC = var.m_TRITC  ))
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



# mean & variance by patient
stat.by.pat <- aggr.mv( Data_final, by = data.frame( Patient = Data_final$Patient_ID ), compute.stat )
