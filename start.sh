#!/bin/bash
# Configure namenode/datanode

#set -Eeuo pipefail
#iperf3 -s

ifconfig
echo "Hostname -i"
hostname -i

cni_ip=$(hostname -i | awk '{$1=$1;print}')
echo "\"$cni_ip\""

nohup iperf3 -s -p 30010 &
export HADOOP_ROOT_LOGGER=DEBUG,console

if [ ! -f /opt/hadoop/initialized ] ; then
  tar -xzf /usr/src/app/hadoop-3.4.0.tar.gz -C /opt

  ls /opt
  mv /opt/hadoop-3.4.0 /opt/hadoop

  mkdir -p /opt/hadoop/hdfs
  chown hduser:hadoop -R /opt/hadoop

  cd /opt/hadoop
  mv /usr/src/app/hadoop-mapreduce-examples-2.7.1.jar .
  mv /usr/src/app/teragen.sh .

  cd /opt/hadoop/etc/hadoop

  echo "Inserting new files..."

  mv /usr/src/app/core-site.xml .
  mv /usr/src/app/hdfs-site.xml .
  mv /usr/src/app/yarn-site.xml .
  mv /usr/src/app/mapred-site.xml .

  jav_test=$(readlink -f /usr/bin/java | sed "s:bin/java::")
  echo $jav_test

  sed -i -e "s:# export JAVA_HOME=:export JAVA_HOME=$jav_test:g" /opt/hadoop/etc/hadoop/hadoop-env.sh
  echo "export HADOOP_SSH_OPTS=\"-p 30022 -o StrictHostKeyChecking=accept-new\"" >> /opt/hadoop/etc/hadoop/hadoop-env.sh

  cd /opt/hadoop
  mv /usr/src/app/start-dfs.sh sbin
  chmod +x sbin/start-dfs.sh
  mv /usr/src/app/start-yarn.sh sbin
  chmod +x sbin/start-yarn.sh
  mv /usr/src/app/hdfs bin
  chmod +x bin/hdfs

  mkdir -p /home/hduser/.ssh
  chown hduser:hadoop /home/hduser/.ssh
  runuser -u hduser -- ssh-keygen -t rsa -b 4096 -f /home/hduser/.ssh/id_rsa -P ""
  runuser -u hduser -- touch /home/hduser/.ssh/authorized_keys
  #echo "ls -la /home/hduser/.ssh"
  runuser -u hduser -- ls -la /home/hduser/.ssh
  runuser -u hduser -- chmod 700 /home/hduser/.ssh
  runuser -u hduser -- chmod 644 /home/hduser/.ssh/id_rsa.pub
  runuser -u hduser -- chmod 644 /home/hduser/.ssh/authorized_keys
  runuser -u hduser -- chmod 600 /home/hduser/.ssh/id_rsa
  runuser -u hduser -- chmod 600 /home/hduser/.ssh/id_rsa
  runuser -u hduser -- chmod 755 /home/hduser
  #echo "ls -la /home/hduser/.ssh"
  #runuser -u hduser -- ls -la /home/hduser/.ssh



  sed -i -e "s/#Port 22/Port 30022/g" /etc/ssh/sshd_config
  sed -i -e "s/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g" /etc/ssh/sshd_config
  sed -i -e "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  sed -i -e "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
  #cat /etc/ssh/sshd_config
  #runuser -u hduser -- ssh-keygen -A
  #echo "ls /etc/ssh"

  #ls /etc/ssh
  #echo "Creating ssh hostkey"
  ssh-keygen -A
  #echo "ls /etc/ssh"
  #ls /etc/ssh

fi

cd /opt/hadoop

#echo "/opt/hadoop/etc/hadoop/hadoop-env.sh"
#cat /opt/hadoop/etc/hadoop/hadoop-env.sh

if [ -z $FLOTO_DEVICE_UUID ] ; then
  echo "ERROR: Expected FLOTO_DEVICE_UUID to be defined"
  exit 1
fi

device_host="${FLOTO_DEVICE_UUID:0:7}"
echo "Device host: $device_host"
master_name=$(echo $NODES | cut -f1 -d:)
echo "Master name: $master_name"
master_ip=$(echo $NODES | cut -f1 -d';' | cut -f2 -d:)
echo "Master ip: $master_ip"
hst=$(hostname)
echo "Hostname: $hst"

if [ "$master_name" = "$device_host" ] ; then
  node_type="namenode"  
