install.packages(c("httr", "jsonlite", "dplyr",
                   "ggplot2", "wesanderson", "scales", "data.table"))
# Load packages
library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(wesanderson)
library(scales)
library(tidyverse)
library(data.table)

setwd("/Users/brianchung/Documents/LMU/")
path_data <- getwd()

file.edit("~/.Renviron")
readRenviron("~/.Renviron")
key <- Sys.getenv("youtube_key")

news <- 
read.csv(paste0(path_data,"/News_id.csv"), header = TRUE, sep = ",")


query_youtube_api <-
  function(base = "https://www.googleapis.com/youtube/v3/",
           sub_api = NULL,
           key = NULL,
           api_params = NULL) {
    api_call <- paste0(base, sub_api, "?", api_params)
    api_result <- GET(api_call)
    httr::stop_for_status(api_result)
    
    return(api_result)
  }

response_to_df <- function(api_result) {
  json_result <- httr::content(api_result, "text", encoding = "UTF-8")
  channel_json <- fromJSON(json_result, flatten = T)
  channel_df <- as.data.frame(channel_json)
  return(channel_df)
}

keywords <- c("Israel", "Gaza", "Palestine", "Palestinian", "Israeli", "Hamas", "IDF")
from <- "2023-10-07T00:00:00Z"
to   <- "2025-07-31T23:59:59Z"

iso8601_to_seconds <- function(duration) {
  # Example input: "PT1H2M30S"
  matches <- regmatches(duration, gregexpr("\\d+", duration))[[1]]
  hours <- minutes <- seconds <- 0
  
  if (grepl("H", duration)) hours <- as.numeric(matches[1])
  if (grepl("M", duration)) {
    if (grepl("H", duration)) minutes <- as.numeric(matches[2]) else minutes <- as.numeric(matches[1])
  }
  if (grepl("S", duration)) {
    if (grepl("H", duration) & grepl("M", duration)) seconds <- as.numeric(matches[3])
    else if (grepl("H", duration) | grepl("M", duration)) seconds <- as.numeric(matches[2])
    else seconds <- as.numeric(matches[1])
  }
  
  total_seconds <- hours * 3600 + minutes * 60 + seconds
  return(total_seconds)
}

get_video_durations <- function(video_ids, api_key) {
  all_durations <- tibble()
  for (chunk in split(video_ids, ceiling(seq_along(video_ids)/50))) {
    res <- GET("https://www.googleapis.com/youtube/v3/videos", query = list(
      part = "contentDetails",
      id = paste(chunk, collapse = ","),
      key = api_key
    ))
    stop_for_status(res)
    dat <- content(res, as = "parsed", encoding = "UTF-8")
    if (!"items" %in% names(dat)) next
    chunk_df <- map_dfr(dat$items, function(x) {
      tibble(
        videoId = x$id,
        duration = x$contentDetails$duration
      )
    })
    all_durations <- bind_rows(all_durations, chunk_df)
  }
  return(all_durations)
}

