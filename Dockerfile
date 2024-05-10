ARG ARCH="amd64"
ARG OS="linux"
ARG VER="1.1.0"

FROM ubuntu:latest

#
# Basic Parameters
#
ARG ARCH
ARG OS
ARG VER

#
# Some important labels
#
LABEL ORG="Armedia LLC"
LABEL MAINTAINER="Armedia Devops Team <devops@armedia.com>"
LABEL APP="Set Permissions"
LABEL VERSION="${VER}"
LABEL IMAGE_SOURCE="https://github.com/ArkCase/ark_setperm"

# Default parallelism rate of 4 processes (min 1, max 16)
ENV PARALLELISM="4"
# Default batch size of 1,000 items (min 100, max 10,000)
ENV BATCH_SIZE="1000"
# Debug mode is turned off by default (set this to "True" to enable)
ENV DEBUG="False"
# Root mode is enabled by default (set this to "True" to disable)
ENV NOROOT="False"
# The jobs to run
ENV JOBS=""

RUN apt-get update && apt-get -y dist-upgrade && apt-get -y install python3-yaml
COPY --chown=root:root set-permissions /
RUN /usr/bin/chmod -R 750 /set-permissions

#
# Final parameters
#
WORKDIR     /
ENTRYPOINT  [ "/set-permissions" ]