else
  node_type="datanode"
fi

if [ ! -f /opt/hadoop/initialized ] ; then
  echo "Creating $device_host as $node_type"
  runuser -u hduser -- mkdir /opt/hadoop/hdfs/$node_type

  if [ -z $NODES ] ; then
    # First IP is master
    echo "ERROR: No nodes defined. Define NODES in the format \"HOSTNAME:IP;HOSTNAME:IP;HOSTNAME:IP\""
    exit 1
  fi
  NODES=${NODES//;/$'\n'}  # change the semicolons to white space
  i=0
  #echo "/opt/hadoop/etc/hadoop/workers"
  #cat /opt/hadoop/etc/hadoop/workers
  runuser -u hduser -- rm /opt/hadoop/etc/hadoop/workers
  runuser -u hduser -- touch /opt/hadoop/etc/hadoop/workers
  #echo "$cni_ip" >> /opt/hadoop/etc/hadoop/workers
  for node in $(echo $NODES | tr ";" "\n")
  do
      node_name=$(echo $node | cut -f1 -d:)
      node_ip=$(echo $node | cut -f2 -d:)
      echo "$node_name available at $node_ip"
      #if [ "$node_name" != "$device_host" ] ; then
      #if [ "$node_type" != "namenode" -o  "$node_name" != "$device_host" ] ; then
      #echo -e "$node_ip\t$node_name" >> /etc/hosts
      #else
      #  echo -e "127.0.0.1\t$node_name" >> /etc/hosts
      #fi
      if [ "$node_type" = "namenode" -a "$i" -ne 0 ] ; then
        echo -e "$node_ip\t$node_name" >> /etc/hosts
        #echo "$node_ip" >> /opt/hadoop/etc/hadoop/workers
      fi
      i=$((i+1))
  done

fi

# Todo: just refer to hosts using "master", "worker1", etc instead of ids


#runuser -u hduser -- sed -i -e "s/# quorumjournal nodes (if any)/exit 0/g" /opt/hadoop/start-dfs.sh
#cat /opt/hadoop/start-dfs.sh


cd /opt/hadoop

#ls -R /home/hduser/.ssh
#echo "ls /etc/ssh"
#ls /etc/ssh

chown hduser:hadoop /home/hduser/.ssh
chmod 700 /home/hduser/.ssh
chmod 644 /home/hduser/.ssh/id_rsa.pub
chmod 600 /home/hduser/.ssh/id_rsa
chmod 755 /home/hduser

# Start SSHd on port 30022
mkdir -p /run/sshd
chmod 755 /run/sshd
#/usr/sbin/sshd -p 30022 -d > /home/hduser/sshd_log.txt 2>&1 &
/usr/sbin/sshd -p 30022

echo "ls -la /home/hduser/.ssh"
runuser -u hduser -- ls -la /home/hduser/.ssh

if [ ! -f /opt/hadoop/initialized ] ; then
  found_self=0
  for node in $(echo $NODES | tr ";" "\n")
  do
    node_name=$(echo $node | cut -f1 -d:)
    if [ "$found_self" -eq 0 -a "$node_name" != "$device_host" ] ; then
      echo "Skipping ssh-copy-id for $node_name because it starts after this node"
      continue
    fi
    found_self=1
    node_ip=$(echo $node | cut -f2 -d:)
    #echo "Testing password SSH"
    #runuser -u hduser -- sshpass -p "mypassword" ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip ls /
    echo "Manually sharing SSH key with hduser@$node_ip on $node_name"
    cat /home/hduser/.ssh/id_rsa.pub | runuser -u hduser -- sshpass -p "mypassword" ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip 'cat >> /home/hduser/.ssh/authorized_keys'
    #runuser -u hduser -- sshpass -p "mypasssword" ssh-copy-id -i /home/hduser/.ssh/id_rsa.pub -p 30022 hduser@$node_ip
    #echo "ls -la /home/hduser/.ssh"
    #runuser -u hduser -- ls -la /home/hduser/.ssh
    echo "cat /home/hduser/.ssh/authorized_keys"
    runuser -u hduser -- cat /home/hduser/.ssh/authorized_keys
    if [ "$node_name" != "$device_host" ] ; then
      echo "iperf3 -c $node_name -p 30010"
      iperf3 -c $node_name -p 30010
      echo "Reversing ssh-copy-id..."
      (runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "cat .ssh/id_rsa.pub") | tee -a /home/hduser/.ssh/authorized_keys
    fi
    echo "cat /home/hduser/.ssh/authorized_keys"
    cat /home/hduser/.ssh/authorized_keys

  done
  #if false ; then
  if [ "$node_type" = "namenode" ] ; then
    echo "Setting up CNI IPs"
    #echo "Testing 10.188.0.241"
    #runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@10.188.0.241 "hostname && hostname -i"
    #echo "Testing 10.188.2.111"
    #runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@10.188.2.111 "hostname && hostname -i"
    for node in $(echo $NODES | tr ";" "\n")
    do
      node_name=$(echo $node | cut -f1 -d:)
      node_ip=$(echo $node | cut -f2 -d:)
      if [ "$node_name" = "$device_host" ] ; then
        echo "Skipping namenode"
        continue
      fi
      echo "Sharing with $node_name at $node_ip"
      runuser -u hduser -- echo $node_ip
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "sed -i -e \"s/$master_name/$cni_ip/g\" /opt/hadoop/etc/hadoop/*.xml"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "cat /opt/hadoop/etc/hadoop/core-site.xml"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "hostname"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "hostname -i"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "hostname -i" | awk '{$1=$1;print}' >> /opt/hadoop/etc/hadoop/workers
      node_cni_ip=$(runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "hostname -i" | awk '{$1=$1;print}')
      echo "Testing SSH to CNI IP $node_cni_ip"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_cni_ip "hostname"
    done
    echo "cat /opt/hadoop/etc/hadoop/workers"
    cat /opt/hadoop/etc/hadoop/workers
  fi 
fi

# Replace master with actual hostname in config.xml files
cd /opt/hadoop/etc/hadoop
#if [ "$node_type" = "namenode" ] ; then
#  #sed -i -e "s/master/0.0.0.0/g" core-site.xml
#  sed -i -e "s/master/$hst/g" core-site.xml
#  sed -i -e "s/master/$hst/g" yarn-site.xml
#  sed -i -e "s/master/$hst/g" hdfs-site.xml
#  sed -i -e "s/master/$hst/g" mapred-site.xml
#else
  #sed -i -e "s/master/$master_ip/g" core-site.xml
  #sed -i -e "s/master/$master_ip/g" yarn-site.xml
  #sed -i -e "s/master/$master_ip/g" hdfs-site.xml
  #sed -i -e "s/master/$master_ip/g" mapred-site.xml
echo -e "127.0.0.1\t$hst" >> /etc/hosts
sed -i -e "s/master/$master_name/g" core-site.xml
sed -i -e "s/master/$master_name/g" yarn-site.xml
sed -i -e "s/master/$master_name/g" hdfs-site.xml
sed -i -e "s/master/$master_name/g" mapred-site.xml
#fi

echo "/etc/hosts"
cat /etc/hosts

echo "cat /opt/hadoop/etc/hadoop/workers"
cat /opt/hadoop/etc/hadoop/workers


cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys

echo "cat /home/hduser/.ssh/authorized_keys"
cat /home/hduser/.ssh/authorized_keys

#ls -la /home/hduser/.ssh

echo "Restarting sshd"
killall -9 sshd
/usr/sbin/sshd -p 30022

echo "Testing SSH to localhost"
runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@localhost "cat /etc/hostname"
echo "Testing SSH to nodes"
found_self=0
for node in $(echo $NODES | tr ";" "\n")
do
  node_name=$(echo $node | cut -f1 -d:)
  if [ "$found_self" -eq 0 -a "$node_name" != "$device_host" ] ; then
    echo "Skipping SSH test for $node_name"
    continue
  fi
  found_self=1
  echo "Connecting to $node_name"
  runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_name "cat /etc/hostname"
done
echo "Testing SSH to nodes (done)"

#echo "cat /home/hduser/sshd_log.txt"
#cat /home/hduser/sshd_log.txt

source /home/hduser/.bashrc

export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
echo "Set JAVA_HOME to $JAVA_HOME"
export HADOOP_HOME=/opt/hadoop
export HADOOP_INSTALL=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export PATH=$PATH:$HADOOP_INSTALL/bin
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"

runuser -u hduser -- mkdir -p /opt/hadoop/logs
runuser -u hduser -- mkdir -p /opt/hadoop/tmp

cd /opt/hadoop

if [ "$node_type" = "namenode" ] ; then
  if [ ! -f /opt/hadoop/initialized ] ; then
    echo "Formatting namenode"
    timeout 60s runuser -u hduser -- bin/hdfs namenode -format --loglevel DEBUG
    echo "ls -la /opt/hadoop/hdfs/namenode"
    ls -la /opt/hadoop/hdfs/namenode
  fi
  #echo "/opt/hadoop/bin/hdfs getconf -namenodes"
  #runuser -u hduser -- /opt/hadoop/bin/hdfs getconf -namenodes
  #echo "/opt/hadoop/bin/hdfs getconf -confKey yarn.resourcemanager.ha.enabled"
  #runuser -u hduser -- /opt/hadoop/bin/hdfs getconf -confKey yarn.resourcemanager.ha.enabled
  #echo "/opt/hadoop/bin/hdfs getconf -secondarynamenodes"
  #runuser -u hduser -- /opt/hadoop/bin/hdfs getconf -secondarynamenodes
  echo "Starting namenode"
  #bin/hdfs namenode
  echo "Starting dfs"
  #timeout 60s runuser -u hduser -- bash -x sbin/start-dfs.sh || true

  echo "Starting dfs namenode"
  #runuser -u hduser -- /opt/hadoop/bin/hdfs --daemon start namenode
  runuser -u hduser -- /opt/hadoop/bin/hdfs namenode
  tail -n +1 /opt/hadoop/logs/*

  echo "Starting dfs datanode"
  cat /opt/hadoop/etc/hadoop/workers | while read line
  do
    echo "\"$line\""
    if [[ -n "$line" ]] ; then
      echo "Not empty... SSHing into $line"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$line "hostname"
      runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$line "/opt/hadoop/bin/hdfs --daemon start datanode"
    fi
  done


  netstat -tupan

  echo "Starting yarn"
  timeout 60s runuser -u hduser -- bash -x sbin/start-yarn.sh || true
  #echo "Manually starting YARN..."
  #/opt/hadoop/bin/yarn --config /opt/hadoop/etc/hadoop --daemon start resourcemanager
  runuser -u hduser -- bin/hdfs dfsadmin -safemode leave
  echo "Waiting for yarn to start..."
  sleep 60s
  ls /opt/hadoop/logs
  tail -n +1 /opt/hadoop/logs/*
  netstat -tupan
  echo "Running jps..."
  jps
  echo "Generating report"
  timeout 60s runuser -u hduser -- bin/hdfs dfsadmin -report || true

  echo "cat /opt/hadoop/err.msg"
  cat /opt/hadoop/err.msg

  echo "Testing ssh to ara.zackmurry.com"
  echo "$SSH_PASS" | runuser -u hduser -- sshpass ssh -p 443 zack@ara.zackmurry.com ls /

  echo "Starting reverse ssh"
  echo "$SSH_PASS" | runuser -u hduser -- sshpass ssh -R 30022:localhost:30022 -p 443 zack@ara.zackmurry.com

  echo "Starting teragen with SIZE=1M"
  date
  SIZE=1M runuser -u hduser -- bash /opt/hadoop/teragen.sh
  date

else
  echo "Initialized data node"
  runuser -u hduser -- ls -l /opt/hadoop/hdfs
  runuser -u hduser -- ls -l /opt/hadoop/hdfs/datanode
  chown -R hduser /opt/hadoop/hdfs/datanode
  chgrp -R hadoop /opt/hadoop/hdfs/datanode
fi

runuser -u hduser -- touch /opt/hadoop/initialized

i=0
while true
do
  echo "Staying active $i..."
  echo "Running jps..."
  jps
  lsof -nP -iTCP -sTCP:LISTEN
  echo "ps -a"
  ps -a
  tail -n +1 /opt/hadoop/logs/*
  cat /opt/hadoop/etc/hadoop/core-site.xml
  if [ "$node_type" = "namenode" ] ; then
    #echo "Trying telnet to 127.0.0.1:30001"
    #timeout 5s telnet 127.0.0.1 30001
    #echo "Trying telnet to $master_ip:30001"
    #timeout 5s telnet $master_ip 30001
    #echo "Trying telnet to $cni_ip:30001"
    #timeout 5s telnet $master_ip 30001
    echo "Generating report"
    timeout 60s runuser -u hduser -- bin/hdfs dfsadmin -report || true
  else
    echo "Trying telnet to $master_ip:30001"
    timeout 5s telnet $master_ip 30001
  fi
  i=$((i+1))
  sleep 60s
done
