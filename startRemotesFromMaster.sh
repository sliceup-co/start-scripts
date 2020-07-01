    sudo apt-get install -y sshpass

    
    echo -e "\e[96m This is the master node. Enter a comma seperated list of all workernode IP addresses"
    echo -e "Example 192.0.2.1,192.0.2.33,192.0.2.99 \e[39m"
    #read ipaddressin
    IFS=',' read -r -a ipaddresses

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
	        sshpass -ev ssh -t -o "StrictHostKeyChecking=no"  $address "$insed"  

         done

    exit