# Configure namenode/datanode

if [ -z $NODE_TYPE ] ; then
  echo "ERROR: NODE_TYPE not set"
  exit 1
fi

if [ -z $NODE_NAME ] ; then
  echo "ERROR: NODE_NAME not set"
  exit 1
fi


echo "Creating $NODE_NAME as $NODE_TYPE"

# Format: 192.168.1.0;192.168.1.1;IP;IP
WORKER_IPS=${WORKER_IPS//;/$'\n'}  # change the semicolons to white space
i=1
for ip in $WORKER_IPS
do
    echo "worker$i IP: $ip"
    i=$((i+1))
done

mkdir /opt/hadoop/hdfs/$NODE_TYPE

cd /opt/hadoop

if [ "$NODE_TYPE" = "namenode" ] ; then
  echo "Starting namenode"
  bin/hdfs namenode -format
  sbin/start-dfs.sh
  sbin/start-yarn.sh
  bin/hdfs dfsadmin -report
fi

