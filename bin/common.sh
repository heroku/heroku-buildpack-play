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

download_play_official() {
  local playVersion=${1}
  local playTarFile=${2}
  local playZipFile="play-${playVersion}.zip"
  local playUrl="https://downloads.typesafe.com/play/${playVersion}/${playZipFile}"

  status=$(curl --retry 3 --silent --head -w %{http_code} -L ${playUrl} -o /dev/null)
  if [ "$status" != "200" ]; then
    error "Could not locate: ${playUrl}
Please check that the version ${playVersion} is correct in your conf/dependencies.yml"
    exit 1
  else
    echo "Downloading ${playZipFile} from https://downloads.typesafe.com" | indent
    curl --retry 3 -s -O -L ${playUrl}
  fi

  # create tar file
  echo "Preparing binary package..." | indent
  local playUnzipDir="tmp-play-unzipped/"
  mkdir -p ${playUnzipDir}
  unzip ${playZipFile} -d ${playUnzipDir} > /dev/null 2>&1

  PLAY_BUILD_DIR=$(find -name 'framework' -type d | sed 's/framework//')

  mkdir -p tmp/.play/framework/src/play

  # Add Play! framework
  cp -r $PLAY_BUILD_DIR/framework/dependencies.yml tmp/.play/framework
  cp -r $PLAY_BUILD_DIR/framework/lib/             tmp/.play/framework
  cp -r $PLAY_BUILD_DIR/framework/play-*.jar       tmp/.play/framework
  cp -r $PLAY_BUILD_DIR/framework/pym/             tmp/.play/framework
  cp -r $PLAY_BUILD_DIR/framework/src/play/version tmp/.play/framework/src/play
  cp -r $PLAY_BUILD_DIR/framework/templates/       tmp/.play/framework

  # Add Play! core modules
  cp -r $PLAY_BUILD_DIR/modules    tmp/.play

  # Add Play! Linux executable
  cp -r $PLAY_BUILD_DIR/play  tmp/.play

  # Add Resources
  cp -r $PLAY_BUILD_DIR/resources tmp/.play

  # Run tar and remove tmp space
  if [ ! -d build ]; then
    mkdir build
  fi

  tar cvzf ${playTarFile} -C tmp/ .play > /dev/null 2>&1
  rm -fr tmp/
}

validate_play_version() {
  local playVersion=${1}

  if [ "1.4.0" == "${playVersion}" ] || [ "1.3.2" == "${playVersion}" ]; then
    error "Unsupported version!
This version of Play! is incompatible with Linux. You may need to upgrade to a newer version.
For more information see this bug report:
https://play.lighthouseapp.com/projects/57987-play-framework/milestones/216577-141"
  elif [[ "${playVersion}" =~ ^2.* ]]; then
    error "Unsupported version!
Play 2.x requires the Scala buildpack. For more information see:
https://devcenter.heroku.com/articles/scala-support"
  fi
}

install_play()
{
  VER_TO_INSTALL=$1
  PLAY_URL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-$VER_TO_INSTALL.tar.gz"
  PLAY_TAR_FILE="play-heroku.tar.gz"

  validate_play_version ${VER_TO_INSTALL}

  echo "-----> Installing Play! $VER_TO_INSTALL....."

  status=$(curl --retry 3 --silent --head -w %{http_code} -L ${PLAY_URL} -o /dev/null)
  if [ "$status" != "200" ]; then
    download_play_official ${VER_TO_INSTALL} ${PLAY_TAR_FILE}
  else
    curl --retry 3 -s --max-time 150 -L $PLAY_URL -o $PLAY_TAR_FILE
  fi

  if [ ! -f $PLAY_TAR_FILE ]; then
    echo "-----> Error downloading Play! framework. Please try again..."
    exit 1
  fi
  if [ -z "`file $PLAY_TAR_FILE | grep gzip`" ]; then
    error "Failed to install Play! framework or unsupported Play! framework version specified.
Please review Dev Center for a list of supported versions."
    exit 1
  fi
  tar xzmf $PLAY_TAR_FILE
  rm $PLAY_TAR_FILE
  chmod +x $PLAY_PATH/play
  echo "Done installing Play!" | indent
}

remove_play() {
  local buildDir=${1}
  local playVersion=${2}

  rm -rf ${buildDir}/tmp-play-unzipped
  rm -f ${buildDir}/play-${playVersion}.zip
}
