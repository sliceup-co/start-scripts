# this is the start script

  export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"

  /opt/sliceup/executables/flink-1.10.0/bin/task-manager.sh stop-all

  sleep 10

  /opt/sliceup/executables/flink-1.10.0/bin/task-manager.sh start

  sleep 5

  /opt/sliceup/executables/flink-1.10.0/bin/task-manager.sh start

