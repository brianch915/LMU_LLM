install.packages(c("httr", "jsonlite", "dplyr",
                   "ggplot2", "wesanderson", "scales"))
# Load packages
library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(wesanderson)
library(scales)

setwd("/Users/brianchung/Documents/LMU/")
path_data <- getwd()

file.edit("~/.Renviron")
readRenviron("~/.Renviron")
key <- Sys.getenv("youtube_key")

