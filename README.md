This repository is used in conjunction with a separate tarball and you should have received a link to download it. The deployment should consist of one master node and a minimum of two worker nodes.

On the master node, Clone this repository into the home directory of the username being used to install the system. Move the tarball into the start-scripts directory (do not extract it). Next, run the sliceinstall.sh script. Do not use sudo when executing this command. The script will prompt for sudo when required.

This deployment configuration is set up to run as a POC. If you start with a 1tb of SSD drive space on the master, your system will run for approximately 30 days (+/- 10 days) -  at 8k/sec of logs. For production usage, the system will have to be customized for your environment. This will include database cleaning and data retention policies. 

Also for production, certificates will need to be installed, HTTPS will need to be configured, and database configurations will need to be refined to enhance security and match policies.

These systems should start out with full and open communications between all devices in the cluster. Traffic that is not to or from the master/workers should be blocked for the worker nodes. The exception would be any protocols used for device administration. The master should allow the configured Syslog port, administration traffic, TCP port 3000, and full communication to the workers.

