FROM        ubuntu-debootstrap:15.10
MAINTAINER  Kotaimen <kotaimen.c@gmail.com>

ENV         DEBIAN_FRONTEND noninteractive

#
# HACK: Speed AWS build by using local APT sources
#
RUN         set -x \
            && mv /etc/apt/sources.list /etc/apt/sources.list.back \
            && sed s/archive.ubuntu.com/ap-northeast-1.ec2.archive.ubuntu.com/ /etc/apt/sources.list.back > /etc/apt/sources.list

# Set locale
RUN         locale-gen en_US.UTF-8
ENV         LANG=en_US.UTF-8 \
            LANGUAGE=en_US:en \
            LC_ALL=en_US.UTF-8

# Deployment Packages
ENV         DEPLOY_PACKAGES \
                libcairo2 \
                libboost-filesystem1.58.0 \
                libboost-program-options1.58.0 \
                libboost-python1.58.0 \
                libboost-regex1.58.0 \
                libboost-system1.58.0 \
                libboost-thread1.58.0 \
                zlib1g \
                libwebp5 \
                liblcms2-2 \
                libjpeg62 \
                libpng3 \
                libtiff5 \
                libproj9 proj-bin proj-data \
                libgeos-3.5.0 \
                libgdal1i gdal-bin \
                libicu55 \
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
                python-pylibmc \
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
                libpq-dev \
                libxml2-dev

ENV         BUILD_DIR=/tmp/build \
            FREETYPE_VERSION=2.6.3 \
            HARFBUZZ_VERSION=1.1.3 \
            MAPNIK_VERSION=v3.0.9 \
            PYTHON_MAPNIK_VERSION=db7c1fdb2e970bdc93ab439119465fa5c0df3a07

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
            && curl -SL http://ftp.osuosl.org/pub/blfs/conglomeration/harfbuzz/harfbuzz-${HARFBUZZ_VERSION}.tar.bz2 | tar xfj - \
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
            && curl -SL http://mapnik.s3.amazonaws.com/dist/v3.0.9/mapnik-${MAPNIK_VERSION}.tar.bz2 | tar xfj - \
            && cd mapnik-${MAPNIK_VERSION} \
            && ./configure \
            && ./scons/scons.py --jobs=`nproc` \
            && make install

# Build python-manpik, which don't have release mangement, good luck!
RUN         set -x \
            && git clone https://github.com/mapnik/python-mapnik python-mapnik \
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
RUN         curl -SL http://cdn.masonmaps.me/dist/gdal-1.11.3/data/esri_extra.wkt > /usr/share/gdal/1.11/esri_extra.wkt

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
