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

german_parties <-
read.csv(paste0(path_data,"/german_parties_id.csv"), header = TRUE, sep = ";")

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

parties <- as.list(german_parties$channel_id)

german_party_channels_stats <- data.frame()

for (i in 1:length(parties)) {
  # Get party
  party <- parties[[i]]
  # Define parameters
  params <- paste(
    paste0("key=", key),
    paste0("id=", party),
    "part=statistics",
    "fields=items(id),items(statistics)",
    sep = "&"
  )
  
  # Use query_youtube_api()
  api_resp <-
    query_youtube_api(sub_api = "channels",
                      key = key,
                      api_params = params)
  
  # Use response_to_df()
  resp_df <- response_to_df(api_resp)
  
  # Rename columns
  resp_df <- resp_df %>%
    mutate(
      channel_id = items.id,
      views = as.numeric(items.statistics.viewCount),
      videos = as.numeric(items.statistics.videoCount),
      subscriber = as.numeric(items.statistics.subscriberCount),
      average_views_per_video = views / videos
    ) %>%
    select(channel_id,
           views,
           videos,
           subscriber,
           average_views_per_video)
  
  # Add to df
  german_party_channels_stats <- rbind(german_party_channels_stats, resp_df)
}

german_party_channels_stats <- german_party_channels_stats %>%
  left_join(german_parties, by = c("channel_id"))

ggplot(german_party_channels_stats, aes(
  x = reorder(party_name,-average_views_per_video),
  y = average_views_per_video,
  fill = party_name
)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Average Views per Video by Political Party",
       x = "Channel ID",
       y = "Average Views per Video",
       fill = "Party Name") +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "Mio")) +
  scale_fill_manual(values = wes_palette("Moonrise3", 7, type = "continuous")) +
  theme(
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold")
  )


for (i in 1:nrow(german_parties)) {
  print(german_parties[i, "party_name"])
  api_params <-
    paste(
      paste0("key=", key),
      paste0("id=", german_parties[i, "channel_id"]),
      "part=contentDetails",
      "fields=items/contentDetails/relatedPlaylists/uploads",
      sep = "&"
    )
  api_result <- query_youtube_api(sub_api = "channels",
                                  key = key,
                                  api_params = api_params)
  videos_in_channel <- response_to_df(api_result)
  upload_playlist_id <- videos_in_channel$contentDetails.relatedPlaylists.uploads
  print(upload_playlist_id)
}

all_videos <- data.frame()
for (i in 1:nrow(german_parties)) {
  # Get playlist ID of party
  upload_playlist_id = german_parties[i, "uploads_id"]
  # Get all video id’s for all videos in a Playlist
  api_params <- paste(
    paste0("key=", key),
    "maxResults=50",
    paste0("playlistId=", upload_playlist_id),
    "part=snippet,contentDetails",
    "fields=nextPageToken,items(contentDetails(videoId)),items(snippet(title,description,publishedAt,channelId))",
    sep = "&"
  )
  # Query API
  api_result <- query_youtube_api(sub_api = "playlistItems",
                                  key = key,
                                  api_params = api_params)
  # Convert to df
  upload_videos <- response_to_df(api_result)
  # Add party name
  upload_videos$party_name <- german_parties[i, "party_name"]
  # Add df to all_videos
  all_videos <- rbind(all_videos, upload_videos)
}