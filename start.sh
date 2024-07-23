# Configure namenode/datanode

if [ -z $FLOTO_DEVICE_UUID ] ; then
  echo "ERROR: Expected FLOTO_DEVICE_UUID to be defined"
  exit 1
fi

device_host="${FLOTO_DEVICE_UUID:0:7}"
echo "Device host: $device_host"

master_name=$(echo $NODES | cut -f1 -d:)
echo "Master name: $master_name"

if [ "$master_name" = "$device_host" ] ; then
  node_type="namenode"  
else
  node_type="datanode"
fi

if [ ! -f /opt/hadoop/initialized ] ; then
  echo "Creating $device_host as $node_type"
  mkdir /opt/hadoop/hdfs/$node_type

  if [ -z $NODES ] ; then
    # First IP is master
    echo "ERROR: No nodes defined. Define NODE in the format \"HOSTNAME:IP;HOSTNAME:IP;HOSTNAME:IP\""
    exit 1
  fi
  NODES=${NODES//;/$'\n'}  # change the semicolons to white space
  i=0
  echo "/opt/hadoop/etc/hadoop/workers"
  cat /opt/hadoop/etc/hadoop/workers
  for node in $(echo $NODES | tr ";" "\n")
  do
      node_name=$(echo $node | cut -f1 -d:)
      node_ip=$(echo $node | cut -f2 -d:)
      echo "$node_name available at $node_ip"
      echo -e "$node_ip\t$node_name" >> /etc/hosts
      if [ "$node_type" = "namenode" -a "$i" -ne 0 ] ; then
        echo "$node_name" >> /opt/hadoop/etc/hadoop/workers
      fi
      i=$((i+1))
  done
  cat /opt/hadoop/etc/hadoop/workers
  echo "/etc/hosts"
  cat /etc/hosts

fi

cd /opt/hadoop




ls -R ~/.ssh

chmod 700 ~/.ssh
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa
chmod 755 /home/hduser

# Start SSHd on port 30022
mkdir -p /run/sshd && chmod 755 /run/sshd
/usr/sbin/sshd

echo "Waiting for other servers to come online..."
sleep 60s

if [ ! -f /opt/hadoop/initialized ] ; then
  for node in $(echo $NODES | tr ";" "\n")
  do
      node_name=$(echo $node | cut -f1 -d:)
      node_ip=$(echo $node | cut -f2 -d:)
      echo "Sharing SSH key with hduser@$node_ip on $node_name"
    echo "mypassword" | sshpass ssh-copy-id -f -i ~/.ssh/id_rsa.pub hduser@$node_ip
  done
fi

if [ "$node_type" = "namenode" ] ; then
  if [ ! -f /opt/hadoop/initialized ] ; then
    bin/hdfs namenode -format
  fi
  echo "Starting namenode"
  sbin/start-dfs.sh
  sbin/start-yarn.sh
  bin/hdfs dfsadmin -report
else
  echo "Initialized data node"
fi

touch /opt/hadoop/initialized

