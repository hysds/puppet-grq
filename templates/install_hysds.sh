#!/bin/bash

SCIFLO_DIR=<%= @sciflo_dir %>

# create virtualenv if not found
if [ ! -e "$SCIFLO_DIR/bin/activate" ]; then
  /opt/conda/bin/virtualenv $SCIFLO_DIR --system-site-packages
  echo "Created virtualenv at $SCIFLO_DIR."
fi


# source virtualenv
source $SCIFLO_DIR/bin/activate


# install latest pip and setuptools
pip install -U pip
pip install -U setuptools


# force install supervisor
if [ ! -e "$SCIFLO_DIR/bin/supervisord" ]; then
  #pip install --ignore-installed supervisor
  pip install --ignore-installed git+https://github.com/Supervisor/supervisor
fi


# create sciflo etc directory
if [ ! -d "$SCIFLO_DIR/etc" ]; then
  mkdir $SCIFLO_DIR/etc
fi


# create sciflo scripts directory
if [ ! -d "$SCIFLO_DIR/scripts" ]; then
  mkdir $SCIFLO_DIR/scripts
fi


# create sciflo log directory
if [ ! -d "$SCIFLO_DIR/log" ]; then
  mkdir $SCIFLO_DIR/log
fi


# create run directory
if [ ! -d "$SCIFLO_DIR/run" ]; then
  mkdir $SCIFLO_DIR/run
fi


# create sqlite_data directory
if [ ! -d "$SCIFLO_DIR/sqlite_data" ]; then
  mkdir $SCIFLO_DIR/sqlite_data
  for i in `echo AIRS ALOS CloudSat MODIS-Terra MODIS-Aqua`; do
    touch $SCIFLO_DIR/sqlite_data/${i}.db
  done
fi


# set oauth token
OAUTH_CFG="$HOME/.git_oauth_token"
if [ -e "$OAUTH_CFG" ]; then
  source $OAUTH_CFG
  GIT_URL="https://${GIT_OAUTH_TOKEN}@github.com"
else
  GIT_URL="https://github.com"
fi


# create ops directory
OPS="$SCIFLO_DIR/ops"
if [ ! -d "$OPS" ]; then
  mkdir $OPS
fi


# export latest prov_es package
cd $OPS
PACKAGE=prov_es
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest osaka package
cd $OPS
GITHUB_REPO=osaka
PACKAGE=osaka
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -U pyasn1
pip install -U pyasn1-modules
pip install -U python-dateutil
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds_commons package
cd $OPS
PACKAGE=hysds_commons
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds package
cd $OPS
PACKAGE=hysds
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
pip install -U  greenlet
pip install -U  pytz
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest sciflo package
cd $OPS
PACKAGE=sciflo
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
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
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest tosca package
cd $OPS
PACKAGE=tosca
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone --single-branch -b python3 ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi
