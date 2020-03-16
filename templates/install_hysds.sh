#!/bin/bash
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)


# usage
usage() {
  echo "usage: $0 <release tag>" >&2
}


# check usage
if [ $# -ne 1 ]; then
  usage
  exit 1
fi
release=$1


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
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $HOME/$PACKAGE
if [ "$release" = "develop-es7" ]; then
  git checkout $release
  ./install.sh -d $token grq
else
  ./install.sh -r $release $token grq
fi


SCIFLO_DIR=<%= @sciflo_dir %>


# source virtualenv
source $SCIFLO_DIR/bin/activate


# create sciflo scripts directory
if [ ! -d "$SCIFLO_DIR/scripts" ]; then
  mkdir $SCIFLO_DIR/scripts
fi


# create sqlite_data directory
if [ ! -d "$SCIFLO_DIR/sqlite_data" ]; then
  mkdir $SCIFLO_DIR/sqlite_data
  for i in `echo AIRS ALOS CloudSat MODIS-Terra MODIS-Aqua`; do
    touch $SCIFLO_DIR/sqlite_data/${i}.db
  done
fi


# create ops directory
OPS="$SCIFLO_DIR/ops"
if [ ! -d "$OPS" ]; then
  mkdir $OPS
fi


# export latest eosUtils package
cd $OPS
PACKAGE=eosUtils
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest soap package
cd $OPS
PACKAGE=soap
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi


# export latest crawler package
cd $OPS
PACKAGE=crawler
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi


# export latest grq2 package
cd $OPS
PACKAGE=grq2
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest tosca package
cd $OPS
PACKAGE=tosca
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest pele package
cd $OPS
PACKAGE=pele
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# cleanup pkgs
rm -rf $SCIFLO_DIR/pkgs/*
