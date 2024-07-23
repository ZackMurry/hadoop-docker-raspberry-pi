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
      if [ "$NODE_TYPE" = "namenode" -a "$i" -ne 0 ] ; then
        echo "$node_name" >> /opt/hadoop/etc/hadoop/workers
      fi
      i=$((i+1))
  done
  cat /opt/hadoop/etc/hadoop/workers
  echo "/etc/hosts"
  cat /etc/hosts

fi

cd /opt/hadoop

if [ "$NODE_TYPE" = "namenode" ] ; then
  if [ ! -f /opt/hadoop/initialized ] ; then
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
  exit 1
fi


touch /opt/hadoop/initialized

