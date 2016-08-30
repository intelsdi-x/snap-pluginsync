FROM ruby:2.3.1-slim
MAINTAINER Nan Liu <nan.liu@gmail.com>

ARG VERSION=0.6.1
ARG BUILD_DATE

LABEL name="modulesync ${VERSION}" \
      license="Apache 2.0" \
      build-date=$BUILD_DATE \
      org.voxpupuli.modulesync.version=$VERSION

RUN apt-get update && \
    apt-get install -y build-essential git && \
    gem install modulesync -v ${VERSION} --no-ri --no-rdoc && \
    apt-get autoremove -y build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh && \
    touch /root/.ssh/known_hosts && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

CMD cd /plugin && msync update --noop
