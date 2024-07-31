#!/bin/bash
# Configure namenode/datanode

#set -Eeuo pipefail

#iperf3 -s

ifconfig

if [ ! -f /opt/hadoop/initialized ] ; then
  tar -xzf /usr/src/app/hadoop-3.4.0.tar.gz -C /opt

  ls /opt
  mv /opt/hadoop-3.4.0 /opt/hadoop

  mkdir -p /opt/hadoop/hdfs
  chown hduser:hadoop -R /opt/hadoop

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
  for node in $(echo $NODES | tr ";" "\n")
  do
      node_name=$(echo $node | cut -f1 -d:)
      node_ip=$(echo $node | cut -f2 -d:)
      echo "$node_name available at $node_ip"
      if [ "$node_name" != "$device_host" ] ; then
      #if [ "$node_type" != "namenode" -o  "$node_name" != "$device_host" ] ; then
        echo -e "$node_ip\t$node_name" >> /etc/hosts
      else
        echo -e "127.0.0.1\t$node_name" >> /etc/hosts
      fi
      if [ "$node_type" = "namenode" -a "$i" -ne 0 ] ; then
        echo "$node_name" >> /opt/hadoop/etc/hadoop/workers
      fi
      i=$((i+1))
  done

fi

# Todo: just refer to hosts using "master", "worker1", etc instead of ids


# Replace master with actual hostname in config.xml files
cd /opt/hadoop/etc/hadoop
if [ "$node_type" = "namenode" ] ; then
  #echo -e "127.0.0.1\t$hst" >> /etc/hosts
  #sed -i -e "s/master/0.0.0.0/g" core-site.xml
  sed -i -e "s/master/$hst/g" core-site.xml
  sed -i -e "s/master/$hst/g" yarn-site.xml
  sed -i -e "s/master/$hst/g" hdfs-site.xml
  sed -i -e "s/master/$hst/g" mapred-site.xml
else
  sed -i -e "s/master/$master_name/g" core-site.xml
  sed -i -e "s/master/$master_name/g" yarn-site.xml
  sed -i -e "s/master/$master_name/g" hdfs-site.xml
  sed -i -e "s/master/$master_name/g" mapred-site.xml
fi

echo "/etc/hosts"
cat /etc/hosts

echo "cat /opt/hadoop/etc/hadoop/workers"
cat /opt/hadoop/etc/hadoop/workers

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
      echo "Reversing ssh-copy-id..."
      (runuser -u hduser -- ssh -p 30022 -o StrictHostKeyChecking=accept-new hduser@$node_ip "cat .ssh/id_rsa.pub") | tee -a /home/hduser/.ssh/authorized_keys
    fi
    echo "cat /home/hduser/.ssh/authorized_keys"
    cat /home/hduser/.ssh/authorized_keys

  done
fi

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

if [ "$node_type" = "namenode" ] ; then
  if [ ! -f /opt/hadoop/initialized ] ; then
    echo "Formatting namenode"
    runuser -u hduser -- bin/hdfs namenode -format
  fi
  echo "/opt/hadoop/bin/hdfs getconf -namenodes"
  runuser -u hduser -- /opt/hadoop/bin/hdfs getconf -namenodes
  echo "/opt/hadoop/bin/hdfs getconf -confKey yarn.resourcemanager.ha.enabled"
  runuser -u hduser -- /opt/hadoop/bin/hdfs getconf -confKey yarn.resourcemanager.ha.enabled
  echo "Starting namenode"
  #bin/hdfs namenode
  echo "Starting dfs"
  timeout 60s runuser -u hduser -- bash -x sbin/start-dfs.sh || true
  netstat -tupan
  tail -n +1 /opt/hadoop/logs/*
  echo "Starting yarn"
  timeout 60s runuser -u hduser -- bash -x sbin/start-yarn.sh || true
  #echo "Manually starting YARN..."
  #/opt/hadoop/bin/yarn --config /opt/hadoop/etc/hadoop --daemon start resourcemanager
  echo "Waiting for yarn to start..."
  sleep 60s
  ls /opt/hadoop/logs
  tail -n +1 /opt/hadoop/logs/*
  netstat -tupan
  echo "Running jps..."
  jps
  echo "Generating report"
  runuser -u hduser -- bin/hdfs dfsadmin -report || true

else
  echo "Initialized data node"
fi

runuser -u hduser -- touch /opt/hadoop/initialized

i=0
while true
do
  echo "Staying active $i..."
  echo "Running jps..."
  jps
  netstat -tupan
  tail -n +1 /opt/hadoop/logs/*
  if [ $i -eq 5 ] ; then
    runuser -u hduser -- bash /opt/hadoop/bin/hdfs datanode
  fi
  i=$((i+1))
  sleep 60s
done
