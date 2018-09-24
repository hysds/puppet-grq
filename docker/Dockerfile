FROM hysds/dev:latest

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-grq/raw/docker/install.sh

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-grq/git/refs/heads/docker version.json

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum \
 && cd $HOME \
 && ./install_hysds.sh \
 && rm -rf $HOME/sciflo/ops/*/.git* \
 && rm -rf $HOME/.cache


FROM hysds/base:latest


MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="HySDS GRQ image"

# git url to hysds dev puppet module
ENV GIT_URL https://github.com/hysds/puppet-grq/raw/docker/install.sh

# add latest repo version to invalidate cache
ADD https://api.github.com/repos/hysds/puppet-grq/git/refs/heads/docker version.json

# provision via puppet
RUN set -ex \
 && sudo yum update -y \
 && sudo curl -skL ${GIT_URL} > /tmp/install.sh \
 && sudo chmod 755 /tmp/install.sh \
 && sudo /tmp/install.sh \
 && sudo rm -rf /etc/puppet/modules/* /mnt/swapfile \
 && sudo yum clean all \
 && sudo rm -f /tmp/install.sh \
 && sudo rm -rf /var/cache/yum

# copy ops home
COPY --chown=ops:ops --from=0 /home/ops /home/ops

# link configuration files
RUN set -ex \
 && ln -sf /home/ops/sciflo/etc/celeryconfig.py /home/ops/sciflo/ops/hysds/celeryconfig.py \
 && ln -sf /home/ops/sciflo/etc/grq2_settings.cfg /home/ops/sciflo/ops/grq2/settings.cfg \
 && ln -sf /home/ops/sciflo/etc/tosca_settings.cfg /home/ops/sciflo/ops/tosca/settings.cfg \
 && ln -sf /home/ops/sciflo/etc/server.key /home/ops/sciflo/ops/grq2/server.key \
 && ln -sf /home/ops/sciflo/etc/server.pem /home/ops/sciflo/ops/grq2/server.pem \
 && ln -sf /home/ops/sciflo/etc/server.key /home/ops/sciflo/ops/tosca/server.key \
 && ln -sf /home/ops/sciflo/etc/server.pem /home/ops/sciflo/ops/tosca/server.pem

# set entrypoint
COPY docker/wait-for-it.sh /wait-for-it.sh
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 80 443 8878 8879 9001
CMD ["supervisord"]
