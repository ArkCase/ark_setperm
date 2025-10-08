#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG PRIVATE_REGISTRY
ARG BASE_VER_PFX=""
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="22.04"
ARG PKG="setperm"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base"
ARG BASE_VER="${VER}"
ARG BASE_VER_PFX="${BASE_VER_PFX}"
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

FROM "${BASE_IMG}"

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

COPY --chown=root:root --chmod=0755 set-permissions /

#
# Final parameters
#
WORKDIR     /
ENTRYPOINT  [ "/set-permissions" ]
