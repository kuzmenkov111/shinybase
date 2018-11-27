#!/bin/sh
### In rserver.sh (make sure this file is chmod +x):
# `chpst -u xxxx` runs the given command as the user `xxxx`.
# If you omit that part, the command will be run as root.

exec chpst -u shiny /usr/bin/shiny-server  2>&1
