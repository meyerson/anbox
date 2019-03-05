#!/usr/bin/env bash
service dbus start
anbox container-manager --daemon --privileged --data-path=/var/lib/anbox &
/anbox/scripts/anbox-bridge.sh start
export $(dbus-launch)
export XDG_RUNTIME_DIR=/run/user/1000
anbox session-manager & 
#/bin/sleep 10
anbox launch --package=org.anbox.appmgr --component=org.anbox.appmgr.AppViewActivity
exec "$@"