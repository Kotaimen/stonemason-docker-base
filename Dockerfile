FROM        ubuntu:14.04
MAINTAINER  Kotaimen <kotaimen.c@gmail.com>

ENV         DEBIAN_FRONTEND noninteractive

#
# HACK: Speed local build by using local apt sources
#
# RUN         mv /etc/apt/sources.list /etc/apt/sources.list.back && \
#             sed s/archive.ubuntu.com/mirrors.aliyun.com/ /etc/apt/sources.list.back > /etc/apt/sources.list
# RUN         cat /etc/apt/sources.list


#
# Install binary packages
#
RUN         apt-get -q update && \
            apt-get -y install unzip curl \
                python-dev python-pip libz-dev \
                libjpeg-dev libtiff-dev libfreetype6-dev \
                libwebp-dev liblcms2-dev imagemagick \
                libproj-dev libgeos-dev \
                python-scipy python-numpy libgdal-dev gdal-bin python-gdal \
                libboost-all-dev libicu-dev \
                libfreetype6-dev libsqlite3-dev libpq-dev libxml2-dev \
                libmemcached-dev

#
# Patch gdal data files, see
#   https://launchpad.net/ubuntu/trusty/+source/gdal/+copyright
RUN         curl -SL http://cdn.masonmaps.me/dist/ubuntu-14.04/gdal-1.10.1/data/esri_extra.wkt > /usr/share/gdal/1.10/esri_extra.wkt

#
# Install mapnik
#
#WORKDIR     /tmp/
#RUN         curl -SL https://github.com/mapnik/mapnik/archive/2.3.x.zip > 2.3.x.zip && \
#            unzip 2.3.x.zip && \
#            cd /tmp/mapnik-2.3.x && \
#            ./scons/scons.py install --jobs=2 && \
#            rm -rf /tmp/mapnik-2.3.x


RUN         apt-get install -y software-properties-common && \
            add-apt-repository ppa:mapnik/nightly-2.3 && \
            apt-get update && \
            apt-get install -y libmapnik libmapnik-dev mapnik-utils python-mapnik \
                mapnik-input-plugin-gdal mapnik-input-plugin-ogr\
                mapnik-input-plugin-postgis \
                mapnik-input-plugin-sqlite \
                mapnik-input-plugin-osm


#
# Speedup pip by install "must have" python packages first
#
RUN         pip install awscli boto boto3 moto six futures \
                pillow flask gunicorn Click Shapely python-memcached \
                pylibmc nose coverage tox Cython Pygments alabaster \
                Sphinx sphinxcontrib-httpdomain \
                scikit-image

#
# Check installed software
#
RUN         geos-config --version && \
            echo && \
            ogrinfo --version && \
            echo && \
            ogrinfo --formats && \
            echo && \
            mapnik-config --version && \
            echo && \
            ls `python -c 'import mapnik; print mapnik.inputpluginspath'` && \
            echo && \
            convert --version && \
            echo && \
            convert rose: /tmp/rose.jpg && \
            convert rose: /tmp/rose.png && \
            convert rose: /tmp/rose.tiff && \
            convert rose: /tmp/rose.webp && \
            ls /tmp/rose.* && rm /tmp/rose*

