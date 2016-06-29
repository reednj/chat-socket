#!/bin/sh

WEB=~/asteroids.reednj.com
SRC=~/code/asteroids.git
CONFIG=~/code/config_backup/asteroids

# back up the log files
mkdir -p /tmp/asteroids.logs/
cp $WEB/log/* /tmp/asteroids.logs/

# copy the required files to the website
rm -rf $WEB/*
cp -R $SRC/* $WEB
cp $CONFIG/app.config.rb $WEB/config/

# copy back the log files
mkdir $WEB/tmp
mkdir $WEB/log
chgrp www-data $WEB/log
chmod 770 $WEB/log
mv /tmp/asteroids.logs/* $WEB/log/

chgrp www-data $WEB/log/*
chmod 660 $WEB/log/*

touch $WEB/payments.log
chmod 777 $WEB/payments.log

# restart the server
sudo -u www-data thin --config /etc/thin/asteroids.reednj.com.yml restart > $WEB/tmp/thin-restart.log &

echo "Website deployed"
