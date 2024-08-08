#!/bin/bash

cat /opt/hadoop/etc/hadoop/workers | while read line
do
  echo "\"$line\""
done

