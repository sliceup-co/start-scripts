#!/bin/bash

    echo -e "\e[96m Give users detailed instructions\e[39m"
    echo -e "\e[96m Download tar ball \e[39m"


#install sshpas
sudo apt-get install -y sshpass

#Get password for postgres
    echo -e "\e[96m Please enter the password for the database  \e[39m"
    read psqlpass


#Get node IP info from end user
    echo -e "\e[96m This is the master node. Enter a comma seperated list of all workernode IP addresses"
    echo -e "Example 192.0.2.1,192.0.2.33,192.0.2.99 \e[39m"
    #read ipaddressin
    IFS=',' read -r -a ipaddresses

# Get IP address of the Master
    echo -e "\e[96m This device is being configured as the master. Enter on of its IP addresses to be used to communicate with the worker nodes"
    echo -e "e.g. 192.0.2.100 \e[39m"
    read masterip


#Get syslog port
    echo -e "\e[96m Enter the port that will be used to recieve \e[39m"
    read port

#Ask for password 
    echo -e "\e[96m The system needs to ssh into the worker nodes to complete the install \e[39m" 
        echo -e "\e[96m Enter the password for the remote worker \e[39m" 
        read -s sspass1
        echo -e "\e[96m Enter password again\e[39m"
        read -s sspass2

        while [[ "$sspass1" != "$sspass2" ]]; do	
         
            echo -e "\e[96m The passwords do not match. Let's try again. \e[39m" 
            echo -e "\e[96m Enter password \e[39m" 
            read -s sspass1
            echo -e "\e[96m Enter password again\e[39m"
            read -s sspass2
          
        done

export SSHPASS="$sspass1"

# Check for Ping reachablility
    for address in "${ipaddresses[@]}"
         do

            pingtest=$(ping -nq -w 2 -c 1 $address | grep -o "=")    

                    if [[ "$pingtest" != "=" ]]; then	
                        echo -e "\e[96m $address is not reachable via ping \e[39m"
                        echo -e "\e[96m Please resolve and try again. \e[39m"
                        exit
                      
                    fi

         done

	 echo -e "\e[96m Success! All devices rechable via ping. Continuing. \e[39m"

# Check for SSH reachablility
    for address in "${ipaddresses[@]}"
         do


            linux=$(sshpass -ev ssh -o "StrictHostKeyChecking=no" $address uname)    

                    if [[ "$linux" != "Linux" ]]; then	
                        echo -e "\e[96m $address is not reachable via SSH \e[39m"
                        echo -e "\e[96m Please resolve and try again. \e[39m"
                        exit
                      
                    fi


         done


	echo -e "\e[96m Success! All devices rechable via SSH. Continuing. \e[39m"

#Install code on remote devices

    for address in "${ipaddresses[@]}"
         do
	      echo -e "\e[96m Starting process for $address \e[39m"
            sshpass -ev rsync -avz -e ssh --progress executables.tar.gz remoterun.sh workerstart.sh sliceworker.service $address:
            sshpass -ev ssh -t -o "StrictHostKeyChecking=no"  $address "echo $sspass1 | sudo -S ./remoterun.sh"
	    
            insed="echo $sspass1 | sudo -S sed -i 's/{MASTER_IP}/$masterip/g' /opt/sliceup/executables/flink-1.10.0/conf/flink-conf.yaml"
            insed="echo $sspass1 | sudo -S sed -i 's/{MASTER_IP}/$masterip/g' /opt/sliceup/executables/conf.ini"

	        sshpass -ev ssh -t -o "StrictHostKeyChecking=no"  $address "$insed"  

            sshpass -ev ssh -o "StrictHostKeyChecking=no" $address "python3 /opt/sliceup/executables/task-exec-monitor.py $address &"

         done

        exit


#Check to see if Java working on remote node.


    for address in "${ipaddresses[@]}"
         do

            jversion=$(sshpass -ev ssh -o "StrictHostKeyChecking=no" $address java --version | grep -oh 'OpenJDK 64-Bit')    

                    if [[ "$jversion" != "OpenJDK 64-Bit" ]]; then	
                        echo -e "\e[96m $address is not Running the correct version of Java \e[39m"
                        echo -e "\e[96m Please resolve and run script agin \e[39m"
                        exit
                      
                    fi


         done



	echo -e "\e[96m Success! All devices running correct Java version. Continuing install of master node \e[39m"



