#' Prepare the data of the experiments
#' 
#' Loading required library
suppressPackageStartupMessages({
  library(methods)
  library(data.table)
  library(dplyr)
  library(IPinYouExp)
  library(FeatureHashing)
})

loginfo <- function(fmt, ...) {
  cat(sprintf("(%s) ", Sys.time()))
  cat(sprintf(fmt, ...))
  cat("\n")
}

day.list <- list(
  training2nd = seq.Date(from = as.Date("2013-06-06"), by = 1, length.out = 7),
  training3rd = seq.Date(from = as.Date("2013-10-19"), by = 1, length.out = 9))
fmt <- "%Y%m%d"

# model1 <- ~ IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
#   AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
#   hour + adid + split(usertag) + ctr + wr

model1 <- ~ wr * (IP + Region + City + AdExchange + Domain + URL + AdSlotId + AdSlotWidth +
                    AdSlotHeight + AdSlotVisibility + AdSlotFormat + CreativeID + weekday +
                    hour + adid + split(usertag) + ctr)

linear_regression <- function(m, y, lambda2 = 1000, start = rep(0.0, nrow(m))) {
  f <- function(w) {
    sum((w %*% m - y)^2) + lambda2 * sum(tail(w, -1)^2) / 2
  }
  g <- function(w) {
    2 * (m %*% (w %*% m - y)) + lambda2 * c(0, tail(w, -1))
  }
  r <- optim(start, f, g, method = "L-BFGS-B", control = list(maxit = ifelse(interactive(), 100, 20000), trace = ifelse(interactive(), 1, 0)))
  list(predict = function(m) r$par %*% m, r = r)
}

censored_regression <- function(m, y, is_win, lambda2 = 1, start = rep(0.0, nrow(m) + 1)) {
  f <- function(wall) {
    sigma <- exp(tail(wall, 1))
    w <- head(wall, -1)
    z <- (w %*% m - y) / sigma
    - (sum(dnorm(z[is_win], log = TRUE)) + sum(pnorm(z[!is_win], lower.tail = TRUE, log.p = TRUE)) - sum(is_win) * tail(wall, 1)) + lambda2 * sum(wall^2) / 2
  }
  g <- function(wall) {
    sigma <- exp(tail(wall, 1))
    w <- head(wall, -1)
    z <- (w %*% m - y) / sigma
    z.observed <- dzdl.observed <- z[is_win]
    z.censored <- z[!is_win]
    dzdl.censored <- -exp(dnorm(z.censored, log = TRUE) - pnorm(z.censored, log.p = TRUE))
    dzdl <- z
    dzdl[!is_win] <- dzdl.censored
    c((m %*% dzdl) / sigma, - dzdl %*% z + sum(is_win)) + lambda2 * wall
  }
  r <- optim(start, f, g, method = "L-BFGS-B", control = list(maxit = ifelse(interactive(), 100, 20000), trace = ifelse(interactive(), 1, 0)))
  w <- head(r$par, -1)
  list(predict = function(m) w %*% m, r = r)
}

censored_regression2 <- function(m, y, is_win, sigma, lambda2 = 1000, start = rep(0.0, nrow(m))) {
  f.w <- function(w) {
    z <- (w %*% m - y) / sigma
    - (sum(dnorm(z[is_win], log = TRUE)) + sum(pnorm(z[!is_win], lower.tail = TRUE, log.p = TRUE))) + lambda2 * sum(tail(w, -1)^2) / 2
  }
  g.w <- function(w) {
    z <- (w %*% m - y) / sigma
    z.observed <- dzdl.observed <- z[is_win]
    z.censored <- z[!is_win]
    dzdl.censored <- -exp(dnorm(z.censored, log = TRUE) - pnorm(z.censored, log.p = TRUE))
    dzdl <- z
    dzdl[!is_win] <- dzdl.censored
    (m %*% dzdl) / sigma + lambda2 * c(0, tail(w, -1))
  }
  r.w <- optim(start, f.w, g.w, method = "L-BFGS-B", control = list(maxit = ifelse(interactive(), 100, 20000), trace = ifelse(interactive(), 1, 0)))
  list(predict = function(m) r.w$par %*% m, r = r.w)
}

