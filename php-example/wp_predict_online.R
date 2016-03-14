#' Prepare the data of the experiments
library(methods)
 library(foreach,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(Matrix,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
 library(FeatureHashing,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(glmnet,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(dplyr,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
model <- ~ wr * (days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os +
  Osv + model + connectiontype + country + ua + carrier + js + user + carriername +
  split(app_cat,delim =",") + split(btype,delim =",") + split(mimes,delim =",") + split(badv,delim =",") + split(bcat,delim =","))


  apply_win_loose <- function(df) {
    df <- as.data.frame(df)
    function(f, ...) {
      f(df, ...)
    }
  }
  Args <- commandArgs(TRUE)
  # bidimpclk <- read.table(Args[6],header = TRUE, sep="\t")
  bidimpclk <- data.frame(exchange_id=Args[1],days=Args[2],hours=Args[3],country=Args[4],carrier=Args[5],user=Args[6],app_cat=Args[7],app_id=Args[8],publiser_id=Args[9],Osv=Args[10],ua=Args[11],model=Args[12],js=Args[13],os=Args[14],carriername=Args[15],connectiontype=Args[16],w=Args[17],h=Args[18],mimes=Args[19],bidfloor=Args[20],btype=Args[21],badv=Args[22],bcat=Args[23])

  formula <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
  split(mimes,delim =",") + split(badv,delim =",") +
  split(bcat,delim =",")

  predict.test <- hashed.model.matrix(formula, bidimpclk, 2^20)
  # load(cv.g.lr)
  cv.g.lr <- readRDS("wr_model_26.Rds")
  # win rate model
  wr <- predict(cv.g.lr, predict.test, s="lambda.min", type = "response")

  tmp <- cbind(bidimpclk,wr=c(wr))
  bidimpclk$wr <- tmp$wr

  apply_f <- apply_win_loose(bidimpclk)
  m <- apply_f(hashed.model.matrix, formula = model, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)

  l.lm <- readRDS("lm.26.Rds")
#lm.26model.Rds
  l.clm2 <- readRDS("clm.26.Rds")
#clm.26model.Rds
  # lm + clm with wr as weighted
  wpPre <- wr * l.lm$predict(m) + (1 - wr) * l.clm2$predict(m)
  sprintf("winning price is : %s", wpPre)
