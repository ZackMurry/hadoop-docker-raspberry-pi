#!/bin/bash

addgroup hadoop
adduser --ingroup hadoop --gecos "" --disabled-password hduser
chpasswd <<< "hduser:mypassword"
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -P ""

mkdir -p /opt/hadoop/hdfs
mkdir /opt/hadoop/hdfs/namenode
chown hduser:hadoop -R /opt/hadoop

ls /root
cat bashrc_additions.sh >> /root/.bashrc
source /root/.bashrc


curl -L https://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz -O - | tar -xvz
ls

