FTPRL <- "FTPRL"

#'@exportClass FTPRL
#'@title Parameters of Follow The Proximal Regularized Leader Algorithms
#'@name FTPRL
#'@aliases FTPRL
#'
#'@section Slots:
#'  \describe{
#'    \item{\code{alpha}: Learning rate.}
#'    \item{\code{beta}: Regularization of initial learning rate.}
#'    \item{\code{lambda1}: $L_1$ regularization.}
#'    \item{\code{lambda2}: $L_2$ regularization.}
#'  }
#'
#'@details TODO
setClass(FTPRL, representation(alpha = "numeric", beta = "numeric", lambda1 = "numeric", lambda2 = "numeric"))

setMethod("$",
    signature(x = "FTPRL"),
    function (x, name) 
    {
      if (name == "w") {
        return (.get_w(x))
      }
    }
)
