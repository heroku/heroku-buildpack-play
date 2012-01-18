#!/bin/sh

#. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

#PLAY_URL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-$VER_TO_INSTALL.tar.gz"

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
