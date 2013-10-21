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

testPlay20NotDetected()
{
  mkdir ${BUILD_DIR}/project
  touch ${BUILD_DIR}/project/Build.scala
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf

  detect

  assertNoAppDetected
}

testPlay22NotDetected()
{
  touch ${BUILD_DIR}/build.sbt
  mkdir ${BUILD_DIR}/conf
  touch ${BUILD_DIR}/conf/application.conf

  detect

  assertNoAppDetected
}

