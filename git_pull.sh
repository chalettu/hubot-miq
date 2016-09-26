#!/bin/bash  

DIR="/tmp/hubot_pull_requests"
CREDS=$1
REPO=$2
PR=$3

if [ -d $DIR ]; then
    rm -rf $DIR/*
    rm -rf $DIR/.git
else
    mkdir $DIR
fi

cd $DIR
git clone https://$CREDS@github.com/$REPO .
git fetch origin pull/$PR/head:pr-$PR
git checkout pr-$PR

git diff --name-only `git merge-base origin/master HEAD` | grep '.rb' | xargs rubocop --format progress --format json --out rubocop.json