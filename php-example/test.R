#' Prepare the data of the experiments
#'
#' Loading required library

  # library(methods)
  # library(FeatureHashing)
  # library(glmnet)
  library(methods)
   library(foreach,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
  library(Matrix,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
   library(FeatureHashing,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
  library(glmnet,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")

  # Args <- commandArgs()
  bidimp <- read.table("/usr/share/nginx/html/pred.txt",sep = "\t", header = TRUE)
  # bidimp <- read.table(Args[6],sep = "\t", header = TRUE)

  f <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
  split(mimes,delim =",") + split(badv,delim =",") +
  split(bcat,delim =",")

  m.test <- hashed.model.matrix(f, bidimp, 2^20)

  cv.g.lr <- readRDS("/usr/share/nginx/html/wr_model_26.Rds")
  p.lr <- predict(cv.g.lr, m.test, s="lambda.min", type = "response")
  sprintf("Win rate is : %s", p.lr)
