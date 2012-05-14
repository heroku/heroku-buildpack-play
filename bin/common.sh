#!/usr/bin/env bash

get_property()
{
  local file=${1?"No file specified"}
  local key=${2?"No key specified"}

  if [ ! -f $file ]; then
    return 0
  fi
    
  local yaml_key=.*-.*$(echo $key | sed "s/\./\\\./g")
  local grepped_line=$(grep -E ^$yaml_key $file)
  local sedded_line=$(echo $grepped_line | sed -E -e "s/$yaml_key(:?[\ \t]+([A-Za-z0-9\.-]+))?.*/\1/g")

  if [ "$grepped_line" == "$sedded_line" ]; then
    echo ""
  else
    echo $sedded_line
  fi
}

check_compile_status()
{
  if [ "${PIPESTATUS[*]}" != "0 0" ]; then
    echo " !     Failed to build Play! application"
    rm -rf $CACHE_DIR/$PLAY_PATH
    echo " !     Cleared Play! framework from cache"
    exit 1
  fi
}

install_play()
{
  VER_TO_INSTALL=$1
  PLAY_URL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-$VER_TO_INSTALL.tar.gz"
  PLAY_TAR_FILE="play-heroku.tar.gz"
  echo "-----> Installing Play! $VER_TO_INSTALL....."
  curl --silent --max-time 150 --location $PLAY_URL -o $PLAY_TAR_FILE
  if [ ! -f $PLAY_TAR_FILE ]; then
    echo "-----> Error downloading Play! framework. Please try again..."
    exit 1
  fi
  if [ -z "`file $PLAY_TAR_FILE | grep gzip`" ]; then
    echo "-----> Error installing Play! framework or unsupported Play! framework version specified. Please review Dev Center for a list of supported versions."
    exit 1
  fi
  tar xzf $PLAY_TAR_FILE
  rm $PLAY_TAR_FILE
  chmod +x $PLAY_PATH/play
  echo "-----> done"
}
