#!/bin/bash
set -e

# set HOME explicitly
export HOME=/root

# wait for redis and ES
/wait-for-it.sh -t 30 grq-redis:6379
/wait-for-it.sh -t 30 grq-elasticsearch:9200

# get group id
GID=$(id -g)

# generate ssh keys
gosu 0:0 ssh-keygen -A 2>/dev/null

# update ownership of other files
if [ -e /var/run/docker.sock ]; then
  gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
fi

# source bash profile
source $HOME/.bash_profile

# source grq virtualenv
if [ -e "$HOME/sciflo/bin/activate" ]; then
  source $HOME/sciflo/bin/activate
fi

# install ES template for grq datasets
$HOME/sciflo/ops/grq2/scripts/install_es_template.sh || :

# install ES templates for HySDS package indexes
$HOME/sciflo/ops/hysds_commons/scripts/install_es_template.sh grq || :

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
