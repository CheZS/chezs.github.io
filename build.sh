#!/bin/sh

hexo generate
cp -R public/* .deploy/chezs.github.io
cd .deploy/chezs.github.io
git add .
git commit -m "update"
git push origin master