get_channel_videos <- function(uploads_id, 
                               api_key,
                               keywords,
                               from,
                               to) {
  
  base_url <- "https://www.googleapis.com/youtube/v3/playlistItems"
  all_items <- list()
  page_token <- NULL
  
  repeat {
    res <- GET(base_url, query = list(
      part = "snippet,contentDetails",
      playlistId = uploads_id,
      maxResults = 50,
      pageToken = page_token,
      key = api_key
    ))
    
    stop_for_status(res)
    dat <- content(res, as = "parsed", encoding = "UTF-8")
    
    if (!"items" %in% names(dat)) break
    
    all_items <- append(all_items, dat$items)
    
    # Convert publishedAt to POSIXct and check last video date
    last_date <- tail(sapply(dat$items, function(x) x$snippet$publishedAt), 1)
    last_date <- as.POSIXct(last_date, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC")
    
    if (last_date < as.POSIXct(from, tz="UTC")) {
      break  # Stop fetching, all remaining videos are older than "from"
    }
    
    page_token <- dat$nextPageToken
    if (is.null(page_token)) break
  }
  
  if (length(all_items) == 0) return(tibble())
  
  # Convert to data frame
  df <- map_dfr(all_items, function(x) {
    tibble(
      videoId = x$contentDetails$videoId,
      title = x$snippet$title,
      publishedAt = as.POSIXct(x$snippet$publishedAt, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC"),
      channelId = x$snippet$channelId
    )
  })
  
  # Filter by date
  if (!is.null(from)) df <- df %>% filter(publishedAt >= as.POSIXct(from, tz="UTC"))
  if (!is.null(to))   df <- df %>% filter(publishedAt <= as.POSIXct(to, tz="UTC"))
  
  # Filter by keywords
  if (!is.null(keywords)) {
    pattern <- paste(keywords, collapse = "|")
    df <- df %>% filter(grepl(pattern, title, ignore.case = TRUE))
  }
  
  df <- df %>% distinct(videoId, .keep_all = TRUE)
  
  return(df)
}

visegrad_v <- get_channel_videos("UUYQkkkVWJXlIAUZlLB-zjBA", api_key, keywords, from, to)
dw_v <- get_channel_videos("UUknLrEdhRCp1aegoMqRaCZg", api_key, keywords, from, to)
bbc_v <- get_channel_videos("UU16niRr50-MSBwiO3YDb3RA", api_key, keywords, from, to)
aljaz_v <- get_channel_videos("UUNye-wNBqNL5ZzHSJj3l8Bg", api_key, keywords, from, to)
richard_v <- get_channel_videos("UUB1u_wJThc3_e5J4VVj7hQQ", api_key, keywords, from, to)

write.csv(visegrad_v, "visegrad.csv", row.names=FALSE)
write.csv(dw_v, "dw.csv", row.names=FALSE)
write.csv(bbc_v, "bbc.csv", row.names=FALSE)
write.csv(aljaz_v, "aljaz.csv", row.names=FALSE)
write.csv(richard_v, "richard.csv", row.names=FALSE)


# Filter Al Jazeera (only those with duration longer than 10 minutes)

aljaz_v <- fread("aljaz.csv")
aljaz_s <- paste(c("shorts", "Shorts", "#", "Quotable", "Compare and Contrast", "By the Numbers", "Centre Stage"), collapse = "|")
aljaz_f <- aljaz_v[!grepl(aljaz_s, aljaz_v$title), ]

aljaz_d <- get_video_durations(aljaz_f$videoId, api_key)
aljaz_d <- aljaz_d %>%
  mutate(duration_seconds = sapply(duration, iso8601_to_seconds)) %>%
  select(-duration)

aljaz_f <- aljaz_f %>% left_join(aljaz_d, by = "videoId") %>%
  filter(duration_seconds < 600, duration_seconds > 180)
write.csv(aljaz_f, "aljaz_filtered.csv", row.names=FALSE)

# Filter BBC (Remove shorts)

bbc_v <- fread("bbc.csv")
bbc_f <- bbc_v[!grepl("#", bbc_v$title), ]
write.csv(bbc_f, "bbc_filtered.csv", row.names=FALSE)

# Filter Visegrad (Remove shorts)

visegrad_v <- fread("visegrad.csv")
visegrad_f <- visegrad_v[!grepl("#", visegrad_v$title), ]

visegrad_d <- get_video_durations(visegrad_f$videoId, api_key)
visegrad_d <- visegrad_d %>%
  mutate(duration_seconds = sapply(duration, iso8601_to_seconds)) %>%
  select(-duration)

visegrad_f <- visegrad_f %>% left_join(visegrad_d, by = "videoId") %>%
  filter(duration_seconds < 1800, duration_seconds > 60)
write.csv(visegrad_f, "visegrad_filtered.csv", row.names=FALSE)

# Filter Richard

richard_v <- fread("richard.csv")

richard_d <- get_video_durations(richard_v$videoId, api_key)
richard_d <- richard_d %>%
  mutate(duration_seconds = sapply(duration, iso8601_to_seconds)) %>%
  select(-duration)
richard_v <- richard_v %>% left_join(richard_d, by = "videoId") %>%
  filter(duration_seconds < 1800, duration_seconds > 60)
write.csv(richard_v, "richard_filtered.csv", row.names=FALSE)

# Filter DW

dw_v <- fread("dw.csv")

dw_d <- get_video_durations(dw_v$videoId, api_key)
dw_d <- dw_d %>%
  mutate(duration_seconds = sapply(duration, iso8601_to_seconds)) %>%
  select(-duration)
dw_v <- dw_v %>% left_join(dw_d, by = "videoId") %>%
  filter(duration_seconds < 1800, duration_seconds > 60)
write.csv(dw_v, "dw_filtered.csv", row.names=FALSE)

