gmean <- function(x){
  exp(mean(log(x[!is.infinite(x)]), na.rm = TRUE))
}

'%!in%' <- function(x, y)!('%in%'(x, y))
