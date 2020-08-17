#!/bin/sh

DEST_DIR=/media/rdc-nas/video/Youtube
DOWNLOAD_ARCHIVE=$DEST_DIR/downloaded.txt
BATCH_FILE=$DEST_DIR/channel_list.txt
COOKIES_FILE=$DEST_DIR/google_cookies.txt
LOG_FILE=$DEST_DIR/downloaded.log

DOWNLOAD_SPEED_LIMIT=20M
SUB_LANG=fr,en
SUB_FORMAT=srt
FORMAT='bestvideo[ext=?mp4][height<=?720]+bestaudio[ext=?mp3]/best'
DATE_AFTER=$(date +"%Y0101")
#DATE_AFTER="now-2weekss"
TMP_DIR=/tmp/youtube-downloader

CACHE_DIR=$DEST_DIR/cache

CURRENT_DIR=`pwd`

touch $DOWNLOAD_ARCHIVE

_append_past_videos_to_downloaded_archive() {
  # $1 = channel url
  # $2 = cache download archive filename
  URL=$1
  FILECACHE=$2
  youtube-dl --playlist-reverse \
    -i -s \
    --datebefore $DATE_AFTER \
    --no-cache-dir \
    --cookies $COOKIES_FILE \
    --youtube-skip-dash-manifest \
    --get-id \
    $URL | tee $FILECACHE
    sed -i -E "s/(.*)/youtube \1/" $FILECACHE
    cat $FILECACHE >> $DOWNLOAD_ARCHIVE && sed -i '/^$/d' $DOWNLOAD_ARCHIVE
}

_download_videos() {
  # $1 = channel url
  URL=$1
  KEY=$(echo -n "$URL" | md5sum | cut -d' ' -f1)
  rm -rf $TMP_DIR/$KEY && \
  mkdir -p $TMP_DIR/$KEY/downloads && \
  cd  $TMP_DIR/$KEY && \
  cp $DOWNLOAD_ARCHIVE ./downloaded.txt && \
  cd downloads && \
  youtube-dl --playlist-reverse \
    --download-archive ../downloaded.txt \
    -i \
    -f $FORMAT \
    --dateafter $DATE_AFTER \
    --youtube-skip-dash-manifest \
    --autonumber-start 0001 \
    --no-cache-dir \
    --cookies $COOKIES_FILE \
    --add-metadata \
    --write-thumbnail \
    --write-sub --write-auto-sub --sub-lang $SUB_LANG --sub-format $SUB_FORMAT --convert-subs $SUB_FORMAT \
    --write-description \
    --limit-rate $DOWNLOAD_SPEED_LIMIT \
    -o "%(uploader)s/%(uploader)s - S$(date +"%Y")/%(playlist_index)s. %(title)s %(upload_date)s/%(uploader)s - S$(date +"%Y")E%(playlist_index)s - %(upload_date)s - %(title)s --end.%(ext)s" \
    $URL >$LOG_FILE 2>&1
  COUNT=$(find . -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [ $COUNT -gt 0 ]; then
    rename 's/(.*) - (\d{4})(\d{2})(\d{2}) - (.*) --end\.(.*)/$1 - $2-$3-$4 - $5.$6/' **/**/**/*.* && \
    echo "Copy downloaded videos to $DEST_DIR" >log.txt 2>&1 && \
    cp -rfn * $DEST_DIR && \
    cd .. && \
    echo "Append downloaded archive to $DOWNLOAD_ARCHIVE and remove empty lines" >log.txt 2>&1 && \
    grep -Fxvf $DOWNLOAD_ARCHIVE ./downloaded.txt >> $DOWNLOAD_ARCHIVE && sed -i '/^$/d' $DOWNLOAD_ARCHIVE
  fi
  cd $CURRENT_DIR && \
  rm -rf $TMP_DIR/$KEY
}


# init cache dir
mkdir -p $CACHE_DIR

# Loop batch file
awk '!/^(#|;|\])/'  $BATCH_FILE |
while IFS= read -r URL; do

  echo "" >log.txt 2>&1
  echo "Prepare to download videos for $URL ..." >log.txt 2>&1

  # check if we need to add old videos to downloaded archive
  KEY=$(echo -n "$URL" | md5sum | cut -d' ' -f1)
  filename="$CACHE_DIR/$KEY.txt"
  if [ ! -f "$filename" ]; then
      echo "" >log.txt 2>&1
      echo "Add past videos id to download archive for $URL to file $filename ..."
      _append_past_videos_to_downloaded_archive $URL $filename >log.txt 2>&1
  fi

  echo "" >log.txt 2>&1
  echo "Download new videos files for $URL" >log.txt 2>&1
  _download_videos $URL
  
  echo ""
  echo "done."
done
