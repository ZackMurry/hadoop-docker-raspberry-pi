# Configure namenode/datanode

master_name=$(echo $NODES | cut -f1 -d:)
echo "Master name: $master_name"
echo "HOSTNAME"
hostname
echo "HOSTNAME"
this_name=$(hostname)

if [ "$master_name" -eq "$this_name" ] ; then
  node_type="namenode"  
else
  node_type="datanode"
fi

if [ ! -f /opt/hadoop/initialized ] ; then
  echo "Creating $this_name as $node_type"
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

if [ "$node_type" = "namenode" ] ; then
  if [ ! -f /opt/hadoop/initialized ] ; then
    bin/hdfs namenode -format
  fi
  echo "Starting namenode"
  sbin/start-dfs.sh
  sbin/start-yarn.sh
  bin/hdfs dfsadmin -report
elif [ "$node_type" = "datanode" ] ; then
  echo "Starting data node"
else
  echo "ERROR: Unknown node type $node_type"
  exit 1
fi


touch /opt/hadoop/initialized