##########################Begin Master Install#####################################


#update system
    sudo apt-get update
#create directory structure
    sudo mkdir /opt/sliceup
    sudo mkdir /opt/sliceup/scripts
    sudo chmod -R a+r /opt/sliceup
    sudo mkdir /opt/sliceup/dashboards
    cuser=$(whoami)
    sudo chown -R $cuser /opt/sliceup

# get files remove this section and uncomment CURL when available"

    echo -e "\e[96m Need way to download TAR files  \e[39m"
   

# get files remove this section and uncomment CURL when available"



	echo -e "\e[96m  Need way to download TAR files \e[39m"
	sudo rm workerinstall.sh
	sudo rm workerstart.sh
	sudo rm sliceworker.service
	sudo mv masterstart.sh /opt/sliceup/scripts/masterstart.sh
	sudo mv masterinstall.sh /opt/sliceup/scripts/masterinstall.sh
	sudo chmod +x /opt/sliceup/scripts/masterstart.sh
	sudo mv slicemaster.service /etc/systemd/system/slicemaster.service
	


    echo -e "\e[96m This script is not using CURL. When Curl is avaialbe, enable it in the script \e[39m"
    sleep 5




# begin install


#curl https://transfer.sh/wROIc/executables.tar.gz -o executables.tar.gz
    echo -e "\e[96m Extract Files and install JAVA  \e[39m"
    sudo tar -xvzf executables.tar.gz --directory /opt/sliceup/
    #sudo chmod -R a+r /opt/sliceup
    sudo apt install openjdk-11-jre-headless -y
    sudo apt install openjdk-11-jdk-headless -y

#changing curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | sh
    echo -e "\e[96m Install Vector and Postgress  \e[39m"
    curl --proto '=https' --tlsv1.2 -O https://packages.timber.io/vector/0.9.X/vector-amd64.deb
    sudo dpkg -i vector-amd64.deb
    sudo systemctl start vector
    sudo apt install postgresql-client -y
    sudo apt install postgresql -y
    sleep 10

#create variable requires config for sliceupdev
    echo -e "\e[96m Config Postgres  \e[39m"
    sudo -u postgres psql -c "CREATE USER sliceup WITH PASSWORD '$psqlpass';"
    sudo -u postgres psql -c "ALTER ROLE sliceup WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;"
    sudo -u postgres psql -c "CREATE DATABASE sliceup"
    sudo -u postgres psql sliceup < /opt/sliceup/executables/db_migration/sourcedb.sql

#Lock this down and standardize install

    sudo sed -i "s/#listen_addresses.*/listen_addresses = '*'/" /etc/postgresql/10/main/postgresql.conf
   

# take user entered IP addresses and create hba config
    for address in "${ipaddresses[@]}"
    do
        line="host    all             all             $address\/32            md5"
        sudo sed -i "s/# IPv4 local connections:/# IPv4 local connections:\n$line/" /etc/postgresql/10/main/pg_hba.conf
    done

    line="host    all             all             $masterip\/32            md5"
    sudo sed -i "s/# IPv4 local connections:/# IPv4 local connections:\n$line/" /etc/postgresql/10/main/pg_hba.conf


    echo -e "\e[96m Install Additonal Supporting Files  \e[39m"

    sudo systemctl restart postgresql
    sudo apt-get install libpq-dev -y
    sudo apt-get install python-dev -y
    sudo apt-get install python3-dev -y
    sudo apt-get install build-essential -y
    sudo apt-get install build-essential autoconf libtool pkg-config python-opengl python-pil python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev -y
    sudo apt install python3-pip -y
    python3 -m pip install psycopg2
    python3 -m pip install requests
    python3 -m pip install PrettyTable
    python3 -m pip install selenium
    python3 -m pip install kafka-python

    echo -e "\e[96m Create Zookeeper Config  \e[39m"

    K=1 && mkdir /tmp/zookeeper$K && echo $K >> /tmp/zookeeper$K/myid
    K=2 && mkdir /tmp/zookeeper$K && echo $K >> /tmp/zookeeper$K/myid
    K=3 && mkdir /tmp/zookeeper$K && echo $K >> /tmp/zookeeper$K/myid


    echo -e "\e[96m Replace Variable Information in Configs  \e[39m"

    sudo sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-1.properties
    sudo sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-2.properties
    sudo sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-3.properties
    sudo sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-4.properties

