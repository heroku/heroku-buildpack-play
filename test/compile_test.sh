#!/usr/bin/env bash

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

PLAY_TEST_CACHE="/tmp/play-test-cache"
DEFAULT_PLAY_VERSION=1.2.4

_full_play() {
  local playVersion=${1:-${DEFAULT_PLAY_VERSION}}
  local playBaseDir="${2:-${PLAY_TEST_CACHE}/full}"
  local playExe="${playBaseDir}/play-${playVersion}/play"
  local playUrl="http://s3.amazonaws.com/heroku-jvm-buildpack-play-test/play-${playVersion}.tar.gz"
  local playCommand="$(installPlay ${playVersion} ${playBaseDir} ${playExe} ${playUrl})"
  echo "${playCommand}"
}

installPlay() {
  local playVersion=$1
  local playBaseDir=$2
  local playExe=$3
  local playURL=$4
  if [ ! -x ${playExe} ]; then
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
    $(_full_play ${playVersion}) new ${appBaseDir} --name app >/dev/null
  fi
  cp -r ${appBaseDir}/. ${BUILD_DIR}
  assertTrue "${BUILD_DIR}/conf/application.conf should be present after creating a new app." "[ -f ${BUILD_DIR}/conf/application.conf ]"
}

newPlayApp() {
  local appBaseDir="$1"
  local playVersion=${2:-${DEFAULT_PLAY_VERSION}}
  $(_full_play ${playVersion}) new ${appBaseDir}/.playapp --name app >/dev/null
  cp -r ${appBaseDir}/.playapp/. ${appBaseDir}
}

definePlayAppVersion() {
  local playVersion=$1
  cat > ${BUILD_DIR}/conf/dependencies.yml <<EOF
require:
    - play ${playVersion}
EOF
}

testNewAppGetsSystemPropertiesFile() {
  newPlayApp "${BUILD_DIR}"
  rm -rf ${CACHE_DIR}
  compile
  assertCapturedSuccess
  assertCaptured "Installing OpenJDK"
}

testSystemPropertiesInCacheDirGetsCopied() {
  newPlayApp "${BUILD_DIR}"
  echo "java.runtime.version=1.6" > ${CACHE_DIR}/system.properties
  compile
  assertCapturedSuccess
  assertCaptured "Installing OpenJDK"
  assertTrue "System properties file should be present in build dir." "[ -f ${BUILD_DIR}/system.properties ]"
  assertTrue "System properties file should be present in cache dir." "[ -f ${CACHE_DIR}/system.properties ]"
}

testCacheUnpacksIntoBuildDirAndPacksBackIntoCache() {
  getPlayApp

  mkdir -p ${CACHE_DIR}/.play
  mkdir -p ${CACHE_DIR}/.ivy2
  touch ${CACHE_DIR}/.play/test-cached
  touch ${CACHE_DIR}/.ivy2/test-cached

  assertTrue "Precondition: A play file should have been added to the cache dir" "[ -f ${CACHE_DIR}/.play/test-cached ]"
  assertTrue "Precondition: An ivy file should have been added to the cache dir" "[ -f ${CACHE_DIR}/.ivy2/test-cached ]"

  compile

  assertTrue "A play file should have been added to the build dir" "[ -f ${BUILD_DIR}/.play/test-cached ]"
  assertFalse "Ivy files should have been removed from the build dir" "[ -d ${BUILD_DIR}/.ivy2 ]"
  assertTrue "A play file should have been added to the cache dir" "[ -f ${CACHE_DIR}/.play/test-cached ]"
  assertTrue "An ivy file should have been added to the cache dir" "[ -f ${CACHE_DIR}/.ivy2/test-cached ]"
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
    "Dependencies should have been resolved for guava." \
    "[ -f ${BUILD_DIR}/lib/guava-11.0.jar ]"
  assertTrue \
    "A precompiled app should have an Application.class" \
    "[ -f ${BUILD_DIR}/precompiled/java/controllers/Application.class ]"
}

