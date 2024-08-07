#!/bin/bash

echo "Running teragen"

#trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

#MR_EXAMPLES_JAR=/usr/hdp/2.2.0.0-2041/hadoop-mapreduce/hadoop-mapreduce-examples.jar
MR_EXAMPLES_JAR=/opt/hadoop/hadoop-mapreduce-examples-2.7.1.jar

if [[ -z $SIZE ]] ; then
	SIZE=1G
	echo "Using 1G as default size"
fi

if [ $SIZE = "1M" ] ; then
	ROWS=10000
elif [ $SIZE = "10M" ] ; then
	ROWS=100000
elif [ $SIZE = "100M" ] ; then
	ROWS=1000000
elif [ $SIZE = "1G" ] ; then
	ROWS=10000000
elif [ $SIZE = "10G" ] ; then
	ROWS=100000000
else
	echo "Unknown size"
	exit 1
fi




#SIZE=500G
#ROWS=5000000000

#SIZE=100G
#ROWS=1000000000

#SIZE=1T
#ROWS=10000000000

#SIZE=10G
#ROWS=100000000

#SIZE=1G
#ROWS=10000000

#SIZE=100M
#ROWS=1000000

#SIZE=10M
#ROWS=100000

#SIZE=1M
#ROWS=10000


LOGDIR=logs

if [ ! -d "$LOGDIR" ]
then
    mkdir ./$LOGDIR
fi

echo "Creating tera folder"
bin/hdfs dfs -mkdir /tera
echo "hadoop ls /"
bin/hdfs dfs -ls /

DATE=`date +%Y-%m-%d:%H:%M:%S`

RESULTSFILE="./$LOGDIR/teragen_results_$DATE"


OUTPUT=/tera/${SIZE}-terasort-input

# teragen.sh
# Kill any running MapReduce jobs
#bin/mapred job -list | grep job_ | awk ' { system("mapred job -kill " $1) } '
#echo "bin/mapred job -list"
#bin/mapred job -list
# Delete the output directory
#echo "hadoop rm $OUTPUT"
#bin/hadoop fs -rm -r -f -skipTrash ${OUTPUT}

#-Dmapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.Lz4Codec

# Run teragen
echo "Running teragen"
timeout 60s bin/hadoop jar $MR_EXAMPLES_JAR teragen \
-Dmapreduce.map.log.level=INFO \
-Dmapreduce.reduce.log.level=INFO \
-Dyarn.app.mapreduce.am.log.level=INFO \
-Dio.file.buffer.size=131072 \
-Dmapreduce.map.cpu.vcores=1 \
-Dmapreduce.map.java.opts=-Xmx1536m \
-Dmapreduce.map.maxattempts=1 \
-Dmapreduce.map.memory.mb=2048 \
-Dmapreduce.map.output.compress=true \
-Dmapreduce.reduce.cpu.vcores=1 \
-Dmapreduce.reduce.java.opts=-Xmx1536m \
-Dmapreduce.reduce.maxattempts=1 \
-Dmapreduce.reduce.memory.mb=2048 \
-Dmapreduce.task.io.sort.factor=100 \
-Dmapreduce.task.io.sort.mb=384 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx768m \
-Dyarn.app.mapreduce.am.resource.mb=1024 \
-Dmapred.map.tasks=92 \
${ROWS} ${OUTPUT}
#>> $RESULTSFILE 2>&1

echo "Running teragen (done)"

echo "hadoop ls /"
bin/hdfs dfs -ls /

echo "hadoop ls /tera"
bin/hdfs dfs -ls /tera

echo "bin/mapred job -list"
bin/mapred job -list

#-Dmapreduce.map.log.level=TRACE \
#-Dmapreduce.reduce.log.level=TRACE \
#-Dyarn.app.mapreqduce.am.log.level=TRACE \

