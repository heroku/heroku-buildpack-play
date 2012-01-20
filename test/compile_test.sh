#!/usr/bin/env bash

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# test modules and ivy deps from build time are removed and not included in the slug

PLAY_TEST_CACHE="/tmp/play-test-cache"
DEFAULT_PLAY_VERSION=1.2.4

_play() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local playCommand=`$(installPlay) "${playVersion}"`
  echo "${playCommand}"
}

_full_play() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local playBaseDir="${2:-${PLAY_TEST_CACHE}/full}"
  local playExe="${playBaseDir}/play-${playVersion}/play"
  local playUrl="http://download.playframework.org/releases/play-${playVersion}.zip"
  local playCommand="$(installPlay ${playVersion} ${playBaseDir} ${playExe} ${playUrl})"
  echo "${playCommand}"
}

installPlay() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local playBaseDir=${2:-${PLAY_TEST_CACHE}/${playVersion}}
  local playExe=${3:-${playBaseDir}/.play/play}
  local playURL=${4:-"https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-${playVersion}.tar.gz"}
  if [ ! -f ${playExe} ]; then
    mkdir -p ${playBaseDir}
    local currentDir="$(pwd)"
    cd ${playBaseDir}
    curl --silent --max-time 300 --location ${playURL} | tar xz
    chmod +x ${playExe}
    cd ${currentDir}
  fi
  echo "${playExe}"
}

getPlayApp() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local appBaseDir="${PLAY_TEST_CACHE}/app-${playVersion}"
  if [ ! -f ${appBaseDir}/conf/application.conf ]; then
    $(_full_play) new ${appBaseDir} --name app
  fi
  cp -r ${appBaseDir}/. ${BUILD_DIR}
  assertTrue "Expected ${BUILD_DIR}/conf/application.conf, but it's not there." "[ -f ${BUILD_DIR}/conf/application.conf ]"
}

definePlayAppVersion() {
  local playVersion=$1
  cat > ${BUILD_DIR}/conf/dependencies.yml <<EOF
require:
    - play ${playVersion}
EOF
}

testNewApp() {
  getPlayApp
  assertTrue "An application.conf file should have been created for a new app" "[ -f ${BUILD_DIR}/conf/application.conf ]"
}

testBuildPhases() {
  getPlayApp
  assertTrue "A new app should have an Application.java" "[ -f ${BUILD_DIR}/app/controllers/Application.java ]"
  cat > ${BUILD_DIR}/conf/dependencies.yml <<EOF
require:
    - play ${DEFAULT_PLAY_VERSION}
    - com.google.guava -> guava 11.0
EOF
  compile
  assertTrue \
    "Dependencies should have been resolved for guava, but they're not present after compiling." \
    "[ -f ${BUILD_DIR}/lib/guava-11.0.jar ]"
  assertTrue \
    "A precompiled app should have an Application.class" \
    "[ -f ${BUILD_DIR}/precompiled/java/controllers/Application.class ]"
}

testHerokuIvySettingsAreInstalled() {
  getPlayApp
  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertTrue "Ivy settings file is not installed." "[ -f ${CACHE_DIR}/.ivy2/ivysettings.xml ]"
  assertContains \
    "s3pository.heroku.com" \
    "$(cat ${CACHE_DIR}/.ivy2/ivysettings.xml)"
}

testBuildTimeArtifactsAreDeleted() {
  getPlayApp
  compile
  assertTrue \
    "Play modules should not be present in the slug, but are still in the build dir." \
    "[ ! -d ${BUILD_DIR}/.play/modules ]"
  assertTrue \
    "Ivy doesn't need to remain in the slug after deps are resolved, but are still present." \
    "[ ! -d ${BUILD_DIR}/.ivy2 ]"
}

testCacheIsCopied() {
  getPlayApp
  
  mkdir -p ${CACHE_DIR}/.play
  mkdir -p ${CACHE_DIR}/.ivy2
  touch ${CACHE_DIR}/.play/test-cached
  touch ${CACHE_DIR}/.ivy2/test-cached
  
  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  
  assertTrue "A play file was added to the cache dir, but it is not present after compile." "[ -f ${CACHE_DIR}/.play/test-cached ]"
  assertTrue "An ivy file was added to the cache dir, but it is not present after compile." "[ -f ${CACHE_DIR}/.ivy2/test-cached ]"
}

testCacheNotCopiedForFailedBuild() {
  getPlayApp

  rm ${BUILD_DIR}/conf/application.conf
  mkdir -p ${CACHE_DIR}/.play/test-cached

  compile
  
  assertTrue \
    "Files in ${CACHE_DIR}/.play should have been cleared after a failed build, but are still present." \
    "[ ! -f ${CACHE_DIR}/.play/test-cached ]"
  assertTrue \
    "${CACHE_DIR}/.play/play should have been cleared after a failed build, but is still present." \
    "[ ! -f ${CACHE_DIR}/.play/play ]"
}

testProcfileWarningIsDisplayedWhenNoProcfileIsPresent() {
  getPlayApp
  assertTrue "No procfile should be present in an empty app." "[ ! -f ${BUILD_DIR}/Procfile ]"

  compile

  assertContains "No Procfile found. Will use the following default process" "$(cat ${STD_OUT})"
}

testPlayVersionIsPickedUpFromDependenciesFile() {
  getPlayApp "1.2.4"
  definePlayAppVersion "1.2.4"

  compile

  assertNotContains "WARNING: Play! version not specified in dependencies.yml." "$(cat ${STD_OUT})"
}

testPlayInstalledInBuildDirSlashDotPlayDir() {
  compile
  assertTrue "Expected play to be present in ${BUILD_DIR}/.play, but it's not." "[ -f ${BUILD_DIR}/.play/play ]"
}

testPlayCopiedToCacheDirForSuccessfulBuild() {
  getPlayApp
  compile
  assertTrue "Expected play to be present in ${CACHE_DIR}/.play, but it's not." "[ -f ${CACHE_DIR}/.play/play ]"
}

testValidVersionOfPlayThatIsNotInS3Bucket() {
  getPlayApp "1.1.1"
  definePlayAppVersion "1.1.1"
  compile
  assertContains \
    "Error installing Play! framework or unsupported Play! framework version specified." \
    "$(cat ${STD_OUT})"
}

testUpgradePlayProject() {
  getPlayApp "1.2.3"
  definePlayAppVersion "1.2.3"
  compile
  definePlayAppVersion "1.2.4"
  compile
  assertContains \
    "Updating Play! version." \
    "$(cat ${STD_OUT})"
}

