#!/bin/bash

addgroup hadoop
adduser --ingroup hadoop --gecos "" --disabled-password hduser
chpasswd <<< "hduser:mypassword"
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -P ""


ls /root
cat bashrc_additions.sh >> /root/.bashrc
source /root/.bashrc


wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
tar -xzf /usr/src/app/hadoop-3.4.0.tar.gz -C /opt

mv /opt/hadoop-3.4.0 /opt/hadoop

mkdir -p /opt/hadoop/hdfs
mkdir /opt/hadoop/hdfs/namenode
chown hduser:hadoop -R /opt/hadoop

cd /opt/hadoop

ls /opt/hadoop




