#!/usr/bin/env bash

# Build image
docker build -t stonemason-base:mapnik3.0.9 debian

# See http://jasonwilder.com/blog/2014/08/19/squashing-docker-images/
docker save stonemason-base:mapnik3.0.9 | sudo TMPDIR=/var/run/shm docker-squash  -from root -t kotaimen/stonemason-base:mapnik3.0.9 -verbose | docker load