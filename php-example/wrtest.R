#' Prepare the data of the experiments
#'
#' Loading required library

library(methods)
 library(foreach,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(Matrix,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
 library(FeatureHashing,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(glmnet,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
  Args <- commandArgs(TRUE)
  # bidtmp <- Args[1]
  # sprintf(bidtmp)
  bidimp <- data.frame(exchange_id=Args[1],days=Args[2],hours=Args[3],country=Args[4],carrier=Args[5],user=Args[6],app_cat=Args[7],app_id=Args[8],publiser_id=Args[9],Osv=Args[10],ua=Args[11],model=Args[12],js=Args[13],os=Args[14],carriername=Args[15],connectiontype=Args[16],w=Args[17],h=Args[18],mimes=Args[19],bidfloor=Args[20],btype=Args[21],badv=Args[22],bcat=Args[23])

  f <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
  split(mimes,delim =",") + split(badv,delim =",") +
  split(bcat,delim =",")

  m.test <- hashed.model.matrix(f, bidimp, 2^20)

  cv.g.lr <- readRDS("wr_model_26.Rds")
  p.lr <- predict(cv.g.lr, m.test, s="lambda.min", type = "response")
  sprintf("Win rate is : %s", p.lr)
