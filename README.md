# Project Title

Graph SNMPv3 values from Clavister Netwall

## Description

This script uses crontab to set the polling intervall of the Netshield devices,
it will take the values and store them in InfluxDB. The values can then be used to 
make graphs in grafana.

## Getting Started

### Dependencies

* Setup uses Ubuntu server 20.04
	* Add Grafana repo
	```
	wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
	echo "deb https://packages.grafana.com/enterprise/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	sudo apt update
	```
* Grafana (apt install grafana)
* InfluxDB (apt install influxdb)
* Influx-client (apt install influx-client)

### Installing

* The file NetwallIP.txt is where the script reads IP,USER,SNMPv3-PW,USER-PW,

Example
```
192.168.105.3,apa,apa123456789,dt12576!,
```
* Enable Influx and Grafana
```
sudo systemctl enable influxdb
sudo systemctl status influxdb
sudo systemctl enable grafana-server.service
sudo systemctl status grafana-server
```
* Create the dir for the script
```
sudo mkdir /usr/local/bin/Netwall
sudo vi /usr/local/bin/Netwall/NetwallIP.txt 
```
* Make script executable
```
sudo chmod +x Influx_Netwall.sh
```

### Executing program

* This script uses crontab to execute the script
Polls the network device every 5 min
```
*/5 * * * *     /usr/local/bin/Netwall/Influx_Netwall.sh > /dev/null 2>&1
```

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

## Authors

Contributors names and contact info

[Foxmaster](pemi@clavister.com)  
[Count_Oliver](olgr@clavister.com)

## Version History
* 1.0 Updating Readme
* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the BSD License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [Grafana](https://grafana.com/)
* [Clavister](https://clavister.com)
