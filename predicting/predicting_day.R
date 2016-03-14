#' Prepare the data of the experiments
#' Loading required library
library(methods)
library(FeatureHashing)
library(glmnet)

loginfo <- function(fmt, ...) {
  cat(sprintf("(%s) ", Sys.time()))
  cat(sprintf(fmt, ...))
  cat("\n")
}

Args <- commandArgs()
bidimpclk <- read.table(Args[6],sep = "\t", header = TRUE)
model <- ~ wr * (days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") + split(mimes,delim =",") + split(badv,delim =",") + split(bcat,delim =","))

apply_win_loose <- function(df) {
  df <- as.data.frame(df)
  function(f, ...) {
    f(df, ...)
  }
}

formula <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") + split(mimes,delim =",") + split(badv,delim =",") + split(bcat,delim =",")

predict.test <- hashed.model.matrix(formula, bidimpclk, 2^20)
# load(cv.g.lr)
cv.g.lr <- readRDS(Args[7])
# load("wr.rda")
# win rate model
wr <- predict(cv.g.lr, predict.test, s="lambda.min", type = "response")
loginfo("win rate is : %s", wr)
tmp <- cbind(bidimpclk,wr=c(wr))
bidimpclk$wr <- tmp$wr

apply_f <- apply_win_loose(bidimpclk)
m <- apply_f(hashed.model.matrix, formula = model, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)

l.lm <- readRDS(Args[8])
# load(Args[8])
#lm.26model.Rds
l.clm2 <- readRDS(Args[9])
# load(Args[9])
#clm.26model.Rds
# lm + clm with wr as weighted
wpre <- wr * l.win_lm$predict(m) + (1 - wr) * l.clm2$predict(m)
sprintf("winning price is : %s", wpre)
