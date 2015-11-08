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
                libwebp5 \
                libpng3 \
                libjpeg62 \
                libtiff5 \
                imagemagick \
                cython3 \
                gdal-bin \
                libgdal1i \
                python3-gdal

#
# Build python-mapnik form source, since Mapnik's pip package only supports python2,
# and their official PPA is broken.  Hopefully this will be fixed in ubuntu-16.04
#
# WARNING: Very slow!!!, and memory hungry using GCC:
#   - 1~2 cores: 8GB
#   - 4~8 cores: 16GB
#   - >=16 cores: 32GB
#
# Requires freetype2.6 otherwise Google Noto CJK fonts don't get auto hinting.

WORKDIR     /tmp

ENV         FREETYPE_VERSION=VER-2-6-1 \
            MAPNIK_VERSION=v3.0.8

# Fixes https://github.com/mapnik/mapnik/issues/3090
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
                libwebp-dev \
                liblcms2-dev  \
                libjpeg-dev \
                libpng-dev \
                libwebp-dev \
                libtiff-dev \
                libproj-dev \
                libgeos-dev \
                libgdal-dev \
                libicu-dev \
                libharfbuzz-dev \
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
            && make -j `nproc` \
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
# Patch gdal data files, see:
#   https://launchpad.net/ubuntu/trusty/+source/gdal/+copyright
RUN         curl -SL http://cdn.masonmaps.me/dist/gdal-1.11.3/data/esri_extra.wkt > /usr/share/gdal/1.11/esri_extra.wkt

#
# Install latest Pillow
#
RUN         pip3 install --upgrade pillow

#
# Test mapnik and imagemagick
#
RUN         set -x \
            && echo 'import gdal; \
                import mapnik; \
                import PIL; \
                from pprint import pprint; \
                print("GDAL Version:"); \
                print(gdal.VersionInfo()); \
                print("Mapnik Version:"); \
                print(mapnik.mapnik_version()); \
                print("Mapnik Plugins:"); \
                pprint(list(mapnik.DatasourceCache.plugin_names())); \
                print("Pillow Version:"); \
                print(PIL.PILLOW_VERSION); \
                print("Pillow Plugins:"); \
                pprint(PIL._plugins);' > /tmp/test.py \
            && python3.5 /tmp/test.py \
            && convert --version \
            && rm /tmp/test.py

