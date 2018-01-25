#!/usr/bin/env bash

function print_usage(){
  echo "Usage: newpost post_name post_type"
}

print_usage

if [ -n "$1" ]
then
  post_name=$1'.md'
else
  post_name='xxx.md'
fi

if [ -n "$2" ]
then
  type=$2
else
  type='xxx'
fi

date=`date +"%Y%m%d %H:%M:%S"`

content="---\nlayout: post\nauthor: sjf0115\ntitle: ${post_name}\ndate: ${date}\ntags:\n  - ${type}\n\ncategories: ${type}\n---"
cd source/_posts/
touch ${post_name}
echo -e ${content} > ${post_name}
