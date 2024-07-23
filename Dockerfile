FROM alpine:3.14

RUN apk update
RUN apk add --no-cache openssh
RUN apk --no-cache add openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

RUN addgroup hadoop
RUN adduser --ingroup hadoop hduser
RUN ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -P ""

RUN mkdir -p /opt/hadoop/hdfs
RUN mkdir /opt/hadoop/hdfs/namenode
RUN chown hduser:hadoop -R /opt/hadoop

RUN ls /root
RUN echo bashrc_additions.sh >> /root/.bashrc
RUN source /root/.bashrc

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . .

RUN wget https://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
RUN tar -xvzf hadoop-3.4.0.tar.gz -C /opt/
RUN mv /opt/hadoop-3.4.0 /opt/hadoop

CMD sleep infinity
