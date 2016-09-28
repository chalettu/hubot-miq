#!/bin/bash  

DIR="/tmp/hubot_pull_requests/eslint"
CREDS=$1
REPO=$2
PR=$3

root_dir=`pwd`
echo $PWD
if [ -d $DIR ]; then
    rm -rf $DIR
fi
mkdir -p $DIR

cd $DIR
git clone https://$CREDS@github.com/$REPO .
git fetch origin pull/$PR/head:pr-$PR
git checkout pr-$PR

git diff --name-only `git merge-base origin/master HEAD` | grep '.js' | xargs $root_dir/node_modules/.bin/eslint --format json --config $DIR/.eslintrc.json --output-file /tmp/hubot_pull_requests/eslint_output.json
exit 0