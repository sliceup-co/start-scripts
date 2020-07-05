#!/bin/bash
#create directory structure
    K=1 && mkdir /tmp/zookeeper$K && echo $K >> /tmp/zookeeper$K/myid
    K=2 && mkdir /tmp/zookeeper$K && echo $K >> /tmp/zookeeper$K/myid
    K=3 && mkdir /tmp/zookeeper$K && echo $K >> /tmp/zookeeper$K/myid
    export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/zookeeper-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/zookeeper1.properties & 
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/zookeeper-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/zookeeper2.properties & 
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/zookeeper-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/zookeeper3.properties & 
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/kafka-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-1.properties & 
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/kafka-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-2.properties & 
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/kafka-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-3.properties & 
    sleep 5
    /opt/sliceup/executables/kafka_2.12-2.4.1/bin/kafka-server-start.sh /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-4.properties & 
    sleep 5
    vector --config /opt/sliceup/executables/vector/vector.toml &
    sleep 5
# Start Cluster
    /opt/sliceup/executables/flink-1.10.0/bin/start-cluster.sh 
#Wait for task executors to start
    echo -e "\e[96m Job initialization started.  \e[39m"
    echo -e "\e[96m Stage 1/5  \e[39m"
    sleep 30
    echo -e "\e[96m Stage 2/5  \e[39m"
    sleep 30
    echo -e "\e[96m Stage 3/5  \e[39m"
    sleep 30
​    echo -e "\e[96m Stage 4/5  \e[39m"
    sleep 30
​​    echo -e "\e[96m Stage 5/5  \e[39m"
    java -cp /opt/sliceup/executables/db-cleaner.jar com.sliceup.dbcleaner.Main /opt/sliceup/executables/conf.ini &
    sleep 30
    echo -e "\e[96m Phase 5/5 of job initialization completed.  \e[39m"
    /opt/sliceup/executables/flink-1.10.0/bin/flink run /opt/sliceup/executables/log-lines-proc-1.0.jar --init /opt/sliceup/executables/conf.ini
    sleep 5
    echo -e "\e[96m Flink-job finished executing so we are restarting the job  \e[39m"
    exit 1    


