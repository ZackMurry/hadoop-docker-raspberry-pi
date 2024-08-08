#!/bin/bash

trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

#MR_EXAMPLES_JAR=/opt/cloudera/parcels/CDH/jars/hadoop-mapreduce-examples-3.1.1.7.2.2.2-1.jar
MR_EXAMPLES_JAR=/opt/hadoop/hadoop-mapreduce-examples-2.7.1.jar


if [[ -z $SIZE ]] ; then
	echo "Using 1G as default size"
	SIZE=1G
fi


#SIZE=500G
#SIZE=100G
#SIZE=1M
#SIZE=1T
#SIZE=1G
#SIZE=10G
#INPUT=/${SIZE}-terasort-input
#OUTPUT=/${SIZE}-terasort-output


LOGDIR=logs

if [ ! -d "$LOGDIR" ]
then
    mkdir ./$LOGDIR
fi

DATE=`date +%Y-%m-%d:%H:%M:%S`

RESULTSFILE="./$LOGDIR/terasort_results_$DATE"

INPUT=/tera/${SIZE}-terasort-input
OUTPUT=/tera/${SIZE}-terasort-output

# terasort.sh
# Kill any running MapReduce jobs
# mapred job -list | grep job_ | awk ' { system("mapred job -kill " $1) } '
# Delete the output directory
bin/hadoop fs -rm -r -f -skipTrash ${OUTPUT}

#-Dmapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.Lz4Codec \
# Run terasort
time bin/hadoop jar $MR_EXAMPLES_JAR terasort \
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
-Dmapreduce.task.io.sort.factor=300 \
-Dmapreduce.task.io.sort.mb=384 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx768m \
-Dyarn.app.mapreduce.am.resource.mb=1024 \
-Dmapred.reduce.tasks=92 \
-Dmapreduce.terasort.output.replication=1 \
${INPUT} ${OUTPUT} >> $RESULTSFILE 2>&1

