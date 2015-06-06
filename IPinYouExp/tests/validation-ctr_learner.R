library(methods)
library(dplyr)
library(IPinYouExp)

data(bidimpclk)
nrow(bidimpclk)

bidimpclk <- arrange(bidimpclk, bid_t)


is_click <- rep(NA, nrow(bidimpclk))
is_click[bidimpclk$is_win] <- FALSE
is_click[!is.na(bidimpclk$is_click)] <- TRUE
bidimpclk$is_click <- is_click
library(FeatureHashing)
m <- hashed.model.matrix(~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
                           AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
                           hour + adid + tag(usertag), bidimpclk) %>%
  as("dgCMatrix")
learner_ctr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
tmp <- OnlineSimulation(m, learner_ctr, learner_wr, bidimpclk$is_click, bidimpclk$is_win, bidimpclk$bid_t, bidimpclk$clk_t)

bidimpclk2 <- filter(bidimpclk, !is.na(is_click), bid_t < max(bid_t) - 600)
m2 <- hashed.model.matrix(~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
                           AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
                           hour + adid + tag(usertag), bidimpclk2) %>%
  as("dgCMatrix")
library(BridgewellML)
learner_ctr2 <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m2))
update(learner_ctr2, m2, bidimpclk2$is_click)
w1 <- learner_ctr$w
w2 <- learner_ctr2$w

stopifnot(max(abs(w1 - w2)) < 1e-7)
