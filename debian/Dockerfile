FROM        debian:jessie
MAINTAINER  Kotaimen <kotaimen.c@gmail.com>

ENV         DEBIAN_FRONTEND noninteractive

#
# Packages to install
#
ENV         DEPLOY_PACKAGES \
                libcairo2 \
                libboost-filesystem1.55.0 \
                libboost-program-options1.55.0 \
                libboost-python1.55.0 \
                libboost-regex1.55.0 \
                libboost-system1.55.0 \
                libboost-thread1.55.0 \
                zlib1g \
                libwebp5 \
                liblcms2-2 \
                libjpeg62 \
                libpng3 \
                libtiff5 \
                libproj0 proj-bin proj-data \
                libgeos-c1 \
                libgdal1h gdal-bin \
                libicu52 \
#                libharfbuzz0b \
#                libfreetype6 \
                libsqlite3-0 \
                libmemcached11 \
                libpq5 \
                libxml2 \
                python \
                cython \
                python-dev \
                python-pip \
#                python-pil \
                python-numpy \
                python-scipy \
#                python-pylibmc \
                python-matplotlib \
#               python-skimage \
                python-gdal
                
ENV         DEVELOP_PACKAGES \
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
                liblcms2-dev \
                libjpeg-dev \
                libpng-dev \
                libtiff-dev \
                libproj-dev \
                libgeos-dev \
                libgdal-dev \
                libicu-dev \
#                libharfbuzz-dev \
#                libfreetype6-dev \
                libsqlite3-dev \
                libmemcached-dev \
                libpq-dev \
                libxml2-dev

# Packages as of 2016/3
ENV         BUILD_DIR=/tmp/build \
            FREETYPE_VERSION=2.6.3 \
            HARFBUZZ_VERSION=1.2.1 \
            MAPNIK_VERSION=v3.0.10 \
            PYTHON_MAPNIK_VERSION=275bfaec4f022322ba0fd8a64d9961838fe5b11e

# Install packages first
RUN         set -x \
            &&  apt-get -q update \
            &&  apt-get -yq --no-install-recommends install \
                locales\
                curl  \
                imagemagick \
                unzip \
                ${DEPLOY_PACKAGES} \
                ${DEVELOP_PACKAGES}

WORKDIR     ${BUILD_DIR}

# Build freetype
RUN         set -x \
            && curl -SL http://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.bz2 | tar xfj - \
            && cd freetype-${FREETYPE_VERSION} \
            && ./autogen.sh \
            && ./configure \
            && make -j `nproc` \
            && make install

# Build harfbuzz
RUN         set -x \
            && curl -SL https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-${HARFBUZZ_VERSION}.tar.bz2 | tar xfj - \
            && cd harfbuzz-${HARFBUZZ_VERSION} \
            && ./configure \
            && make -j `nproc` \
            && make install

# Build mapnik
# SLOW AND MEMORY HUNGARY
#   - 1~2 cores: 8GB
#   - 4   cores: 16GB
#   - 16  cores: 32GB
RUN         set -x \
            && curl -SL http://mapnik.s3.amazonaws.com/dist/${MAPNIK_VERSION}/mapnik-${MAPNIK_VERSION}.tar.bz2 | tar xfj - \
            && cd mapnik-${MAPNIK_VERSION} \
            && ./configure \
            && ./scons/scons.py --jobs=`nproc` \
            && make install

# Build python-manpik, which don't have release mangement, good luck!
RUN         set -x \
            && git clone --depth=64 https://github.com/mapnik/python-mapnik python-mapnik \
            && cd python-mapnik \
            && git checkout ${PYTHON_MAPNIK_VERSION} \
            && python setup.py install

# Update python pakcages with c binding
RUN         set -x \
            && curl -SL https://bootstrap.pypa.io/get-pip.py | python \
            && pip install --no-cache-dir \
                Cython>=0.19 \
                Pillow>=3.0.0 \
                pylibmc>=1.4.3 \
                numpy>=1.8.0 \
                scipy>=0.14.0 \
                scikit-image>=0.10.0

# Cleanup and remove develop packages
RUN         set -x \
            && apt-get -yq remove ${DEVELOP_PACKAGES} \
            && apt-get -yq autoremove \
            && apt-get -yq install libwebp-dev \
            && rm -rf /var/lib/apt/lists/* \
            && rm -rf ${BUILD_DIR}


#
# Patch gdal data files, see:
#   https://launchpad.net/ubuntu/trusty/+source/gdal/+copyright
RUN         curl -SL http://cdn.knrdesign.co/dist/gdal-1.11.3/data/esri_extra.wkt > /usr/share/gdal/1.10/esri_extra.wkt

#
# Set locale
#
RUN         set -x \
            && dpkg-reconfigure locales \
            && /usr/sbin/update-locale LANG=C.UTF-8 \
            && echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen \
            && locale-gen

ENV         LANG=en_US.UTF-8 \
            LANGUAGE=en_US:en \
            LC_ALL=en_US.UTF-8
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
            && python /tmp/test.py \
            && convert --version \
            && rm /tmp/test.py
