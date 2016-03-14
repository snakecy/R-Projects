#' Prepare the data of the experiments

library(methods)
library(curl,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(foreach,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(Matrix,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(FeatureHashing,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(glmnet,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(dplyr,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(lubridate,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")
library(jsonlite,lib="/home/azureuser/R/x86_64-pc-linux-gnu-library/3.2")


Args <- commandArgs(TRUE)
request <- Args[1]
# wp_predict_api <- function(request){
json_req <- fromJSON(request)
json_par <- fromJSON(json_req$json)
# data.frame elements in json_req
days <- day(json_req$create_datetime)%%7
hours <- hour(json_req$create_datetime)
exchange_id <- json_req$exchange_id
# data.frame elements in json_par
app_id <- if(is.null(json_par$app$id)){'0'}else{json_par$app$id}
publiser_id <- if(is.null(json_par$app$publisher$id)){'null'}else{json_par$app$publisher$id}
bidfloor <- if(is.null(json_par$imp$bidfloor)){'0'}else{json_par$imp$bidfloor}
w <- if(is.null(json_par$imp$banner$w)){'0'}else{json_par$imp$banner$w}
h <- if(is.null(json_par$imp$banner$h)){'0'}else{json_par$imp$banner$h}
os <- if(tolower(json_par$device$os) == "android"){'1'}else if(tolower(json_par$device$os) == "ios"){'2'} else{'0'}
os_ver <- if(is.null(json_par$device$osv)){'0'}else{json_par$device$osv}
model <- if(is.null(json_par$device$model)){'null'}else{json_par$device$model}
connectiontype <- if(is.null(json_par$device$connectiontype)){'0'}else(json_par$device$connectiontype)
country <- json_par$device$geo$country
carrier <- if(is.null(json_par$device$geo$carrier)){'null'}else{json_par$device$geo$carrier}
js <- if(is.null(json_par$device$js)){'0'}else{json_par$device$js}
user <- if(is.null(json_par$user)){'0'}else{'1'}
carriername <- if(is.null(json_par$ext$carriername)){'-'}else{json_par$ext$carriername}
app_cat <- paste(if(is.null(json_par$app$cat)){'null'}else{json_par$app$cat},collapse=",")
btype <- paste(if(is.null(json_par$imp$banner$btype)){'null'}else{json_par$imp$banner$btype},collapse = ",")
mimes <- paste(if(is.null(json_par$imp$banner$mimes)){'null'}else{json_par$imp$banner$mimes[[1]]},collapse = ",")
badv <-  paste(if(is.null(json_par$badv)){'null'}else{json_par$badv},collapse = ",")
bcat <-  paste(if(is.null(json_par$bcat)){'null'}else{json_par$bcat},collapse = ",")

operators <- c('windows', 'ios', 'mac', 'android', 'linux')
browsers <- c('chrome', 'sogou', 'maxthon', 'safari', 'firefox', 'theworld', 'opera', 'ie')
operation <- 'other'
browser <- 'other'
regularForm <-   if(!is.null(json_par$device$ua)){
  for(i in 1:length(operators)){
    if(grepl(operators[i],json_par$device$ua)){
      operation <- operators[i]
      break
    }
  }
  for (i in 1:length(browsers)){
    if(grepl(browsers[i],json_par$device$ua)){
      browser <- browsers[i]
      break
    }
  }
  paste(operation,browser,sep="_")
  }else{
    'null'
  }


  bidimpclk <- data.frame(days=days,hours=hours,exchange_id=exchange_id,app_id=app_id,publiser_id=publiser_id,bidfloor=bidfloor,w=w,h=h,os=os,Osv=os_ver,model=model,connectiontype=connectiontype,country=country,ua=regularForm,carrier=carrier,js=js,user=user,carriername=carriername,app_cat=app_cat,btype=btype,mimes=mimes,badv=badv,bcat=bcat)

  model <- ~ wr * (days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os +
    Osv + model + connectiontype + country + ua + carrier + js + user + carriername +
    split(app_cat,delim =",") + split(btype,delim =",") + split(mimes,delim =",") + split(badv,delim =",") + split(bcat,delim =","))


    apply_win_loose <- function(df) {
      df <- as.data.frame(df)
      function(f, ...) {
        f(df, ...)
      }
    }
    formula <- ~ days + hours + exchange_id + app_id + publiser_id + bidfloor + w + h + os + Osv + model + connectiontype + country + ua + carrier + js + user + carriername + split(app_cat,delim =",") + split(btype,delim =",") +
    split(mimes,delim =",") + split(badv,delim =",") +
    split(bcat,delim =",")

    predict.test <- hashed.model.matrix(formula, bidimpclk, 2^20)
    # load(cv.g.lr)
    # cv.g.lr <- readRDS("wr.rda")
    load("wr.rda")
    # win rate model
    wr <- predict(cv.g.lr, predict.test, s="lambda.min", type = "response")
    tmp <- cbind(bidimpclk,wr=c(wr))
    bidimpclk$wr <- tmp$wr

    apply_f <- apply_win_loose(bidimpclk)
    m <- apply_f(hashed.model.matrix, formula = model, hash.size = 2^20, transpose = TRUE, is.dgCMatrix = FALSE)

    # l.lm <- readRDS("lm.rda")
    #lm.26model.Rds
    # l.clm2 <- readRDS("clm.rda")
    #clm.26model.Rds
    load("lm.rda")
    load("clm.rda")
    # lm + clm with wr as weighted
    wpPre <- wr * l.win_lm$predict(m) + (1 - wr) * l.clm2$predict(m)
    sprintf("winning price is : %s", wpPre)
    # }

