#' Prepare the data of the experiments
#'
#' Loading required library
# library(methods)
# library(data.table)
library(dplyr)
library(FeatureHashing)
library(glmnet)

model <- ~ wr * (days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os +
  Osv + model + connectiontype + country + ua + carrier + js + user + carriername +
  split(app_cat,delim =",") + split(btype,delim =",") + split(mimes,delim =",") + split(badv,delim =",") + split(bcat,delim =","))

  mseloss <- function(y, y.hat) {
    mean((y - y.hat)^2)
  }

  apply_win_loose <- function(df) {
    df <- as.data.frame(df)
    function(f, ...) {
      f(df, ...)
    }
  }
  Args <- commandArgs()
  bidimpclk <- read.table(Args[6],header = TRUE, sep="\t")

  formula <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
  split(mimes,delim =",") + split(badv,delim =",") +
  split(bcat,delim =",")

  predict.test <- hashed.model.matrix(formula, bidimpclk, 2^20)
  # load(cv.g.lr)
  cv.g.lr <- readRDS(Args[7])
  # win rate model
  wr <- predict(cv.g.lr, predict.test, s="lambda.min", type = "response")

  sprintf("************** win rate statistic************************")
  AcuWin <- auc(bidimpclk$is_win, p.lr)
  AveWr <- sum(p.lr)/nrow(p.lr)
  loginfo("Average Win rate is : %s", AveWr)
  loginfo("Accuracy win rate is : %s", AcuWin)



  tmp <- cbind(bidimpclk,wr=c(wr))
  bidimpclk$wr <- tmp$wr

  apply_f <- apply_win_loose(bidimpclk)
  m <- apply_f(hashed.model.matrix, formula = model, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)

  l.lm <- readRDS(Args[8])
#lm.26model.Rds
  l.clm2 <- readRDS(Args[9])
#clm.26model.Rds

# for linear part
  linPre <- l.lm$predict(m)
  linAvewp <- sum(linPre)/nrow(linPre)
  sprintf("Linear average winning price is : %s", linAvewp)
  linStaAUC <- data.frame(payp=c(bidimpclk$payingprice), wp = c(linPre))
  linwinNum <- with(linStaAUC,linStaAUC[payp < wp, ])
  linAcuWin <- nrow(linwinNum)/nrow(linStaAUC)
  sprintf("Accuracy using winning price : %s", linAcuWin)

  # for censored part
  cenPre <- l.clm2$predict(m)
  cenAvewp <- sum(cenPre)/nrow(cenPre)
  sprintf("Censored average winning price is : %s", cenAvewp)
  cenStaAUC <- data.frame(payp=c(bidimpclk$payingprice), wp = c(cenPre))
  cenwinNum <- with(cenStaAUC,cenStaAUC[payp < wp, ])
  cenAcuWin <- nrow(cenwinNum)/nrow(cenStaAUC)
  sprintf("Accuracy using winning price : %s", cenAcuWin)

  # lm + clm with wr as weighted
  resultPredict <- wr * l.lm$predict(m) + (1 - wr) * l.clm2$predict(m)
  # png(Args[10])
#  png(file="wp_dis26.png")
  # plot(resultPredict)
  # dev.off()
  Avewp <- sum(resultPredict)/nrow(resultPredict)
  sprintf("Average winning price is : %s", Avewp)

  StaAUC <- data.frame(payp=c(bidimpclk$payingprice), wp = c(resultPredict))
  winNum <- with(StaAUC,StaAUC[payp < wp, ])
  AcuWin <- nrow(winNum)/nrow(StaAUC)
  sprintf("Accuracy using winning price : %s", AcuWin)

#  saveRDS(resultPredict, sprintf("result.predict.Rds"))
