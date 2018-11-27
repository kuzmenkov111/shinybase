#!/bin/bash


set -e

if [ -f /etc/configured ]; then
        chown -R shiny:shiny /srv/shiny-server
        chown -R shiny:shiny /var/lib/shiny-server/bookmarks
        mkdir -p /var/log/shiny-server
        chown -R shiny:shiny /var/log/shiny-server
        echo 'already configured'
else
      #code that need to run only one time ....
      chown -R shiny:shiny /srv/shiny-server
      chown -R shiny:shiny /var/lib/shiny-server/bookmarks
      mkdir -p /var/log/shiny-server
      chown -R shiny:shiny /var/log/shiny-server
        #needed for fix problem with ubuntu and cron
      update-locale 
      date > /etc/configured
fi
