#'@export
bidColClass <- function(name = c("training1st", "training2nd", "training3rd")) {
  bidclass <- c(
    BidID = "character",
    Timestamp = "character",
    iPinyouID = "character",
    UserAgent = "character",
    IP = "character",
    Region = "character",
    City = "character",
    AdExchange = "character",
    Domain = "character",
    URL = "character",
    AnonymousURLId = "character",
    AdSlotId = "character",
    AdSlotWidth = "character",
    AdSlotHeight = "character",
    AdSlotVisibility = "character",
    AdSlotFormat = "character",
    AdSlotFloorPrice = "numeric",
    CreativeID = "character",
    BiddingPrice = "numeric"
  )
  switch(name[1],
    "training1st" = bidclass,
    "training2nd" = c(bidclass, adid = "character", usertag = "character"),
    "training3rd" = c(bidclass, adid = "character", usertag = "character"),
    stop("Invalid name")
  )
}

#'@export
impColClass <- function(name = c("training1st", "training2nd", "training3rd")) {
  impclass <- c(
    BidID = "character",
    Timestamp = "character",
    LogType = "integer",
    iPinyouID = "character",
    UserAgent = "character",
    IP = "character",
    Region = "integer",
    City = "integer",
    AdExchange = "integer",
    Domain = "character",
    URL = "character",
    AnonymousURLId = "character",
    AdSlotId = "character",
    AdSlotWidth = "character",
    AdSlotHeight = "character",
    AdSlotVisibility = "character",
    AdSlotFormat = "character",
    AdSlotFloorPrice = "numeric",
    CreativeID = "character",
    BiddingPrice = "numeric",
    PayingPrice = "numeric",
    KeyPageURL = "character"
  )
  switch(name[1],
         "training1st" = impclass,
         "training2nd" = c(impclass, adid = "character", usertag = "character"),
         "training3rd" = c(impclass, adid = "character", usertag = "character"),
         stop("Invalid name")
  )
}