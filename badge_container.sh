#!/bin/bash
topdir=`git rev-parse --show-toplevel`
status=$?

if [ $status -eq 127 ]; then
  echo "This script requires git, please install and try again"
  exit 1
elif [ $status -ne 0 ]; then
  exit 1
fi

workdir=`pwd | sed "s+$topdir++g"`
docker run --rm -it --privileged -v "$topdir":/app -w "/app/$workdir" hadbadge "$@"
