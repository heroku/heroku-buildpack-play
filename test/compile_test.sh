#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# test cache is unpacked
# test play version is picked up correctly in PLAY_VERSION from dependencies.yml
# test play is installed correctly
# test an upgrade of play version
# test a valid version of play that isn't in S3
# test a fake version of play
# test ivysettings.xml is removed and our custom settings are used
# test dependencies are correctly retrieved
# test precompile phase compiles artifacts
# test play gets put into cache after precompile
# test modules and ivy deps from build time are removed and not included in the slug
# test a warning is printed if no procfile is present

PLAY_TEST_CACHE="/tmp/play-test-cache"
DEFAULT_PLAY_VERSION=1.2.4

_play() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local playCommand="${PLAY_TEST_CACHE}/${playVersion}/.play/play" 
  if [ ! -f "${playCommand}" ]; then
    echo "playCommand: $playCommand" >&2
    installPlay "${playVersion}"
  fi
  echo "${playCommand}"
}

installPlay() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local playURL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-${playVersion}.tar.gz"
  if [ ! -f ${PLAY_TEST_CACHE}/${playVersion}/.play/play ]; then
    mkdir -p ${PLAY_TEST_CACHE}/${playVersion}
    local currentDir="$(pwd)"
    cd ${PLAY_TEST_CACHE}/${playVersion}
    curl --silent --max-time 180 --location ${playURL} | tar xzf
    chmod +x .play/play 
    cd ${currentDir}
  fi
}

createPlayApp() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local appBaseDir="${PLAY_TEST_CACHE}/app-${playVersion}" 
  if [ ! -d ${appBaseDir} ]; then
    $(_play) new ${appBaseDir} --name app > ./fail
  fi
  echo "${appBaseDir}"
}

createDetectablePlayApp() {
  version=${1:-${DEFAULT_PLAY_VERSION}}
  confFile=`cat >  <<EOF
require:
    - play ${version}
EOF`
  
}

testNewApp() {
  local newApp="$(createPlayApp)"
  assertEquals "${newApp}" "/tmp/play-test-cache/app-1.2.4"
  assertTrue "An application.conf file should have been created for a new app" "[ -f ${newApp}/conf/application.conf ]"
}