testCustomIvySettingsAreInstalled() {
  getPlayApp

  mkdir -p ${BUILD_DIR}/.ivy2-overlay
  cat > ${BUILD_DIR}/.ivy2-overlay/ivysettings.xml <<EOF
<ivysettings>
  <settings defaultResolver="s3pository"/>
  <resolvers>
    <ibiblio name="s3pository" root="http://s3pository.heroku.com/maven-central/" m2compatible="true" />
  </resolvers>
</ivysettings>
EOF

  compile
  assertCaptured "Installing custom Ivy files"
  assertTrue "Ivy settings file should be installed." "[ -f ${CACHE_DIR}/.ivy2/ivysettings.xml ]"
  assertContains \
    "s3pository.heroku.com" \
    "$(cat ${CACHE_DIR}/.ivy2/ivysettings.xml)"
}

testBuildTimeArtifactsAreDeleted() {
  getPlayApp
  compile
  assertFalse \
    "Play modules should not be present in the slug." \
    "[ -d ${BUILD_DIR}/.play/modules ]"
  assertFalse \
    "Ivy should not be present in the slug." \
    "[ -d ${BUILD_DIR}/.ivy2 ]"
}

testCacheNotCopiedForFailedBuild() {
  getPlayApp

  rm ${BUILD_DIR}/conf/application.conf
  mkdir -p ${CACHE_DIR}/.play
  touch ${CACHE_DIR}/.play/test-cached

  compile

  assertTrue \
    "Files in ${CACHE_DIR}/.play should have been cleared after a failed build." \
    "[ ! -f ${CACHE_DIR}/.play/test-cached ]"
  assertTrue \
    "${CACHE_DIR}/.play/play should have been cleared after a failed build." \
    "[ ! -f ${CACHE_DIR}/.play/play ]"
}

testProcfileWarningIsDisplayedWhenNoProcfileIsPresent() {
  getPlayApp
  assertTrue "No procfile should be present in an empty app." "[ ! -f ${BUILD_DIR}/Procfile ]"

  compile

  assertCaptured "No Procfile found. Will use the following default process"
}

testPlayRCVersion() {
  local rc_version="1.2.5rc3"
  getPlayApp ${rc_version}
  definePlayAppVersion ${rc_version}

  compile

  assertCaptured "Installing Play! ${rc_version}"
}

testPlayVersionIsPickedUpFromDependenciesFile() {
  getPlayApp "1.2.4"
  definePlayAppVersion "1.2.4"

  compile

  assertCaptured "Installing Play! 1.2.4"
  assertNotCaptured "WARNING: Play! version not specified in dependencies.yml."
}

testPlayInstalledInBuildDirSlashDotPlayDir() {
  compile
  assertTrue "${BUILD_DIR}/.play should be present in build dir after a successful build" "[ -x ${BUILD_DIR}/.play/play ]"
}

testPlayCopiedToCacheDirForSuccessfulBuild() {
  getPlayApp
  compile
  assertTrue "${CACHE_DIR}/.play should be present in cache dir after a successful build." "[ -f ${CACHE_DIR}/.play/play ]"
}

testValidVersionOfPlayThatIsNotInS3Bucket() {
  getPlayApp
  definePlayAppVersion "1.0.1"

  compile

  assertCaptured "Installing Play! 1.0.1"
  assertCaptured "Could not locate:"
  assertCaptured "Please check that the version 1.0.1 is correct in your conf/dependencies.yml"
}

testUpgradePlayProject() {
  getPlayApp "1.2.3"
  definePlayAppVersion "1.2.3"
  compile
  definePlayAppVersion "1.2.4"
  compile
  assertCaptured "Updating Play! version."
}

testCacheIsDeletedDuringUpgrade() {
  getPlayApp "1.2.3"
  definePlayAppVersion "1.2.3"
  compile

  mkdir -p ${CACHE_DIR}/.play
  touch ${CACHE_DIR}/.play/test-cached

  definePlayAppVersion "1.2.4"
  compile
  assertFalse \
    "${CACHE_DIR}/.play/test-cached should have been deleted during play upgrade." \
    "[ -f ${CACHE_DIR}/.play/test-cached ]"
}
