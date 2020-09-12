#!/bin/sh
mkdir -p /var/log/shiny-server
chown sergiobenito.sergiobenito /var/log/shiny-server
exec shiny-server >> /var/log/shiny-server.log 2>&1
