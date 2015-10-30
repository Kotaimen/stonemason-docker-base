FROM        ubuntu:15.10
MAINTAINER  Kotaimen <kotaimen.c@gmail.com>
LABEL       Description="Stonemason base image"
ENV         DEBIAN_FRONTEND noninteractive

#
# HACK: Speed AWS build by using local APT sources
#
RUN         set -x \
            && mv /etc/apt/sources.list /etc/apt/sources.list.back \
            && sed s/archive.ubuntu.com/ap-northeast-1.ec2.archive.ubuntu.com/ /etc/apt/sources.list.back > /etc/apt/sources.list

#
# Set locale
#
RUN         locale-gen en_US.UTF-8
ENV         LANG=en_US.UTF-8 \
            LANGUAGE=en_US:en \
            LC_ALL=en_US.UTF-8

#
# Install apt packages and stable python bindings
#
RUN         set -x \
            &&  apt-get -q update \
            &&  apt-get -yq install \
                curl \
                unzip \
                make \
                automake \
                libtool \
                git \
                python3.5 \
                python3.5-dev \
                python3-pip \
                python3-scipy \
                python3-numpy \
                python3-skimage \
                python3-pylibmc \
                python3-pil \
                libpq5 \
                webp \
                imagemagick \
                cython3 \
                gdal-bin \
                libgdal1i \
                python3-gdal

#
# Build python-mapnik (PPA is broken)
#

# NOTE : Requires at least 8GB memory for 2 cores and 16GB on 4 cores,
#        through 16 cores requires only 32GB memory.

WORKDIR     /tmp

ENV         FREETYPE_VERSION=VER-2-6-1 \
            MAPNIK_VERSION=v3.0.8

COPY        3090-fix.diff ./


RUN         set -x \
            && DEV_PACKAGES="python3-cairo-dev \
                libcairo2-dev \
                libboost-dev \
                libboost-filesystem-dev \
                libboost-program-options-dev \
                libboost-python-dev \
                libboost-regex-dev \
                libboost-system-dev \
                libboost-thread-dev \
                libz-dev \
                libharfbuzz-dev \
                libwebp-dev \
                liblcms2-dev  \
                libjpeg-dev \
                libtiff-dev \
                libproj-dev \
                libgeos-dev \
                libgdal-dev \
                libicu-dev \
                libfreetype6-dev \
                libsqlite3-dev \
                libpq-dev \
                libxml2-dev" \
            && apt-get -yq install $DEV_PACKAGES

RUN         set -x \
            && git clone git://git.sv.nongnu.org/freetype/freetype2.git \
            && cd freetype2 \
            && git checkout ${FREETYPE_VERSION} \
            && ./autogen.sh \
            && ./configure \
            && ./scons/scons.py -j `nproc` \
            && make install \

            && cd .. \
            && git clone https://github.com/mapnik/mapnik mapnik \
            && cd mapnik \
            && git checkout ${MAPNIK_VERSION} \
            && git apply /tmp/3090-fix.diff \
            && ./configure \
            && JOBS=`nproc` && make install \
            && git clone https://github.com/mapnik/python-mapnik python-mapnik \

            && cd python-mapnik \
            && python3.5 setup.py build \
            && python3.5 setup.py install \
            && cd /tmp && rm -rvf *


#
# Patch gdal data files, see
#   https://launchpad.net/ubuntu/trusty/+source/gdal/+copyright
RUN         curl -SL http://cdn.masonmaps.me/dist/gdal-1.11.3/data/esri_extra.wkt > /usr/share/gdal/1.11/esri_extra.wkt

#
# Install pip packages with no strict version requirement
#
RUN         pip3 install -q \
                boto3 \
                six \
                futures \
                flask \
                gunicorn \
                Click \
                nose \
                sphinx \
                tox

RUN         set -x \
            && python3.5 -c 'import gdal; print("GDAL Version:", gdal.VersionInfo())' \
            && python3.5 -c 'import mapnik; print("Mapnik Version:", mapnik.mapnik_version())' \
            && python3.5 -c 'import os, mapnik; print("Mapnik Plugins: ", list(mapnik.DatasourceCache.plugin_names()))' \
            && convert --version \
            && python3.5 -c 'import PIL; print("Pillow Version:", PIL.VERSION, PIL.PILLOW_VERSION)' \
            && convert rose: /tmp/rose.jpg \
            && convert rose: /tmp/rose.png \
            && convert rose: /tmp/rose.webp \
            && rm /tmp/rose*

