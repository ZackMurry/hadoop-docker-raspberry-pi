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



cd /opt/hadoop

if [ "$NODE_TYPE" = "namenode" ] ; then
  if [ -z $WORKER_IPS ] ; then
    echo "ERROR: No workers. Define WORKER_IPS in the format \"IP;IP;IP\""
    exit 1
  fi
  if [ ! -f /opt/hadoop/initialized ] ; then
    WORKER_IPS=${WORKER_IPS//;/$'\n'}  # change the semicolons to white space
    i=1
    echo "/opt/hadoop/etc/hadoop/workers"
    cat /opt/hadoop/etc/hadoop/workers
    for ip in $WORKER_IPS
    do
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
fi


touch /opt/hadoop/initialized

