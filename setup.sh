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


echo "/opt/hadoop/etc/hadoop/core-site.xml"
cat /opt/hadoop/etc/hadoop/core-site.xml

echo "/opt/hadoop/etc/hadoop/hdfs-site.xml"
cat /opt/hadoop/etc/hadoop/hdfs-site.xml

echo "/opt/hadoop/etc/hadoop/yarn-site.xml"
cat /opt/hadoop/etc/hadoop/yarn-site.xml

echo "/opt/hadoop/etc/hadoop/mapred-site.xml"
cat /opt/hadoop/etc/hadoop/mapred-site.xml

cd /opt/hadoop/etc/hadoop

echo "Inserting new files..."

mv /usr/src/app/core-site.xml .
mv /usr/src/app/hdfs-site.xml .
mv /usr/src/app/yarn-site.xml .
mv /usr/src/app/mapred-site.xml .

echo "/opt/hadoop/etc/hadoop/core-site.xml"
cat /opt/hadoop/etc/hadoop/core-site.xml

echo "/opt/hadoop/etc/hadoop/hdfs-site.xml"
cat /opt/hadoop/etc/hadoop/hdfs-site.xml

echo "/opt/hadoop/etc/hadoop/yarn-site.xml"
cat /opt/hadoop/etc/hadoop/yarn-site.xml

echo "/opt/hadoop/etc/hadoop/mapred-site.xml"
cat /opt/hadoop/etc/hadoop/mapred-site.xml


#echo "/opt/hadoop/etc/hadoop/hadoop-env.sh"
#cat /opt/hadoop/etc/hadoop/hadoop-env.sh

jav_test=$(readlink -f /usr/bin/java | sed "s:bin/java::")
echo $jav_test

sed -i -e "s:# export JAVA_HOME=:export JAVA_HOME=$jav_test:g" /opt/hadoop/etc/hadoop/hadoop-env.sh

echo "/opt/hadoop/etc/hadoop/hadoop-env.sh"
cat /opt/hadoop/etc/hadoop/hadoop-env.sh


cd /opt/hadoop
bin/hdfs namenode -format

# todo: namenode and datanode images

