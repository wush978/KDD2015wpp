#' Prepare the data of the experiments
#' 
#' Loading required library
suppressPackageStartupMessages({
  library(methods)
  library(data.table)
  library(dplyr)
  library(IPinYouExp)
  library(FeatureHashing)
  library(FastROC)
})

loginfo <- function(fmt, ...) {
  cat(sprintf("(%s) ", Sys.time()))
  cat(sprintf(fmt, ...))
  cat("\n")
}

logloss <- function(y, p, tol = 1e-6) {
  p[p < tol] <- tol
  p[p > 1 - tol] <- 1 - tol
  mean(- y * log(p) - (1 - y) * log(1 - p))
}

aucloss <- function(y, p) {
  roc <- ROC(y, p, min(1000, length(y)))
  AUC(roc$x, roc$y)
}

day.list <- list(
  training2nd = seq.Date(from = as.Date("2013-06-06"), by = 1, length.out = 7),
  training3rd = seq.Date(from = as.Date("2013-10-19"), by = 1, length.out = 9))
fmt <- "%Y%m%d"
wp.ratio.all <- c(1/6, 1/3, 1/2, 2/3, 5/6)
for(wp.ratio.i in seq_along(wp.ratio.all)) {
  wp.ratio <- wp.ratio.all[wp.ratio.i]
  for(season in c("training3rd")) {
    learner_ctr <- init_FTPRLLogisticRegression(0.01, 0.1, 0.1, 0.1, 2^20)
    learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, 2^20)
    reset_cache()
    gc()
    for(i in seq_along(day.list[[season]])) {
      day <- day.list[[season]][i]
      loginfo("processing %s...", day)
      bidimpclk <- readRDS(sprintf("cache/bidimpclk.%s.sim.Rds", format(day, "%Y%m%d")))
      bidimpclk <- mutate(bidimpclk, is_win = PayingPrice < wp.ratio * BiddingPrice)
      bidimpclk$is_click[!bidimpclk$is_win] <- NA
      m <- hashed.model.matrix(~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
                                 AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
                                 hour + adid + split(usertag), bidimpclk, 2^20, transpose = TRUE, is.dgCMatrix = FALSE) %>%
        as("dgCMatrix")
      tmp <- OnlineSimulation(m, learner_ctr, learner_wr,
                              bidimpclk$is_click, bidimpclk$is_win, bidimpclk$bid_t, bidimpclk$clk_t, i != 1)
      bidimpclk$ctr <- tmp$ctr
      bidimpclk$wr <- tmp$wr
      loginfo("ctr logloss: %f aucloss: %f on %s", 
              logloss(bidimpclk$is_click[!is.na(bidimpclk$is_click)], bidimpclk$ctr[!is.na(bidimpclk$is_click)]),
              aucloss(bidimpclk$is_click[!is.na(bidimpclk$is_click)], bidimpclk$ctr[!is.na(bidimpclk$is_click)]),
              day)
      loginfo("winning rate logloss: %f aucloss: %f on %s", 
              logloss(bidimpclk$is_win, bidimpclk$wr),
              aucloss(bidimpclk$is_win, bidimpclk$wr),
              day)
      saveRDS(bidimpclk, sprintf("cache/bidimpclk.%s.%d.sim2.Rds", format(day, "%Y%m%d"), wp.ratio.i))
    }
  }
}
