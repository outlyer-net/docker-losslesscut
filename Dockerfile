# See https://github.com/jlesage/docker-baseimage-gui

ARG app_version="3.61.1"
# Bump if publishing a new image with the same app_version, reset to 1 with new app versions 
ARG image_revision="1"
# BUILDPLATFORM and TARGETPLATFORM are defined when using BuildKit (i.e. docker buildx)
# Do NOT define a default value or it will override what BuildKit sets
# Do NOT declare TARGETPLATFORM as an ARG before FROM either or it becomes empty
#ARG TARGETPLATFORM

FROM jlesage/baseimage-gui:debian-11-v4 AS extract-stage
ARG TARGETPLATFORM
ARG app_version
ARG download_url_template="https://github.com/mifi/lossless-cut/releases/download/v${app_version}/LosslessCut-linux-#ARCH#.tar.bz2"
#ARG download_url_template="https://github.com/mifi/lossless-cut/releases/latest/download/LosslessCut-linux-#ARCH#.tar.bz2"

# Fail early if TARGETPLATFORM isn't set
RUN test -n "${TARGETPLATFORM}"

# Note ADDing a local tarball automatically extracts it whereas a tarball url is downloaded AS-IS
#ADD ${download_url} /

# The LC_ALL is an attempt to prevent apt complaining about the locale
# Deduce LosslessCut architecture suffix based on TARGETPLATFORM 
RUN LC_ALL=C add-pkg \
                ca-certificates \
                pbzip2 \
                wget \
    && { \
        [ $TARGETPLATFORM = linux/amd64 ] && echo x64 ; \
        [ $TARGETPLATFORM = linux/arm64 ] && echo arm64 ; \
        [ $TARGETPLATFORM = linux/arm/v7 ] && echo armv7l ; \
    } \
    | xargs -I '#ARCH#' \
        wget --progress=dot:giga -O /app.tbz ${download_url_template} \
    && tar -C / -I pbzip2 -xvf /app.tbz \
    && mv /LosslessCut-linux-*/ /LosslessCut

FROM jlesage/baseimage-gui:debian-11-v4 AS final-stage
ARG app_icon="https://raw.githubusercontent.com/mifi/lossless-cut/master/src/renderer/src/icon.svg"
ARG app_version
ARG image_revision
# Missing libraries as of v3.59.1, adjusted to Debian 11
#  See the helper script 'generate_dependencies_list.bash'
RUN LC_ALL="C.UTF-8" add-pkg \
      libasound2 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libatspi2.0-0 \
      libavahi-client3 \
      libavahi-common3 \
      libblkid1 \
      libbrotli1 \
      libbsd0 \
      libcairo2 \
      libcairo-gobject2 \
      libcups2 \
      libdatrie1 \
      libdrm2 \
      libepoxy0 \
      libffi7 \
      libfontconfig1 \
      libfreetype6 \
      libfribidi0 \
      libgbm1 \
      libgcrypt20 \
      libgdk-pixbuf-2.0-0 \
      libglib2.0-0 \
      libgmp10 \
      libgnutls30 \
      libgraphite2-3 \
      libgssapi-krb5-2 \
      libgtk-3-0 \
      libharfbuzz0b \
      libhogweed6 \
      libidn2-0 \
      libjpeg62-turbo \
      libk5crypto3 \
      libkrb5-3 \
      libkrb5support0 \
      liblz4-1 \
      libmd0 \
      libmount1 \
      libnettle8 \
      libnspr4 \
      libnss3 \
      libp11-kit0 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libpangoft2-1.0-0 \
      libpcre2-8-0 \
      libpixman-1-0 \
      libpng16-16 \
      libsystemd0 \
      libtasn1-6 \
      libthai0 \
      libunistring2 \
      libuuid1 \
      libwayland-client0 \
      libwayland-cursor0 \
      libwayland-egl1 \
      libwayland-server0 \
      libx11-6 \
      libxau6 \
      libxcb1 \
      libxcb-randr0 \
      libxcb-render0 \
      libxcb-shm0 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxdmcp6 \
      libxext6 \
      libxfixes3 \
      libxi6 \
      libxinerama1 \
      libxkbcommon0 \
      libxrandr2 \
      libxrender1 \
      libpulse-dev \
      libzstd1

# some manual additions, mostly from  v3.47.1
RUN LC_ALL="C.UTF-8" add-pkg \
      libgl1 \
      libx11-xcb1
#      #libxss1 \
#      #libxtst6

COPY --from=extract-stage /LosslessCut /LosslessCut

# Sandboxing doesn't appear to work, Docker should be sandboxed enough though
RUN echo '#!/bin/sh' > /startapp.sh \
    && echo 'exec /LosslessCut/losslesscut' --no-sandbox >> /startapp.sh \
    && chmod 0755 /startapp.sh
    #&& chmod 04755 /LosslessCut-linux-${app_platform}/chrome-sandbox

# Set app name, version and generate favicons
RUN set-cont-env APP_NAME "LosslessCut" \
    && set-cont-env APP_VERSION ${app_version} \
    && set-cont-env DOCKER_IMAGE_VERSION ${image_revision} \
    && APP_ICON_URL=$app_icon && \
       install_app_icon.sh "$APP_ICON_URL"

VOLUME ["/config", "/storage"]

# 5800: Web, 5900: VNC
EXPOSE 5800/tcp 5900/tcp

# Note the org.label-schema.* labels are inherited from the base image
# TODO: Find out if it's worth overwriting them
LABEL \
      maintainer="Toni Corvera <outlyer@gmail.com>" \
      org.opencontainers.image.title="Dockerized LosslessCut" \
      org.opencontainers.image.description="Docker container to make LosslessCut usable via web browser and VNC" \
      org.opencontainers.image.version="$DOCKER_IMAGE_VERSION" \
      org.opencontainers.image.url="https://hub.docker.com/repository/docker/outlyernet/losslesscut" \
      org.opencontainers.image.source="https://github.com/outlyer-net/docker-losslesscut" \
      org.opencontainers.image.licenses="GPL-2.0"

# Define HOME to ease usage of the file chooser
ENV HOME=/storage

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD \
    pidof cinit \
    && pidof losslesscut \
    && nc -z -v 127.0.0.1 $WEB_LISTENING_PORT
