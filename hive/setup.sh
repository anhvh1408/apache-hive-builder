#!/usr/bin/env bash

if [[ -z ${HIVE_BIN_VERSION} ]] || [[ -z $HADOOP_BIN_VERSION ]]; then
  echo hadoop and hive bin version required
  exit 1;
fi;

if [[ ! -f /tmp/hive/apache-hive-${HIVE_BIN_VERSION}-bin.tar.gz ]];
then
  curl -o /tmp/hive/apache-hive-${HIVE_BIN_VERSION}-bin.tar.gz https://downloads.apache.org/hive/hive-${HIVE_BIN_VERSION}/apache-hive-${HIVE_BIN_VERSION}-bin.tar.gz
fi;
if [[ ! -f /tmp/hive/hadoop-${HADOOP_BIN_VERSION}.tar.gz ]];
then
  curl -o /tmp/hive/hadoop-${HADOOP_BIN_VERSION}.tar.gz https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_BIN_VERSION}/hadoop-${HADOOP_BIN_VERSION}.tar.gz
fi;

tar zxf /tmp/hive/apache-hive-${HIVE_BIN_VERSION}-bin.tar.gz -C /opt/app && \
    tar zxf /tmp/hive/hadoop-${HADOOP_BIN_VERSION}.tar.gz -C /opt/app && \
    rm /opt/app/apache-hive-${HIVE_BIN_VERSION}-bin/lib/guava-19.0.jar && \
    cp /opt/app/hadoop-${HADOOP_BIN_VERSION}/share/hadoop/hdfs/lib/guava-27.0-jre.jar /opt/app/apache-hive-${HIVE_BIN_VERSION}-bin/lib/ && \
    cp /opt/app/hadoop-${HADOOP_BIN_VERSION}/share/hadoop/tools/lib/hadoop-aws-${HADOOP_BIN_VERSION}.jar /opt/app/apache-hive-${HIVE_BIN_VERSION}-bin/lib/ && \
    cp /opt/app/hadoop-${HADOOP_BIN_VERSION}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.12.316.jar /opt/app/apache-hive-${HIVE_BIN_VERSION}-bin/lib/ && \
    rm /tmp/hive/*.gz && rm -rf /tmp/hive/output && rm -rf /tmp/hive/data

exclude_files=("hive-cli" "hive-exec" "hive-metastore")

clean_unused_files() {
  local target=$1
  local mode=$2
  local n=0
  local cleaned=0
  for jf in $(ls $target);
  do
    
    if [[ "${exclude_files[@]}" =~ ${jf%%-*} ]]; then
      continue
    fi

    cleaned=0
    for pom in $(jar tvf $target/$jf|grep -E "pom.(xml|properties)$"|awk -F" " '{print $8}');
    do
      zip -d $target/$jf $pom
      cleaned=1
    done;
    if [[ $cleaned -eq 1 ]] || [[ $jf =~ ^[a-z]+.*$ ]];
    then
      ok=1
      echo $(date) $jf > RELEASE
      zip -u $target/$jf RELEASE
      if [[ "$mode" == "1" ]]; then
        mv $target/$jf $target/lib-$n.jar
      fi;
    fi;
    n=$((n+1))
  done;
}

for fd in hcatalog/share/webhcat hcatalog/share/webhcat/svr/lib jdbc lib hcatalog/share/webhcat/java-client;
do
  clean_unused_files /opt/app/apache-hive-${HIVE_BIN_VERSION}-bin/${fd} 0
  # echo .
done;

for fd in share/hadoop/tools/sources share/hadoop/yarn/sources share/hadoop/hdfs/sources share/hadoop/mapreduce/sources;
do
  rm -rf /opt/app/hadoop-${HADOOP_BIN_VERSION}/${fd}
done;

rm -rf /opt/app/hadoop-${HADOOP_BIN_VERSION}/share/hadoop/yarn/hadoop-yarn-applications-catalog-webapp-*.war

for fd in share/hadoop/tools/lib share/hadoop/yarn share/hadoop/yarn/csi share/hadoop/yarn/csi/lib share/hadoop/yarn/timelineservice share/hadoop/yarn/lib share/hadoop/common/lib share/hadoop/hdfs/lib share/hadoop/mapreduce share/hadoop/client
do
  clean_unused_files /opt/app/hadoop-${HADOOP_BIN_VERSION}/${fd} 0
  # echo .
done;

