from youtube_transcript_api import YouTubeTranscriptApi

import re


video_id = "2ZiKJ4TeRx4"

ytt_api = YouTubeTranscriptApi()
ytt_api.fetch(video_id)

def get_video_id(url):
    video_id = re.search(r'(?:v=|/)([0-9A-Za-z_-]{11}).*', url)
    return video_id.group(1) if video_id else None

def get_transcript(url):
    try:
        video_id = get_video_id(url)
        transcript = YouTubeTranscriptApi.get_transcript(video_id)
        return transcript
    except Exception as e:
        return str(e)

# API key : AIzaSyCXUpzg0gVYKDiBjhTIIRZDpBmz2afen1E

# video : https://www.youtube.com/watch?v=2ZiKJ4TeRx4