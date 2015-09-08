FROM        ubuntu:14.04
MAINTAINER  Kotaimen <kotaimen.c@gmail.com>

ENV         DEBIAN_FRONTEND noninteractive

#
# HACK: Speed local build by using local apt sources
#
# RUN         mv /etc/apt/sources.list /etc/apt/sources.list.back && \
            # sed s/archive.ubuntu.com/ap-northeast-1.ec2.archive.ubuntu.com/ /etc/apt/sources.list.back > /etc/apt/sources.list
# RUN         cat /etc/apt/sources.list


#
# Set locale
#
RUN         locale-gen en_US.UTF-8
ENV         LANG en_US.UTF-8
ENV         LANGUAGE en_US:en
ENV         LC_ALL en_US.UTF-8

#
# Install binary packages
#
RUN         apt-get -qq update && \
            apt-get install -yq software-properties-common && \
            add-apt-repository ppa:mapnik/nightly-2.3 && \
            apt-get -q update && \
            apt-get -yq install curl \
                imagemagick \
                python-dev python-pip python-pil cython \
                python-scipy python-numpy python-matplotlib \
                libz-dev libfreetype6-dev libharfbuzz-dev \
                gdal-bin python-gdal \
                libmemcached-dev \
                libmapnik mapnik-utils python-mapnik \
                mapnik-input-plugin-gdal \
                mapnik-input-plugin-ogr \
                mapnik-input-plugin-postgis \
                mapnik-input-plugin-sqlite \
                mapnik-input-plugin-osm

#
# Patch gdal data files, see
#   https://launchpad.net/ubuntu/trusty/+source/gdal/+copyright
RUN         curl -SL http://cdn.masonmaps.me/dist/ubuntu-14.04/gdal-1.10.1/data/esri_extra.wkt > /usr/share/gdal/1.10/esri_extra.wkt

#
# Speedup pip by install "must have" python packages first
#
RUN         pip install awscli boto moto six futures \
                flask gunicorn Click pylibmc nose shapely \
                scikit-image 
# RUN         pip list

#
# Check installed software
#
RUN         echo GDAL Version: && \
            python -c 'import gdal; print(gdal.VersionInfo())' && \
            echo Mapnik Plugins: && \
            ls `python -c 'import mapnik; print(mapnik.inputpluginspath);'` && \
            echo Mapnik Version && \
            python -c 'import mapnik; print(mapnik.mapnik_version())' && \
            echo Imagemagick: && \
            convert --version && \
            echo PIL/Pillow Version:&& \
            python -c 'import Image; print(Image.VERSION, Image.PILLOW_VERSION)' &&\
            convert rose: /tmp/rose.jpg && \
            convert rose: /tmp/rose.png && \
            convert rose: /tmp/rose.webp && \
            rm /tmp/rose*

