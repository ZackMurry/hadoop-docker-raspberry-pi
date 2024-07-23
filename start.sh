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

mkdir /opt/hadoop/hdfs/$NODE_TYPE

cd /opt/hadoop

if [ "$NODE_TYPE" = "namenode" ] ; then
  echo "Starting namenode"
  bin/hdfs namenode -format
  sbin/start-dfs.sh
  sbin/start-yarn.sh
  bin/hdfs dfsadmin -report
fi

