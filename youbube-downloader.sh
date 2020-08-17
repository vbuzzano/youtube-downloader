#!/bin/sh

DOWNLOAD_SPEED_LIMIT=20M
DEST_DIR=/media/rdc-nas/video/Youtube
DOWNLOAD_ARCHIVE=$DEST_DIR/downloaded.txt
BATCH_FILE=$DEST_DIR/channel_list.txt
COOKIES_FILE=$DEST_DIR/google_cookies.txt
LOG_FILE=$DEST_DIR/downloaded.log
CACHE_DIR=$DEST_DIR/cache

DEFAULT_DATEAFTER=$(date +"%Y0101")
DEFAULT_SUBTITLELANG=""
DEFAULT_SUBTITLEFORMAT="srt"
DEFAULT_FORMAT="bestvideo[ext=?mp4][height<=?720]+bestaudio[ext=?mp3]/best"
DEFAULT_MAXFILESIZE="2048m"

TMP_DIR=/tmp/youtube-downloader
CURRENT_DIR=`pwd`

# assure download archive exists
touch $DOWNLOAD_ARCHIVE

# init cache dir
mkdir -p $CACHE_DIR


_append_past_videos_to_downloaded_archive() {
  # $1 = channel url
  # $2 = dateafter
  # $3 = cache download archive filename
  local url=$1
  local date_after=$2
  local file_cache=$3
  youtube-dl --playlist-reverse \
    --ignore-errors \
    --simulate \
    --datebefore "$date_after" \
    --no-cache-dir \
    --cookies "$COOKIES_FILE" \
    --youtube-skip-dash-manifest \
    --get-id \
    $URL | tee $file_cache
    sed -i -E "s/(.*)/youtube \1/" $file_cache
    cat $file_cache >> $DOWNLOAD_ARCHIVE && sed -i '/^$/d' $DOWNLOAD_ARCHIVE
}

_print() {
  echo "$@" >$LOG_FILE 2>&1
}

_download_videos() {
  # $1 = channel url
  # $2 = channel unique key
  # $3 = date_after
  # $4 = format
  # $5 = max file size
  # $6 = subtitle lang
  # $7 = subtitle format
  local url=$1
  local key=$2
  local date_after=$3
  local format=$4
  local max_filesize=$5
  local sub_lang=$6
  local sub_format=$7

  rm -rf $TMP_DIR/$key
  mkdir -p $TMP_DIR/$key/downloads
  cd  $TMP_DIR/$key
  cp $DOWNLOAD_ARCHIVE ./downloaded.txt
  cd downloads

  local youtube_dl_cmd=""
  read -d '' youtube_dl_cmd << EOF
  youtube-dl --playlist-reverse
    --download-archive ../downloaded.txt
    --ignore-errors
    --max-filesize "$max_filesize"
    --limit-rate "$DOWNLOAD_SPEED_LIMIT"
    --format "$format"
    --dateafter "$date_after"
    --youtube-skip-dash-manifest
    --autonumber-start 0001
    --no-cache-dir
    --cookies "$COOKIES_FILE"
    --add-metadata
    --write-thumbnail
    --write-description
EOF

  if [ ! -z "sdfsf" ]; then 
    youtube_dl_cmd="$youtube_dl_cmd --write-sub --write-auto-sub --sub-lang \"$sub_lang\" --sub-format \"$sub_format\" --convert-subs \"$sub_format\""
  fi

  read -d '' youtube_dl_cmd << EOF
  $youtube_dl_cmd
    -o "%(uploader)s/%(uploader)s - S$(date +"%Y")/%(playlist_index)s. %(title)s %(upload_date)s/%(uploader)s - S$(date +"%Y")E%(playlist_index)s - %(upload_date)s - %(title)s --end.%(ext)s" \
    $url 
EOF

  # execute youtube-dl
  eval $youtube_dl_cmd >$LOG_FILE 2>&1

  local count=$(find . -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [ $count -gt 0 ]; then
    rename 's/(.*) - (\d{4})(\d{2})(\d{2}) - (.*) --end\.(.*)/$1 - $2-$3-$4 - $5.$6/' **/**/**/*.* && \
    _print "Copy downloaded videos to $DEST_DIR" && \
    cp -rfn * $DEST_DIR && \
    cd .. && \
    _print "Append downloaded archive to $DOWNLOAD_ARCHIVE and remove empty lines" && \
    grep -Fxvf $DOWNLOAD_ARCHIVE ./downloaded.txt >> $DOWNLOAD_ARCHIVE && sed -i '/^$/d' $DOWNLOAD_ARCHIVE
  fi
  cd $CURRENT_DIR && \
  rm -rf $TMP_DIR/$key
}

_execute() {
  # Loop batch file
  awk '!/^(#|;|\])/'  $BATCH_FILE |
  while IFS= read -r channel; do

    _print ""
    _print "Prepare to download videos for $channel ..."

    # read channel infos
    IFS='|' read -ra channel_args <<< "$channel"
    local c_url=${channel_args[0]}
    local c_dateafter=${channel_args[1]}
    local c_format=${channel_args[2]}
    local c_maxfilesize=${channel_args[3]}
    local c_subtitlelang=${channel_args[4]}
    local c_subtitleformat=${channel_args[5]}

    # check that c_url is not empty
    if [ "$c_url" == "" ]; then 
      echo "ERROR: channel url is required for channel $channel"
      exit 1
    fi

    # check channel infos value and set default values if needed
    if [ "$c_dateafter" == "default" ] || [ "$c_dateafter" == "" ]; then c_dateafter=$DEFAULT_DATEAFTER; fi
    if [ "$c_format" == "default" ] || [ "$c_format" == "" ]; then c_format=$DEFAULT_FORMAT; fi
    if [ "$c_maxfilesize" == "default" ] || [ "$c_maxfilesize" == "" ]; then c_maxfilesize=$DEFAULT_MAXFILESIZE; fi
    if [ "$c_subtitlelang" == "default" ] || [ "$c_subtitlelang" == "" ]; then c_subtitlelang=$DEFAULT_SUBTITLELANG; fi
    if [ "$c_subtitleformat" == "default" ] || [ "$c_subtitleformat" == "" ]; then c_subtitleformat=$DEFAULT_SUBTITLEFORMAT; fi

    # create unique channel key
    local c_key=$(echo -n "$c_url" | md5sum | cut -d' ' -f1)

    # check if we need to add old videos to downloaded archive
    local past_downloaded_filename="$CACHE_DIR/$KEY.txt"
    if [ ! -f "$past_downloaded_filename" ]; then
        _print
        _print "Add past videos id to download archive for $c_url to file $past_downloaded_filename ..."
        _append_past_videos_to_downloaded_archive $c_url $c_dateafter $past_downloaded_filename
    fi

    _print
    _print "Download new videos files for $c_url"
    
    _download_videos $c_url
    
    _print
    _print "done."
  done
}

_execute
