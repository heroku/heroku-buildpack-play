#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDetectWithConfFileDetectsPlayApp() {
  mkdir -p ${BUILD_DIR}/play-app/conf
  touch ${BUILD_DIR}/play-app/conf/application.conf
  detect
  
  assertAppDetected "Play!"
}

testDetectWithConfFileDetectsPlayApp() {
  mkdir -p ${BUILD_DIR}/play-app/conf/application.conf
  detect
  
  assertNoAppDetected
}

testNoConfFileDoesNotDetectPlayApp() {
  mkdir -p ${BUILD_DIR}/play-app/conf
  detect

  assertNoAppDetected
}

testConfFileWithModulesDirectoryDoesNotDetectPlayApp() {
  mkdir -p ${BUILD_DIR}/play-app/modules/conf
  touch ${BUILD_DIR}/play-app/modules/conf/application.conf
  detect

  assertNoAppDetected
}
