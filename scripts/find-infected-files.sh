#!/bin/bash

# https://medium.com/@chapuyj/fixing-thousands-of-swiftlint-violations-over-time-436691001633

cd ..

current_pwd=`pwd`
escaped_pwd=$(echo "$current_pwd" | sed 's/\//\\\//g')

# run swiftlint, grep to filter only lines with .swift, sed to extract paths, sort to group paths, sed to remove first slash, sed to add

swiftlint | grep .swift: | sed 's/^\([^:]*\):.*/\1/' | sort -u | sed "s/$escaped_pwd//" | sed 's/^\///' | sed 's/\(.*\)/- \1/'
