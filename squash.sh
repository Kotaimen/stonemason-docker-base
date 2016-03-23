#!/usr/bin/env bash

# Squash built images into a single layer, reduces image size.
# See http://jasonwilder.com/blog/2014/08/19/squashing-docker-images/

#
# Doesn't work under docker-1.10+
#

REPO_NAME=kotaimen
IMAGE_TAG=stonemason-base:mapnik3.0.10

docker pull debian:jessie

docker build -t ${IMAGE_TAG} debian
docker save ${IMAGE_TAG} | sudo TMPDIR=/dev/shm ../docker-squash -from $(docker images -q debian:jessie) -t ${REPO_NAME}/${IMAGE_TAG} -verbose | docker load