censored_regression.em <- function(m, y, start, lambda2 = 1, tol = 1e-4) {
  Q <- function(w.previous, sigma.previous) {
    mu.previous <- w.previous %*% m$loose
    alpha.previous <- (y$loose - mu.previous) / sigma.previous
    lambda <- exp(dnorm(alpha.previous, log = TRUE) - pnorm(alpha.previous, lower.tail = FALSE, log.p = TRUE))
    y.previous <- mu.previous + sigma.previous * lambda
    correctness <- sum(1 - lambda^2 + lambda * alpha.previous)
    f <- function(w) {
      sum((y$win - w %*% m$win)^2) + sum((y.previous - w %*% m$loose)^2) + lambda2 * sum(w[-1]^2) / 2
    }
    g <- function(w) {
      2 * (m$win %*% as.vector(w %*% m$win - y$win)) + 2 * (m$loose %*% as.vector(w %*% m$loose - y.previous)) +
        c(0, w[-1]) * lambda2
    }
    f.correct <- function(f.min) {
      f.min + correctness * sigma.previous^2
    }
    list(fn = f, gn = g, f.correct = f.correct)    
  }
  theta.previous <- start
  repeat {
    q <- Q(head(theta.previous, -1), tail(theta.previous, 1))
    r <- optim(par = head(theta.previous, -1), q$fn, q$gn, method = "L-BFGS-B")
    theta <<- c(r$par, sqrt( q$f.correct(r$value) / n))
    if (sqrt(sum((theta - theta.previous)^2)) < tol) {
      w <- head(theta, -1)
      sigma <- tail(theta, 1)
      retval <- list(predict = function(m) w %*% m, r = theta)
    }
    theta.previous <- theta
  }
}


mseloss <- function(y, y.hat) {
  mean((y - y.hat)^2)
}

apply_win_loose <- function(df) {
  df.win <- dplyr::filter(df, is_win) %>% as.data.frame
  df.loose <- dplyr::filter(df, !is_win) %>% as.data.frame
  function(f, ...) {
    list(all = f(df, ...), win = f(df.win, ...), loose = f(df.loose, ...))
  }
}

