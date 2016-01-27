#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testReleasedYamlDoesNotIncludeDefaultProcWhenProcfileIsPresent() {
  touch ${BUILD_DIR}/Procfile
  expectedReleaseYAML=`cat <<EOF
---
config_vars:
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  PLAY_OPTS: --%prod -Dprecompiled=true
addons:
  heroku-postgresql
EOF`

  release
  assertCapturedEquals "${expectedReleaseYAML}"
}

testReleasedYamlHasDefaultProcessType() {
  expectedReleaseYAML=`cat <<EOF
---
config_vars:
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
  PLAY_OPTS: --%prod -Dprecompiled=true
addons:
  heroku-postgresql
default_process_types:
  web:    play run --http.port=\\$PORT \\$PLAY_OPTS
EOF`

  release
  assertCapturedEquals "${expectedReleaseYAML}"
}
