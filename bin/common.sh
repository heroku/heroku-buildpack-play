#!/usr/bin/env bash

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|JAVA_OPTS)$'}
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

get_play_version()
{
  local file=${1?"No file specified"}

  if [ ! -f $file ]; then
    return 0
  fi

  grep -P '.*-.*play[ \t]+[0-9\.]' ${file} | sed -E -e 's/[ \t]*-[ \t]*play[ \t]+([0-9A-Za-z\.]*).*/\1/'
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
  tar xzmf $PLAY_TAR_FILE
  rm $PLAY_TAR_FILE
  chmod +x $PLAY_PATH/play
  echo "-----> done"
}
