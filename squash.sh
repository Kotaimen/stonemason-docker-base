#!/usr/bin/env bash

REPO_NAME=kotaimen
IMAGE_TAG=stonemason-base:mapnik3.0.9

# Build image
docker pull debian:jessie
docker build -t ${IMAGE_TAG} debian

# Squash into a single layer, reduces image size
# See http://jasonwilder.com/blog/2014/08/19/squashing-docker-images/
docker save ${IMAGE_TAG} | sudo TMPDIR=/var/run/shm docker-squash  -from $(docker images -q debian:jessie) -t ${REPO_NAME}/${IMAGE_TAG} -verbose | docker load
