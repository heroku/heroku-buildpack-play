#!/bin/sh

source ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# test with procfile
# test without procfile

testReleasedYamlDoesNotIncludeDefaultProcWhenProcfileIsPresent() {
  touch ${BUILD_DIR}/Procfile
  expectedReleaseYAML=`cat <<EOF
---
config_vars:
  PATH: .play:.tools:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m
  PLAY_OPTS: --%prod -Dprecompiled=true
addons:
  shared-database:5mb
EOF`

  releaseYAML=`release`
  assertEquals "${expectedReleaseYAML}" "$(cat ${STD_OUT})" 
}

testReleasedYamlHasDefaultProcessType() {
  expectedReleaseYAML=`cat <<EOF
---
config_vars:
  PATH: .play:.tools:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m
  PLAY_OPTS: --%prod -Dprecompiled=true
addons:
  shared-database:5mb
default_process_types:
  web:    play run --http.port=\\$PORT \\$PLAY_OPTS
EOF`

  releaseYAML=`release`
  assertEquals "${expectedReleaseYAML}" "$(cat ${STD_OUT})" 
}
