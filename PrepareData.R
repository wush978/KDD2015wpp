#' Prepare the data of the experiments
#' 
#' Loading required library
suppressPackageStartupMessages({
  library(magrittr)
  library(data.table)
  library(dplyr)
})

source("colClass.R")

loginfo <- function(fmt, ...) {
  cat(sprintf(fmt, ...))
}

#' Join the bid and impression for Winning Rate/Winning Price Prediction
#' Join the impression and click for CTR prediction
update.col.names <- function(x, name) {
  setnames(x, colnames(x), name)
}

parse_timestamp <- function(str) {
  stopifnot(nchar(str) == 17)
  base <- strptime(substring(str, 1, 14), "%Y%m%d%H%M%S")
  ms <- as.numeric(substring(str, 15, 17)) * 1e-3
  base + ms
}

join.bid.imp.clk <- function(bid, impclk) {
  ts <- parse_timestamp(bid$Timestamp)
  bid2 <- mutate(bid, weekday = format(ts, "%w"), hour = format(ts, "%H"), bid_t = ts) %>%
    dplyr::select(BidID, BiddingPrice, IP, Region, City, AdExchange, Domain, URL, AdSlotId,
                  AdSlotWidth, AdSlotHeight, AdSlotVisibility, AdSlotFormat, CreativeID, weekday, hour, bid_t)
  impclk2 <- dplyr::select(impclk, BidID, PayingPrice, adid, usertag, imp_t, is_click, clk_t)
  left_join(bid2, impclk2, by = "BidID") %>%
    arrange(bid_t)
}

join.imp.clk <- function(imp, clk) {
  ts <- parse_timestamp(imp$Timestamp)
  imp2 <- dplyr::mutate(imp, imp_t = ts)
  ts <- parse_timestamp(clk$Timestamp)
  clk2 <- dplyr::mutate(clk, clk_t = ts, is_click = TRUE) %>%
    dplyr::select(BidID, clk_t, is_click)
  dplyr::left_join(imp2, clk2, by = "BidID") %>%
    arrange(imp_t)
}

day.list <- list(
  training2nd = seq.Date(from = as.Date("2013-06-06"), by = 1, length.out = 7),
  training3rd = seq.Date(from = as.Date("2013-10-19"), by = 1, length.out = 9))
fmt <- "%Y%m%d"
for(season in c("training2nd", "training3rd")) {
  for(day in day.list[[season]]) {
    class(day) <- "Date"
    loginfo("joining season: %s day: %s", season, day)
    col.class <- impColClass(season)
    bid <- sprintf("ipinyou.contest.dataset/%s/bid.%s.txt", season, format(day, fmt)) %>%
      fread(sep = "\t", colClasses = as.vector(bidColClass(season)), header = F, showProgress = interactive(), data.table = FALSE) %>%
      update.col.names(names(bidColClass(season)))
    imp <- sprintf("ipinyou.contest.dataset/%s/imp.%s.txt", season, format(day, fmt)) %>%
      fread(sep = "\t", colClasses = as.vector(col.class), header = F, showProgress = interactive(), data.table = FALSE) %>%
      update.col.names(names(col.class))
    clk <- sprintf("ipinyou.contest.dataset/%s/clk.%s.txt", season, format(day, fmt)) %>%
      fread(sep = "\t", colClasses = as.vector(col.class), header = F, showProgress = interactive(), data.table = FALSE) %>%
      update.col.names(names(col.class))
    impclk <- join.imp.clk(imp, clk) %>%
      mutate(is_click = !is.na(is_click))
#     saveRDS(impclk, sprintf("cache/impclk.%s.Rds", format(day, fmt)), compress = FALSE)
    bidimpclk <- join.bid.imp.clk(bid, impclk) %>%
      mutate(is_win = !is.na(PayingPrice))
    saveRDS(bidimpclk, sprintf("cache/bidimpclk.%s.Rds", format(day, fmt)))
#' Use 0.5 times bidding price as real bidding price
#' Split the winning bids and losing bids
    bidimpclk <- as.data.frame(bidimpclk) %>%
      filter(is_win) %>%
      mutate(NewBiddingPrice = 0.5 * BiddingPrice, is_win = PayingPrice < 0.5 * BiddingPrice)
    saveRDS(bidimpclk, sprintf("cache/bidimpclk.%s.sim.Rds", format(day, fmt)))
  }
}
loginfo("Done!")
