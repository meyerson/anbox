O---
layout: post
title: "anbox inception"
description: "using adocker to ship anbox
published: false
tags: linux android
---
# install


## build base docker images
    docker build -it local:base_anbox ./

## host os requirements?
kernel modules?
```bash
$ pacaur -Sy aur/anbox-modules-dkms-git
$ sudo modprobe ashmem_linux
$ sudo modprobe binder_linux
```

## opengl inside docker?
https://github.com/jamesbrink/docker-opengl
https://github.com/thewtex/docker-opengl

Where does this go? likely Makefile w/ host_prep.sh

## kernel modules on privileged container ?
https://forums.docker.com/t/consequence-of-instaling-kernel-modules-on-the-container/23186

You have to install *exactly* kernel modules that matches the host os's kernel, simpler to drive from the host side . . .

# use

## grab the android image somewhere

```bash
wget https://build.anbox.io/android-images/2018/06/11/android_amd64.img -O /mnt/store/android_images/android.img
```

#automation

# sources
https://github.com/anbox/anbox/issues/305



To run in the arch I first installed the system kernel headers for the DKMS.

"yaourt -s linux-headers" (I found the version compatible with my my kernel - 4.10.12-1-MANJARO)
Then I compiled the anbox with the following packages:

"aur/anbox-git"
"aur/anbox-image"
"aur/anbox-modules-dkms-git"
I started systemd networks services (for internet to work in apps)

"sudo systemctl start systemd-resolved.service"
"sudo systemctl start systemd-networkd.service"
And started the container-manager service

"sudo systemctl start anbox-container-manager.service"
I added the host driver in /usr/lib/systemd/user/anbox-session-manager.service by changing the line:

From "ExecStart=/usr/bin/anbox session-manager"
To "ExecStart=/usr/bin/anbox session-manager --gles-driver=host"
I started the user service:

"systemctl --user start anbox-session-manager.service"
Then it worked!


# Create a portable android via docker

load modules before compiling?
## host os
ashmem and binder

[cryosphere@sd_arch anbox]$ lsmod | grep bind
binder_linux          118784  60
[cryosphere@sd_arch anbox]$ lsmod | grep ashmem
ashmem_linux           16384  9


## build it

git clone here or docker pull this

## download a pre-build android image

wget https://build.anbox.io/android-images/2018/06/11/android_amd64.img


### run it

docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  --privileged  dmeyerson:anbox /bin/bash


docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  -v /mnt/store/android_images:/var/lib/anbox/ --privileged  dmeyerson:anbox /bin/bash

docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  -v /mnt/store/android_images:/var/lib/anbox/ --privileged  -v /tmp/.X11-unix:/tmp/.X11-unix dmeyerson:anbox /bin/bash

## sessopm ,
## GUI apps on docker
https://medium.com/@SaravSun/running-gui-applications-inside-docker-containers-83d65c0db110




##
# troubleshooting
### debug
docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  --privileged  dmeyerson:anbox /bin/bash run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  --privileged  -v /tmp/.X11-unix:/tmp/.X11-unix local:anbox /bin/bash




### access to kernel modules
root@22650413b559:/anbox/build# anbox session-manager
 2018-10-21 17:23:19] [session_manager.cpp:130@operator()] Failed to start as either binder or ashmem kernel drivers are not loaded

on the container - verify ashmem and binder
root@90b5b5028fd2:/anbox/build# anbox system-info | grep bind
  binder: false
root@90b5b5028fd2:/anbox/build# anbox system-info | grep ash 
  ashmem: false

make sure you are running with --privileged  flag and binder + ashmem are loaded in host OS

## runtime env issues
[cryosphere@sd_arch anbox]$ docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  --privileged  -v /tmp/.X11-unix:/tmp/.X11-unix local:anbox /bin/bash
root@sd_arch:/anbox/build# anbox session-manager
[ 2018-10-21 18:07:30] [daemon.cpp:61@Run] No runtime directory specified

reading https://github.com/anbox/anbox/issues/597
make sure the flag is present -e XDG_RUNTIME_DIR={} arg
attemped ad-hoc from w/in the container
root@sd_arch:/anbox/build# export XDG_RUNTIME_DIR=/run/user/1000 # sip same as hose os?


## socket error
[ 2018-10-21 18:13:17] [daemon.cpp:61@Run] Failed to connect to socket /run/anbox-container.socket: No such file or directory
reading https://github.com/anbox/anbox/issues/123
 indicates that we need to start the container manager first?

## current state
docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  -v /mnt/store/android_images:/var/lib/anbox/ --privileged -e XDG_RUNTIME_DIR=/run/user/1000 -e ANBOX_LOG_LEVEL='trace' local:anbox /bin/bash

anbox container-manager --daemon --privileged --data-path=/var/lib/anbox &

root@sd_arch:/anbox/build# anbox session-managerls
[ 2018-10-21 22:01:42] [Renderer.cpp:168@initialize] Using a surfaceless EGL context
[ 2018-10-21 22:01:42] [Renderer.cpp:251@initialize] Successfully initialized EGL
[ 2018-10-21 22:01:42] [service.cpp:41@Service] Successfully acquired DBus service name
[ 2018-10-21 22:01:42] [client.cpp:49@start] Failed to start container: Failed to start

 ## next 
 https://github.com/mviereck/x11docker


# current state
docker run -it --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw"  -v /mnt/store/android_images:/var/lib/anbox/ --privileged -e XDG_RUNTIME_DIR=/run/user/1000 -e ANBOX_LOG_LEVEL='trace' local:base_anbox /bin/bash 

# two layer build process
docker build -t local:base_anbox ./
docker build -t local:config_anbox -f ./Dockerfile_config ./


## to drive this whole thing once done
http://sikulix.com

## image building bug - seems to be all over the place
echo N | sudo tee /sys/module/overlay/parameters/metacopy