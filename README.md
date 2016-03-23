# Stonemason Base Docker Image

Base image of `stonemason`, based on `debian:jessie`.
Custom built `mapnik` for possibly patching.

> Note: Build this image on a two core CPU requires at least 8G memory.

To reduce final image size use provided `squash.sh`, Download `docker-squash`
from: https://github.com/jwilder/docker-squash.  Note `docker-squash` does not
work under `docker-1.10`` later.

Tags:

- `mapnik3.0.9`: Python 2.7, Mapnik 3.0.9, Freetype 2.6.3, Harfbuzz 1.1.3
- `mapnik3.0.10`: Python 2.7, Mapnik 3.0.10, Freetype 2.6.3, Harfbuzz 1.2.1

