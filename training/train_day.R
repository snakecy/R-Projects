# load library
library(methods)
library(dplyr)
library(FeatureHashing)
library(glmnet)

loginfo <- function(fmt, ...) {
  cat(sprintf("(%s) ", Sys.time()))
  cat(sprintf(fmt, ...))
  cat("\n")
}


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
    (m %*% dzdl) / sigma + c(0, tail(w, -1))
  }
  r.w <- optim(start, f.w, g.w, method = "L-BFGS-B", control = list(maxit = ifelse(interactive(), 100, 20000), trace = ifelse(interactive(), 1, 0)))
  list(predict = function(m) r.w$par %*% m, r = r.w)
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

do_exp <- function (model1, model_name) {
  #   browser()
  loginfo("processing exp with model:%s", model_name)
  m1 <- apply_f(hashed.model.matrix, formula = model1, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)
  m1.next <- apply_f.next(hashed.model.matrix, formula = model1, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)
  for(name in c("all", "win", "loose")) {
    loginfo("mse of averaged observed y at training on data %s is %f", name, mseloss(y[[name]], mean(y$win)))
    loginfo("mse of averaged observed y at testing on data %s is %f", name, mseloss(y.next[[name]], mean(y$win)))
  }
  { # lm on win
    .start <- rep(0, nrow(m1$win));.start[1] <- mean(y$win)
    progressive.cv <- list()
    for(lambda2 in c(1000, 2000)) {
      l.win_lm <- linear_regression(m1$win, y$win, lambda2, start = .start)
      loginfo("lambda2: %d", lambda2)
      for(name in c("all", "win", "loose")) {
        loginfo("mse of lm (winning bids) at training on data %s is %f", name, mseloss(y[[name]], l.win_lm$predict(m1[[name]])))
        loginfo("mse of lm (winning bids) at testing on data %s is %f", name, mseloss(y.next[[name]], l.win_lm$predict(m1.next[[name]])))

        lm.pre <- l.win_lm$predict(m1[[name]])
        loginfo("average winning price of lm (winning bids) at training on data %s is %f", name, sum(lm.pre)/length(lm.pre))
        lm.prenext <- l.win_lm$predict(m1.next[[name]])
        loginfo("average winning price of lm (winning bids) at testing on data %s is %f", name, sum(lm.prenext)/length(lm.prenext))
        linStaAUC <- data.frame(payp=c(y[[name]]), wp = c(l.win_lm$predict(m1[[name]])))
        linwinNum <- with(linStaAUC,linStaAUC[payp < wp, ])
        loginfo("accuracy winning price of lm (winning bids) at training on data %s is %f", name, nrow(linwinNum)/nrow(linStaAUC))
      }
      progressive.cv[[paste(lambda2)]] <- mseloss(y.next[["all"]], l.win_lm$predict(m1.next[["all"]]))
    }
    lambda2 <- unlist(progressive.cv) %>% which.min %>% names %>% as.numeric
    loginfo("lambda2: %d", lambda2)
    l.win_lm <- linear_regression(m1$win, y$win, lambda2, start = .start)
    #      save(l.win_lm, file=Args[8])
    saveRDS(l.win_lm,sprintf(Args[8]))
    # saveRDS(l.win_lm,sprintf("lm.26model.Rds"))
  }
  { # lm on loose
    .start <- l.win_lm$r$par
    l.loose_lm <- linear_regression(m1$loose, y$loose, lambda2 = lambda2, start = .start)
    for(name in c("all", "win", "loose")) {
      loginfo("mse of lm (losing bids) at training on data %s is %f",name, mseloss(y[[name]], l.loose_lm$predict(m1[[name]])))
      loginfo("mse of lm (losing bids) at testing on data %s is %f", name, mseloss(y.next[[name]], l.loose_lm$predict(m1.next[[name]])))
    }

    loginfo("the mean of the absolute difference between lm on win and loose is: %f", mean(abs(l.win_lm$r$par - l.loose_lm$r$par)))
  }
  y.observed <- y$all
  y.observed[!bidimpclk$is_win] <- bid$loose
  { # clm without sigma
    .start <- l.win_lm$r$par
    l.clm2 <- censored_regression2(m1$all, y.observed, bidimpclk$is_win, sigma = sd(y$win), lambda2, .start)
    #      saveRDS(l.clm2,sprintf("clm.26model.Rds"))
    saveRDS(l.clm2,sprintf(Args[9]))
    #      save(l.clm2, file =Args[9])
    for(name in c("all", "win", "loose")) {
      loginfo("mse of clm with sigma at training on data %s is %f", name, mseloss(y[[name]], l.clm2$predict(m1[[name]])))
      loginfo("mse of clm with sigma at testing on data %s is %f", name, mseloss(y.next[[name]], l.clm2$predict(m1.next[[name]])))
      clm.pre <- l.clm2$predict(m1[[name]])
      loginfo("average winning price of clm with sigma at training on data %s is %f", name, sum(clm.pre)/length(clm.pre))
      clm.prenext <- l.clm2$predict(m1.next[[name]])
      loginfo("average winning price of clm with sigma at testing on data %s is %f", name, sum(clm.prenext)/length(clm.prenext))
      cenStaAUC <- data.frame(payp=c(y[[name]]), wp = c(l.clm2$predict(m1[[name]])))
      cenwinNum <- with(cenStaAUC,cenStaAUC[payp < wp, ])
      loginfo("accuracy winning price of clm with sigma at training on data %s is %f", name, nrow(cenwinNum)/nrow(cenStaAUC))
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
      loginfo("mse of mixing lm and clm at training on data %s is %f", name, mseloss(y[[name]], f(m1[[name]], wr[[name]])))
      loginfo("mse of mixing lm and clm at testing on data %s is %f", name, mseloss(y.next[[name]], f(m1.next[[name]], wr.next[[name]])))
      mix.pre <- f(m1[[name]], wr[[name]])
      loginfo("average winning price of mixing lm and clm with sigma at training on data %s is %f", name, sum(mix.pre)/length(mix.pre))
      mix.prenext <- f(m1.next[[name]], wr.next[[name]])
      loginfo("average winning price of mixing lm and clm with sigma at testing on data %s is %f", name, sum(mix.prenext)/length(mix.prenext))
      StaAUC <- data.frame(payp=c(y[[name]]), wp = c(f(m1.next[[name]], wr.next[[name]])))
      winNum <- with(StaAUC,StaAUC[payp < wp, ])
      loginfo("accuracy winning price of mixing lm and clm with sigma at training on data %s is %f", name, nrow(winNum)/nrow(StaAUC))
    }
  }
  #   list(l.win_lm, l.loose_lm, l.clm, l.clm2)
  list(l.win_lm, l.loose_lm, l.clm2)
}

