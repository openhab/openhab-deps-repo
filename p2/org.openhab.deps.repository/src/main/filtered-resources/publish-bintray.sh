#!/bin/bash
#
# Publish p2 repo to bintray
# Usage: publish-bintray.sh user apikey owner 
#
BINTRAY_USER=$1
BINTRAY_API_KEY=$2
BINTRAY_OWNER=$3
PCK_VERSION=${project.version}
DIRNAME=`dirname "$0"`
REPO_DIR=$DIRNAME/repository
BASE_URL=https://api.bintray.com/content/${BINTRAY_OWNER}/p2/openhab-deps-repo

function main() {
  deploy_updatesite
}


function putFile() {
  target_loc=${PCK_VERSION}/$2
  echo "Uploading file $1 to $2"
  response=$(curl -s -X PUT -T $1 -u ${BINTRAY_USER}:${BINTRAY_API_KEY} $BASE_URL/$target_loc;publish=0)
  if [[ $response == *"success"* ]]
  then
    echo "OK - $response"
  elif [[ $response == *"already exists"* ]]
  then
    echo "Exists - $response"
  else
    echo "Retry - $response"
    response=$(curl -s -X PUT -T $1 -u ${BINTRAY_USER}:${BINTRAY_API_KEY} $BASE_URL/$target_loc;publish=0)
    echo "Failed - $response"
    die 1;
  fi
}


function deploy_updatesite() {

  cd $REPO_DIR

  FILES=./*.jar
  PLUGINDIR=./plugins/*
  FEATUREDIR=./features/*

  echo "Creating new version"
  curl -s -X POST -u ${BINTRAY_USER}:${BINTRAY_API_KEY} $BASE_URL/versions -d "{ \"name\": \"${PCK_VERSION}\", \"desc\": \"Release ${PCK_VERSION}\"  }"

  for f in $FILES;
  do
  if [ ! -d $f ]; then
    putFile $f $f
  fi
  done

  echo "Processing features dir $FEATUREDIR file..."
  for f in $FEATUREDIR;
  do
    putFile $f ${f:2}
  done

  echo "Processing plugin dir $PLUGINDIR file..."

  for f in $PLUGINDIR;
  do
    putFile $f ${f:2}
  done

  echo "Publishing the new version"
  curl -X POST -u ${BINTRAY_USER}:${BINTRAY_API_KEY} $BASE_URL/${PCK_VERSION}/publish -d "{ \"discard\": \"false\" }"

}


main "$@"