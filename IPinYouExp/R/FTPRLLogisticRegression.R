FTPRLLogisticRegression <- "FTPRLLogisticRegression"

#'@exportClass FTPRLLogisticRegression
#'@title Prameters of Logistic Regression with FTPRL
#'@name FTPRLLogisticRegression
#'@seealso \link{FTPRL}
setClass(FTPRLLogisticRegression, representation(z = "numeric", n = "numeric"), contains = "FTPRL")

#'@export
init_FTPRLLogisticRegression <- function(alpha, beta, lambda1, lambda2, nfeature) {
  .obj <- new("FTPRLLogisticRegression")
  .obj@alpha <- alpha
  .obj@beta <- beta
  .obj@lambda1 <- lambda1
  .obj@lambda2 <- lambda2
  .obj@z <- numeric(nfeature)
  .obj@n <- numeric(nfeature)
  .obj
}

#'@export
update.FTPRLLogisticRegression <- function(learner, data, y) {
  update_FTPRLLogisticRegression(data, y, learner)
}

#'@export
predict.FTPRLLogisticRegression <- function(learner, data) {
  predict_FTPRLLogisticRegression(data, learner)
}

#'@export
update_FTPRLLogisticRegression <- function(data, y, learner) {
  UseMethod("update_FTPRLLogisticRegression")
}

#'@export
predict_FTPRLLogisticRegression <- function(data, learner) {
  UseMethod("predict_FTPRLLogisticRegression")
}