library(Matrix)
library(FeatureHashing)
day.list <- list(
  training2nd = seq.Date(from = as.Date("2013-06-06"), by = 1, length.out = 7),
  training3rd = seq.Date(from = as.Date("2013-10-19"), by = 1, length.out = 9))
fmt <- "%Y%m%d"
model_wp <- ~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
  AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
  hour + adid + split(usertag)
model_ctr <- ~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
  AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
  hour + adid + split(usertag)

season <- "training2nd"
get_bidimpclk <- function(i) {
  day <- day.list[[season]][i]
  readRDS(sprintf("cache/bidimpclk.%s.sim2.Rds", format(day, "%Y%m%d")))
}
get_m <- function(df, model, transpose) {
  hashed.model.matrix(model, df, hash.size = 2^20, transpose = transpose, is.dgCMatrix = FALSE)
}
censored_regression2 <- function(m, y, is_win, sigma, lambda2 = 1, start = rep(0.0, nrow(m))) {
  f.w <- function(w) {
    z <- (w %*% m - y) / sigma
    - (sum(dnorm(z[is_win], log = TRUE)) + sum(pnorm(z[!is_win], lower.tail = TRUE, log.p = TRUE))) + lambda2 * sum(w^2) / 2
  }
  g.w <- function(w) {
    z <- (w %*% m - y) / sigma
    z.observed <- dzdl.observed <- z[is_win]
    z.censored <- z[!is_win]
    dzdl.censored <- -exp(dnorm(z.censored, log = TRUE) - pnorm(z.censored, log.p = TRUE))
    dzdl <- z
    dzdl[!is_win] <- dzdl.censored
    (m %*% dzdl) / sigma + w
  }
  r.w <- optim(start, f.w, g.w, method = "L-BFGS-B", control = list(maxit = ifelse(interactive(), 100, 20000), trace = ifelse(interactive(), 1, 0)))
  list(predict = function(m) r.w$par %*% m, r = r.w)
}

bidimpclk1 <- get_bidimpclk(1)
bidimpclk1 <- bidimpclk1[!is.na(bidimpclk1$is_click),]
m1.wp <- get_m(bidimpclk1, model_wp, TRUE)
g.wp <- censored_regression2(m1.wp, bidimpclk1$PayingPrice, rep(TRUE, nrow(bidimpclk1)), sd(bidimpclk1$PayingPrice))

bidimpclk2 <- get_bidimpclk(2)
bidimpclk2 <- bidimpclk2[!is.na(bidimpclk2$is_click),]
m2.wp <- get_m(bidimpclk2, model_wp, TRUE)
wp.hat2 <- g.wp$predict(m2.wp)
m2.ctr <- as(get_m(bidimpclk2, model_ctr, TRUE), "dgCMatrix")
m2.ctr@Dimnames[[1]] <- paste(seq_len(nrow(m2.ctr)))
dim(m2.ctr)
length(wp.hat2)

bidimpclk3 <- get_bidimpclk(3)
bidimpclk3 <- bidimpclk3[!is.na(bidimpclk3$is_click),]
m3.wp <- get_m(bidimpclk3, model_wp, TRUE)
wp.hat3 <- g.wp$predict(m3.wp)
m3.ctr <- as(get_m(bidimpclk3, model_ctr, TRUE), "dgCMatrix")
m3.ctr@Dimnames[[1]] <- paste(seq_len(nrow(m3.ctr)))

m2.ctrwp <- rBind(m2.ctr, wp.hat2)
m3.ctrwp <- rBind(m3.ctr, wp.hat3)
clk2 <- bidimpclk2$is_click
clk3 <- bidimpclk3$is_click

source(system.file("ftprl.R", package = "FeatureHashing"))
learner.ctr <- initialize.ftprl(0.1, 1, 0.1, 0.1, nrow(m2.ctr))
learner.ctr <- update.ftprl(learner.ctr, m2.ctr, clk2)
glmnet::auc(clk3, predict.ftprl(learner.ctr, m3.ctr))

learner.ctrwp <- initialize.ftprl(0.1, 1, 0.1, 0.1, nrow(m2.ctrwp))
learner.ctrwp <- update.ftprl(learner.ctrwp, m2.ctrwp, clk2)
glmnet::auc(clk3, predict.ftprl(learner.ctrwp, m3.ctrwp))

# 
# 
# library(glmnet)
# g.ctr <- cv.glmnet(m2.ctr, clk2, family = "binomial", alpha = 0.5, type.measure = "auc",
#                    intercept = FALSE, standardize = FALSE)
# r.ctr <- predict(g.ctr, m3.ctr, s = "lambda.min")
# auc(clk3, r.ctr)
# 
# g.ctrwp <- cv.glmnet(m2.ctrwp, clk2, family = "binomial", alpha = 0.5, type.measure = "auc",
#                    intercept = FALSE, standardize = FALSE)
# r.ctrwp <- predict(g.ctrwp, m3.ctrwp, s = "lambda.min")
# auc(clk3, r.ctrwp)
# system("notify-send R 'exp done!' -t 10000")
