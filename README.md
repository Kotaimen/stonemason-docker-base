# Stonemason Base Docker Image

Base image of `stonemason`, based on `debian:jessie`.
Custom built `mapnik` for possibly patching.

Warning:  Build this image on a two core CPU requires about 8G memory.

To reduce final image size use provided `squash.sh`.

Download `docker-squash` from: https://github.com/jwilder/docker-squash .


Tags:

- `mapnik3.0.9`: Python2.7, Mapnik+3.0.9, Freetype 2.6.1

