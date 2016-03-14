.onLoad <- function(lib, pkg){
  #automatically loads the dataset when package is loaded
  #do not use this in combination with lazydata=true
  utils::data(wr,lm,clm, package = pkg, envir = parent.env(environment()))
  library(methods)
  library(foreach)
  library(Matrix)
  library(FeatureHashing)
  library(glmnet)
  library(jsonlite)
  library(lubridate)
  library(dplyr)
}
