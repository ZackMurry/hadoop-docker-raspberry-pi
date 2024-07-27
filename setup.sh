#!/bin/bash

addgroup hadoop
adduser --ingroup hadoop --gecos "" --disabled-password hduser
chpasswd <<< "hduser:mypassword"
passwd -u hduser

mkdir -p /home/hduser/.ssh
chown hduser:hadoop /home/hduser/.ssh
runuser -u hduser -- ssh-keygen -t rsa -b 4096 -f /home/hduser/.ssh/id_rsa -P ""
runuser -u hduser -- chmod 700 /home/hduser/.ssh
runuser -u hduser -- chmod 644 /home/hduser/id_rsa.pub
runuser -u hduser -- chmod 600 /home/hduser/id_rsa
runuser -u hduser -- chmod 755 /home/hduser


#rc-update add sshd
#rc-status
#rc-service sshd start

sed -i -e "s/#Port 22/Port 30022/g" /etc/ssh/sshd_config
sed -i -e "s/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g" /etc/ssh/sshd_config
cat /etc/ssh/sshd_config
#runuser -u hduser -- ssh-keygen -A
echo "ls /etc/ssh"
ls /etc/ssh
echo "Creating ssh hostkey"
ssh-keygen -A
echo "ls /etc/ssh"
ls /etc/ssh

#rc-service sshd restart

ls /root
cat bashrc_additions.sh >> /root/.bashrc
cat bashrc_additions.sh >> /home/hduser/.bashrc
source /home/hduser/.bashrc

cd /usr/src/app

wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0-aarch64.tar.gz

