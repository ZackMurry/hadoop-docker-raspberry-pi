# Configure namenode/datanode

if [ -z $NODE_TYPE ] ; then
  echo "ERROR: NODE_TYPE not set"
  exit 1
fi

if [ -z $NODE_NAME ] ; then
  echo "ERROR: NODE_NAME not set"
  exit 1
fi


if [ ! -f /opt/hadoop/initialized ] ; then
  echo "Creating $NODE_NAME as $NODE_TYPE"
  mkdir /opt/hadoop/hdfs/$NODE_TYPE

fi

echo HOSTNAME
hostname
echo HOSTNAME


cd /opt/hadoop

if [ "$NODE_TYPE" = "namenode" ] ; then
  if [ -z $NODE_IPS ] ; then
    # First IP is host
    echo "ERROR: No workers. Define NODE_IPS in the format \"IP;IP;IP\""
    exit 1
  fi
  if [ ! -f /opt/hadoop/initialized ] ; then
    NODE_IPS=${NODE_IPS//;/$'\n'}  # change the semicolons to white space
    i=0
    echo "/opt/hadoop/etc/hadoop/workers"
    cat /opt/hadoop/etc/hadoop/workers
    for ip in $NODE_IPS
    do
        if [ "$i" -eq 0  ] ; then
          i=1
          continue
        fi
        echo "worker$i IP: $ip"
        echo "worker$i" >> /opt/hadoop/etc/hadoop/workers
        echo -e "$ip\tworker$i" >> /etc/hosts
        i=$((i+1))
    done
    cat /opt/hadoop/etc/hadoop/workers
    echo "/etc/hosts"
    cat /etc/hosts
    bin/hdfs namenode -format
  fi
  echo "Starting namenode"
  sbin/start-dfs.sh
  sbin/start-yarn.sh
  bin/hdfs dfsadmin -report
elif [ "$NODE_TYPE" = "datanode" ] ; then
  echo "Starting data node"
else
  echo "ERROR: Unknown node type $NODE_TYPE"
fi


touch /opt/hadoop/initialized

