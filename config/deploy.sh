#!/bin/sh

WEB=~/chat.reednj.com
SRC=~/code/chat.git
CONFIG=~/code/config_backup/redditstream

# copy the required files to the website
rm -rf $WEB/*
cp -R $SRC/* $WEB
cp $CONFIG/app.config.rb $WEB/config/

# create tmp directory
mkdir $WEB/tmp
mkdir $WEB/public

# restart the server
sudo -u www-data thin --config /etc/thin/chat.reednj.com.yml restart > $WEB/tmp/thin-restart.log &

echo "Website deployed"
