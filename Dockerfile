FROM        ubuntu-debootstrap:15.10
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
            &&  apt-get -yq --no-install-recommends install \
                curl \
                unzip \
                python \
                cython \
                python-dev \
                python-pip \
                python-scipy \
                python-numpy \
                python-pylibmc \
                python-gdal \
                libwebp5 \
                libpng3 \
                libjpeg62 \
                libtiff5 \
                imagemagick \
                gdal-bin \
                proj-bin \
                libgdal1i

#
# Build python-mapnik form source, since Mapnik's pip package only supports python2,
# and their official PPA is broken.  Hopefully this will be fixed in ubuntu-16.04
#
# WARNING: Very slow!!! Plus memory hungry using GCC:
#   - 1~2 cores: 8GB
#   - 4   cores: 16GB
#   - 16  cores: 32GB
#
# Requires freetype2.6 otherwise Google Noto CJK fonts don't get auto hinting.

WORKDIR     /tmp/build

ENV         FREETYPE_VERSION=VER-2-6-1 \
            MAPNIK_VERSION=v3.0.9

# Fixes https://github.com/mapnik/mapnik/issues/3090
#COPY        3090-fix.diff ./

RUN         set -x \
            && apt-get -yq install --no-install-recommends \
                build-essential \
                make \
                automake \
                pkg-config \
                libtool \
                git \
                python-cairo-dev \
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
                libxml2-dev

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
            && ./configure \
            && ./scons/scons.py --jobs=`nproc` \
            && make install \

            && git clone https://github.com/mapnik/python-mapnik python-mapnik \
            && cd python-mapnik \
            && python setup.py install \
            && rm -rf /tmp/*

WORKDIR     /root

#
# Patch gdal data files, see:
#   https://launchpad.net/ubuntu/trusty/+source/gdal/+copyright
RUN         curl -SL http://cdn.masonmaps.me/dist/gdal-1.11.3/data/esri_extra.wkt > /usr/share/gdal/1.11/esri_extra.wkt

#
# Install latest Pillow & skimage.
#   In 15.10 python3 is python3.4 but pip3 installs to python3.5 instead
#
RUN         python -m pip install --upgrade pillow scikit-image
#Dockerfile
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
            && python /tmp/test.py \
            && convert --version \
            && rm /tmp/test.py