# Ensure Permissions
                cuser=$(whoami)
                sudo chown -R $cuser /opt/sliceup

#Replace {MASTER_IP} to executables/vector/vector.toml
    sudo sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/vector/vector.toml
    sudo sed -i "s/{RECEIVING_PORT}/$port/g" /opt/sliceup/executables/vector/vector.toml

        
#Enable vector to run on port lower than 1024
           sudo setcap 'cap_net_bind_service=+ep' /usr/bin/vector


#Replace {MASTER_IP} in executables/flink-1.10.0/conf/flink-conf.yaml
    sudo sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/flink-1.10.0/conf/flink-conf.yaml
       

#Replace {MASTER_IP} in executables/conf.ini
    sudo sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/conf.ini

#Replace Postgres password
    sudo sed -i "s/{PSQL_PASS}/$psqlpass/" /opt/sliceup/executables/conf.ini

    
#Replace {WORKER_IPS} in executables/flink-1.10.0/conf/slaves with list of worker ips
    # The current file is blank so adding marker
    echo "" > /opt/sliceup/executables/flink-1.10.0/conf/slaves
       
#Grafana Install
    echo -e "\e[96m Installing Grafana  \e[39m"
    sudo apt-get install -y adduser libfontconfig1
    wget https://dl.grafana.com/oss/release/grafana_7.0.4_amd64.deb
    sudo dpkg -i grafana_7.0.4_amd64.deb

    sudo sed -i "s/psqlpass/$psqlpass/g" slicedatasource.yaml
    sudo mv sliceupdashboards/*.* /opt/sliceup/dashboards/
    sudo mv sliceprov.yaml /etc/grafana/provisioning/dashboards
    sudo mv slicedatasource.yaml /etc/grafana/provisioning/datasources

    

####Begin Master Start#####
echo -e "\e[96m Installation is complete. Begin Master Service start?  \e[39m"
read ready






###################Starting the Services#######################3
#  Grafana Start
    sudo /bin/systemctl daemon-reload
    sudo /bin/systemctl enable grafana-server
    sudo /bin/systemctl start grafana-server

    sudo apt-get install -y jq
    echo -e "\e[96m Restarting Grafana \e[39m"
    sudo /bin/systemctl stop grafana-server
    sleep 5
    sudo /bin/systemctl start grafana-server
    sleep 5
    echo -e "\e[96m Changing Home Dashboard \e[39m"
    id=$(curl -X GET -H "Content-Type: application/json" http://admin:admin@127.0.0.1:3000/api/dashboards/uid/kC8AXaZMz | jq .dashboard.id)
    echo -e "\e[96m Dashboard ID is $id \e[39m"
    curl -X PUT -H "Content-Type: application/json" -d '{"theme": "", "homeDashboardId": '$id', "timezone": ""}' http://admin:admin@127.0.0.1:3000/api/org/preferences


echo -e "\e[96m Start Kafka  \e[39m"

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
    echo -e "\e[96m FINISHED INSTALL OF KAFKA  \e[39m"
    sleep 5

#Enable service at startup
echo -e "\e[96m Enable Slicemaster service  \e[39m"
sudo systemctl enable slicemaster

# Start Cluster
echo -e "\e[96m Starting Cluster  \e[39m"
/opt/sliceup/executables/flink-1.10.0/bin/start-cluster.sh #(It will ask the passwords of the worker nodes)
sleep 5

java -cp /opt/sliceup/executables/db-cleaner.jar com.sliceup.dbcleaner.Main /opt/sliceup/executables/conf.ini &

/opt/sliceup/executables/flink-1.10.0/bin/flink run /opt/sliceup/executables/log-lines-proc-1.0.jar --init /opt/sliceup/executables/conf.ini &

sleep 10


echo -e "\e[96m Script Has Finished \e[39m"


