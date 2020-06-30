#!/bin/bash

    echo -e "\e[96m Starting Install of"; hostname; echo -e " \e[39m"
    sudo apt-get update

#create directory structure
    sudo mkdir /opt/sliceup


# get files remove this section and uncomment CURL when available"
    echo -e "\e[96m Install sshpass  \e[39m"
    sudo apt install sshpass -y


    echo -e "\e[96m Extracting Files and Installing Java  \e[39m"
    sudo tar -xvzf executables.tar.gz --directory /opt/sliceup/
    sudo mkdir /opt/sliceup/scripts
    sudo chmod -R a+r /opt/sliceup
    cuser=$(whoami)
    sudo chown -R $cuser /opt/sliceup
    sudo apt install openjdk-11-jre-headless -y
    sudo apt install openjdk-11-jdk-headless -y

    sudo mv workerstart.sh /opt/sliceup/scripts/workerstart.sh
    #sudo mv workerinstall.sh /opt/sliceup/scripts/workerinstall.sh
	sudo chmod +x /opt/sliceup/scripts/workerstart.sh
	sudo mv sliceworker.service /etc/systemd/system/sliceworker.service

#Enable service at start
    echo -e "\e[96m Enabling StartUp service  \e[39m"
    sudo systemctl enable sliceworker

#Inside each of the worker Nodes
	echo -e "\e[96m Replacing Variable Options  \e[39m"
    export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"
        #Replace {MASTER_IP} in executables/flink-1.10.0/conf/flink-conf.yaml
        #sudo sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/flink-1.10.0/conf/flink-conf.yaml