Args <- commandArgs()
# bidimpclk <- read.table("newbid.2015-09-10.txt",header=TRUE,sep = "\t")
bidimpclk <- read.table(Args[6],header=TRUE,sep = "\t")
model1 <- ~ wr * (days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os +
  Osv + model + connectiontype + country + ua + carrier + js + user + carriername +
  split(app_cat,delim =",") + split(btype,delim =",") + split(mimes,delim =",") + split(badv,delim =",") + split(bcat,delim =","))

  formula <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
  split(mimes,delim =",") + split(badv,delim =",") +
  split(bcat,delim =",")

  m.train <- hashed.model.matrix(formula, bidimpclk, 2^20)
  m.test <- m.train

  cv.g.lr <- cv.glmnet(m.train, bidimpclk$is_win, family = "binomial")#, type.measure = "auc")
  saveRDS(cv.g.lr, sprintf(Args[7]))
  p.lr <- predict(cv.g.lr, m.test, s="lambda.min", type = "response")
  sprintf("************** win rate statistic************************")
  AcuWin <- auc(bidimpclk$is_win, p.lr)
  AveWr <- sum(p.lr)/nrow(p.lr)
  loginfo("Average Win rate is : %s", AveWr)
  loginfo("Accuracy win rate is : %s", AcuWin)

  tmp <- cbind(bidimpclk,wr=c(p.lr))
  bidimpclk$wr <- tmp$wr
  apply_f <- apply_win_loose(bidimpclk)
  wr <- apply_f(`[[`, "wr")
  y <- apply_f(`[[`, "payingprice")
  bid <- apply_f(`[[`, "bid_price") %>% lapply(`*`, 0.5)
  #lapply(bid, `*`, 0.5)

  # bidimpclk.next <-  read.table("newbid.2015-09-10.txt", header=TRUE,sep="\t")
  bidimpclk.next <- bidimpclk
  # predict.next <- hashed.model.matrix(formula, bidimpclk.next, 2^20)
  # p.lrnext <- predict(cv.g.lr, predict.next, s="lambda.min", type = "response")
  p.lrnext <- p.lr
  tmp.next <- cbind(bidimpclk.next,wr=c(p.lrnext))
  bidimpclk.next$wr <- tmp.next$wr
  apply_f.next <- apply_win_loose(bidimpclk.next)
  y.next <- apply_f.next(`[[`, "payingprice")
  wr.next <- apply_f.next(`[[`, "wr")
  sprintf("****** do simulation of winning price statistic*********")
  r1 <- do_exp(model1, "model with wr")
  sprintf("****************** finish statistic ********************")
