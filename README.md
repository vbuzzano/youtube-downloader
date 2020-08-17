# youtube-downloader

## Dependencies

- youtube-dl  
- ffmpeg   
- rename  


### Install youtube-cl
http://ytdl-org.github.io/youtube-dl/download.html

### Install ffmpeg on ubuntu

<code>
	sudo apt install ffmpeg
</code>

### Install rename on ubuntu

<code>
	sudo apt install rename
</code>


# config file

DOWNLOAD_SPEED_LIMIT="10M"  
DEST_DIR="/tmp/Youtube"  
DOWNLOAD_ARCHIVE="$DEST_DIR/downloaded.txt"  
BATCH_FILE="$DEST_DIR/channel_list.txt"  
COOKIES_FILE="$DEST_DIR/google_cookies.txt"  
LOG_FILE="$DEST_DIR/youtube-downloader.log"  
CACHE_DIR="$DEST_DIR/cache"

DEFAULT_DATEAFTER=$(date +"%Y0101")  
DEFAULT_SUBTITLELANG=""  
DEFAULT_SUBTITLEFORMAT="srt"  
DEFAULT_FORMAT="bestvideo[ext=?mp4][height<=?720]+bestaudio[ext=?mp3]/best"  
DEFAULT_MAXFILESIZE="2048m"  
DEFAULT_SLEEP_INTERVAL=30  
DEFAULT_MAXSLEEP_INTERVAL=60  



### Usage

<code>
	youtube-dowloader config.cfg
</code>
