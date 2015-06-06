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
                           hour + adid + tag(usertag), bidimpclk, transpose = TRUE)
learner_ctr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
tmp <- OnlineSimulation(m, learner_ctr, learner_wr, bidimpclk$is_click, bidimpclk$is_win, bidimpclk$bid_t, bidimpclk$clk_t)
ctr <- tmp$ctr
df1 <- bidimpclk[1:204381,] %>% as.data.frame
df2 <- bidimpclk[204382:nrow(bidimpclk),] %>% as.data.frame
m1 <- hashed.model.matrix(~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
                            AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
                            hour + adid + tag(usertag), df1, transpose = TRUE)
m2 <- hashed.model.matrix(~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
                      AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
                      hour + adid + tag(usertag), df2, transpose = TRUE)
learner_ctr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
tmp1 <- OnlineSimulation(m1, learner_ctr, learner_wr, 
                        df1$is_click, df1$is_win, df1$bid_t, df1$clk_t)
ctr1 <- tmp1$ctr
tmp2 <- OnlineSimulation(m2, learner_ctr, learner_wr, 
                        df2$is_click, df2$is_win, df2$bid_t, df2$clk_t, 
                        TRUE)
ctr2 <- tmp2$ctr
stopifnot(max(abs(c(ctr1, ctr2) - ctr)) < 1e-7)
max(abs(c(ctr1, ctr2) - ctr))
stopifnot(max(abs(c(tmp1$wr, tmp2$wr) - tmp$wr)) < 1e-7)
max(abs(c(tmp1$wr, tmp2$wr) - tmp$wr))

learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
tmp <- OnlineSimulation2(m, learner_wr, ctr, bidimpclk$is_win, bidimpclk$bid_t)
learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m1))
tmp1 <- OnlineSimulation2(m1, learner_wr, ctr1, df1$is_win, df1$bid_t)
tmp2 <- OnlineSimulation2(m2, learner_wr, ctr2, df2$is_win, df2$bid_t, TRUE)
stopifnot(max(abs(c(tmp1$wr, tmp2$wr) - tmp$wr)) < 1e-7)
max(abs(c(tmp1$wr, tmp2$wr) - tmp$wr))

# learner_ctr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
# learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
# tmp <- OnlineSimulation(m, learner_ctr, learner_wr, bidimpclk$is_click, bidimpclk$is_win, bidimpclk$bid_t, bidimpclk$clk_t)
# ctr <- tmp$ctr
# learner_ctr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
# learner_wr <- init_FTPRLLogisticRegression(0.1, 1, 0.1, 0.1, nrow(m))
# tmp1 <- OnlineSimulation(m1, learner_ctr, learner_wr, 
#                         df1$is_click, df1$is_win, df1$bid_t, df1$clk_t)
# ctr1 <- tmp1$ctr
# tmp2 <- OnlineSimulation(m2, learner_ctr, learner_wr, 
#                         df2$is_click, df2$is_win, df2$bid_t, df2$clk_t, 
#                         TRUE)
# ctr2 <- tmp2$ctr
# stopifnot(max(abs(c(ctr1, ctr2) - ctr)) < 1e-7)
