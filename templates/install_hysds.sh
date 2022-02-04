#!/bin/bash
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)


# usage
usage() {
  echo "usage: $0 <repo branch> <release tag>" >&2
}


# check usage
if [ $# -ne 2 ]; then
  usage
  exit 1
fi
branch=$1
release=$2


# print out commands and exit on any errors
set -e

# set oauth token
OAUTH_CFG="$HOME/.git_oauth_token"
if [ -e "$OAUTH_CFG" ]; then
  source $OAUTH_CFG
fi
if [ -z "${GIT_OAUTH_TOKEN}" ]; then
  GIT_URL="https://github.com"
  token=""
else
  GIT_URL="https://${GIT_OAUTH_TOKEN}@github.com"
  token=" -k ${GIT_OAUTH_TOKEN} "
fi


# clone hysds-framework
cd $HOME
PACKAGE=hysds-framework
if [ ! -d "$HOME/$PACKAGE" ]; then
  git clone -b $branch --single-branch ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $HOME/$PACKAGE
if [ "$release" = "develop" ]; then
  ./install.sh -d $token grq
else
  ./install.sh -r $release $token grq
fi


SCIFLO_DIR=<%= @sciflo_dir %>


# source virtualenv
source $SCIFLO_DIR/bin/activate


# cleanup pkgs
rm -rf $SCIFLO_DIR/pkgs/*
