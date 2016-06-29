#!/bin/sh

cp post-receive.rb ../../.git/hooks/post-receive
chmod 711 ../../.git/hooks/post-receive

# this is required to make the pushing work properly
git config receive.denyCurrentBranch ignore