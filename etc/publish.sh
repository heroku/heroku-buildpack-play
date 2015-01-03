#!/bin/sh

set -e

BP_NAME="play"

if [ ! -z "$1" ]; then
  rm -rf /tmp/heroku-buildpack-$BP_NAME
  pushd . > /dev/null 2>&1
  cd /tmp
  git clone git@github.com:heroku/heroku-buildpack-$BP_NAME.git
  cd heroku-buildpack-$BP_NAME
  git checkout master
  find . ! -name '.' ! -name '..' ! -name 'bin' -maxdepth 1 -print0 | xargs -0 rm -rf --
  heroku buildpacks:publish $1/$BP_NAME

  if [ "$1" = "heroku" ]; then
    echo "Tagging commit... "
    newTag=$(heroku buildpacks:revisions heroku/$BP_NAME | sed -n 2p | grep -o -e "v\d*")
    git tag $newTag
    git push --tags
  fi

  popd > /dev/null 2>&1
  echo "Cleaning up..."
  rm -rf /tmp/heroku-buildpack-$BP_NAME
  echo "Done."
else
  echo "You must provide a buildkit organization as an argument!"
  exit 1
fi
