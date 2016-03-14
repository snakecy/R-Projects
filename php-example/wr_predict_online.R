#' Prepare the data of the experiments
#'
#' Loading required library

library(methods)
 library(foreach,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(Matrix,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
 library(FeatureHashing,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(glmnet,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")

  Args <- commandArgs(TRUE)
  bidtmp <- Args[1]
  bidimp <- cbind(days=bidtmp["days"],hours=bidtmp["hours"],exchange_id=bidtmp["exchange_id"],app_id=bidtmp["app_id"],publiser_id=bidtmp["publiser_id"],bidfloor=bidtmp["bid_floor"],w=bidtmp["ad_width"],h=bidtmp["ad_height"],os=bidtmp["os"],Osv=bidtmp["os_ver"],model=bidtmp["model"],connectiontype=bidtmp["conn_type"],country=bidtmp["country"],ua=bidtmp["ua"],carrier=bidtmp["carrier"],js=bidtmp["js"],user=bidtmp["user"],carriername=bidtmp["carrier_name"],app_cat=bidtmp["app_cat"],btype=bidtmp["btype"],mimes=bidtmp["mimes"],badv=bidtmp["badv"],bcat=bidtmp["bcat"])


  f <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
  split(mimes,delim =",") + split(badv,delim =",") +
  split(bcat,delim =",")

  m.test <- hashed.model.matrix(f, bidimp, 2^20)

  cv.g.lr <- readRDS("wr_model_26.Rds")
  p.lr <- predict(cv.g.lr, m.test, s="lambda.min", type = "response")
  sprintf("Win rate is : %s", p.lr)
