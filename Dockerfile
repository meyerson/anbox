#!/bin/sh
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y \
        build-essential \
        cmake \
        cmake-data \
        cmake-extras \
        debhelper \
        dbus \
        dbus-x11 \
        git \
        google-mock \
        libboost-dev \
        libboost-filesystem-dev \
        libboost-log-dev \
        libboost-iostreams-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-test-dev \
        libboost-thread-dev \
        libcap-dev \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        libglib2.0-dev \
        libglm-dev \
        libgtest-dev \
        liblxc1 \
        libproperties-cpp-dev \
        libprotobuf-dev \
        libsdl2-dev \
        libsdl2-image-dev \
        libsystemd-dev \
        lxc-dev \
        pkg-config \
        protobuf-compiler \
        iproute2 \
        iptables \
        kmod \
        x11-apps \
        software-properties-common \
        libpam-cgfs=3.0.1-0ubuntu1~18.04.2 
    # apt-get clean

WORKDIR /anbox

COPY . /anbox
RUN mkdir build || rm -rf build/*
RUN ls
WORKDIR /anbox/build
RUN cmake ..
RUN VERBOSE=1 make -j10
RUN VERBOSE=1 make test
RUN make install 
ENV ANBOX_LOG_LEVEL='trace'
WORKDIR /anbox