do_exp <- function (model, model_name) {
#   browser()
  loginfo("processing exp with model:%s", model_name)
  m1 <- apply_f(hashed.model.matrix, formula = model, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)
  m1.next <- apply_f.next(hashed.model.matrix, formula = model, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)
  for(name in c("all", "win", "loose")) {
    loginfo("mse of averaged observed y at training day %s on data %s is %f", day, name, mseloss(y[[name]], mean(y$win)))
    loginfo("mse of averaged observed y at testing day %s on data %s is %f", day, name, mseloss(y.next[[name]], mean(y$win)))
  }
  { # lm on win
    .start <- rep(0, nrow(m1$win));.start[1] <- mean(y$win)
    progressive.cv <- list()
    for(lambda2 in c(1000, 2000, 3000, 4000, 5000)) {
      l.win_lm <- linear_regression(m1$win, y$win, lambda2, start = .start)
      loginfo("lambda2: %d", lambda2)
      for(name in c("all", "win", "loose")) {
        loginfo("mse of lm (winning bids) at training day %s on data %s is %f", day, name, mseloss(y[[name]], l.win_lm$predict(m1[[name]])))
        loginfo("mse of lm (winning bids) at testing day %s on data %s is %f", day, name, mseloss(y.next[[name]], l.win_lm$predict(m1.next[[name]])))
      }
      progressive.cv[[paste(lambda2)]] <- mseloss(y.next[["all"]], l.win_lm$predict(m1.next[["all"]]))
    }
    lambda2 <- unlist(progressive.cv) %>% which.min %>% names %>% as.numeric
    loginfo("lambda2: %d", lambda2)
    l.win_lm <- linear_regression(m1$win, y$win, lambda2, start = .start)
  }
  { # lm on loose
    .start <- l.win_lm$r$par
    l.loose_lm <- linear_regression(m1$loose, y$loose, lambda2 = lambda2, start = .start)
    for(name in c("all", "win", "loose")) {
      loginfo("mse of lm (losing bids) at training day %s on data %s is %f", day, name, mseloss(y[[name]], l.loose_lm$predict(m1[[name]])))
      loginfo("mse of lm (losing bids) at testing day %s on data %s is %f", day, name, mseloss(y.next[[name]], l.loose_lm$predict(m1.next[[name]])))
    }
    loginfo("the mean of the absolute difference between lm on win and loose at day %s is: %f", day, mean(abs(l.win_lm$r$par - l.loose_lm$r$par)))
  }
  y.observed <- y$all
  y.observed[!bidimpclk$is_win] <- bid$loose
#   { # clm with sigma
#     .start <- c((l.win_lm$r$par + l.loose_lm$r$par) / 2, log(sd(l.win_lm$predict(m1[["win"]]) - y[["win"]])))
#     l.clm <- censored_regression(m1$all, y.observed, bidimpclk$is_win, 1, .start)
#     for(name in c("all", "win", "loose")) {
#       loginfo("mse of clm with sigma at training day %s on data %s is %f", day, name, mseloss(y[[name]], l.clm$predict(m1[[name]])))
#       loginfo("mse of clm with sigma at testing day %s on data %s is %f", day, name, mseloss(y.next[[name]], l.clm$predict(m1.next[[name]])))
#     }
#   }
  { # clm without sigma
    .start <- l.win_lm$r$par
    l.clm2 <- censored_regression2(m1$all, y.observed, bidimpclk$is_win, sigma = sd(y$win), lambda2, .start)
    for(name in c("all", "win", "loose")) {
      loginfo("mse of clm without sigma at training day %s on data %s is %f", day, name, mseloss(y[[name]], l.clm2$predict(m1[[name]])))
      loginfo("mse of clm without sigma at testing day %s on data %s is %f", day, name, mseloss(y.next[[name]], l.clm2$predict(m1.next[[name]])))
    }
  }
  { # lm + clm with wr as weighted
    l.lm_clm2 <- function(l.lm, l.clm2) {
      function(m, wr) {
        wr * l.lm$predict(m) + (1 - wr) * l.clm2$predict(m)
      }
    }
    f <- l.lm_clm2(l.win_lm, l.clm2)
    for(name in c("all", "win", "loose")) {
      loginfo("mse of mixing lm and clm at training day %s on data %s is %f", day, name, mseloss(y[[name]], f(m1[[name]], wr[[name]])))
      loginfo("mse of mixing lm and clm at testing day %s on data %s is %f", day, name, mseloss(y.next[[name]], f(m1.next[[name]], wr.next[[name]])))
    }
  }
#   list(l.win_lm, l.loose_lm, l.clm, l.clm2)
  list(l.win_lm, l.loose_lm, l.clm2)
}

for(season in c("training2nd", "training3rd")) {
  for(i in head(seq_along(day.list[[season]]), -1)) {
    day <- day.list[[season]][i]
    loginfo("processing %s...", day)

    bidimpclk <- readRDS(sprintf("cache/bidimpclk.%s.sim2.Rds", format(day, "%Y%m%d")))
    apply_f <- apply_win_loose(bidimpclk)
    y <- apply_f(`[[`, "PayingPrice")
    wr <- apply_f(`[[`, "wr")
    bid <- apply_f(`[[`, "BiddingPrice") %>%
      lapply(`*`, 0.5)
    
    bidimpclk.next <- readRDS(sprintf("cache/bidimpclk.%s.sim2.Rds", format(day + 1, "%Y%m%d")))
    apply_f.next <- apply_win_loose(bidimpclk.next)
    y.next <- apply_f.next(`[[`, "PayingPrice")
    wr.next <- apply_f.next(`[[`, "wr")
    
    r1 <- do_exp(model1, "model with wr")
    saveRDS(r1, sprintf("cache/exp.%s.model1.Rds", day))
   # r2 <- do_exp(model2, "model interact with wr")
   # saveRDS(r2, sprintf("cache/exp.%s.model2.Rds", day))
  }
}
    
