#!/bin/bash -x

IPList=/usr/local/bin/Netwall/NetwallIP.txt    #TextFile containing IP's to poll

#count rows in iplist
rows=$(wc -l /usr/local/bin/Netwall/NetwallIP.txt |awk '{print $1}')

#Fetch the IP and SNMPv3 credentials to a ARRAY
nr=1
while [ $nr -le $rows ]
do
	y=$(sed -n $nr\p < $IPList;)
	IFS=',' read -r -a array <<< $y
	IP=${array[0]}
	USER=${array[1]}
	PW=${array[2]}
	PW2=${array[3]}

	DB=($(echo ${array[0]} | tr '.' '_'))

	Ifs_Name=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.1.7.1.2 | awk '{print $4}')
	Ifs_Stat_in1=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.1.2.1.7.1.8 | awk '{print $4}')
	Ifs_Stat_out1=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.1.2.1.7.1.9 | awk '{print $4}')
	#Sleep for 10 Sec to calculate speed
	sleep 10
	Ifs_Stat_in2=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.1.2.1.7.1.8 | awk '{print $4}')
	Ifs_Stat_out2=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.1.2.1.7.1.9 | awk '{print $4}')
	#Ifs to ARRAY	
	Ifs_Name_A=($(echo $Ifs_Name | tr '"' '\n'))
	Ifs_Stat_in_A1=($(echo $Ifs_Stat_in1 | tr ' ' '\n'))
	Ifs_Stat_in_A2=($(echo $Ifs_Stat_in2 | tr ' ' '\n'))
	Ifs_Stat_out_A1=($(echo $Ifs_Stat_out1 | tr ' ' '\n'))
	Ifs_Stat_out_A2=($(echo $Ifs_Stat_out2 | tr ' ' '\n'))
	nr=${#Ifs_Name_A[@]}

	#Create DB
	curl -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE \"$DB\""
	for (( i=0; i<$nr; i++ ))
		do
			# Calculate In BW
			Ifs_Stat_A3_1=$(expr ${Ifs_Stat_in_A2[$i]} - ${Ifs_Stat_in_A1[$i]})
			Ifs_Stat_A3=$(echo "scale = 2; $Ifs_Stat_A3_1 / 10" |bc)
			Ifs_Stat_A4=$(echo "scale = 2; $Ifs_Stat_A3 / 1000 / 1000" |bc )
			# Calculate Out BW
			Ifs_Stat_A5_1=$(expr ${Ifs_Stat_out_A2[$i]} - ${Ifs_Stat_out_A1[$i]})
			Ifs_Stat_A5=$(echo "scale = 2; $Ifs_Stat_A5_1 / 10" | bc)
			Ifs_Stat_A6=$(echo "scale = 2; $Ifs_Stat_A5 / 1000 / 1000" |bc )
			# check for wrapping of counters
			if [ $(( ${Ifs_Stat_A4%.*} )) -lt 0 ]
			then
				Ifs_Stat_A4=0
			fi
			if [ $(( ${Ifs_Stat_A6%.*} )) -lt 0 ]
			then
				Ifs_Stat_A6=0
			fi
			#Post to InfluxDB
			curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "${Ifs_Name_A[$i]},host=$IP,Direction=In value=$Ifs_Stat_A4"
			curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "${Ifs_Name_A[$i]},host=$IP,Direction=Out value=$Ifs_Stat_A6"

	       done

	#Rules usage
        Rule_Name=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.3.2.1.2 | awk '{print $4}')
        Rule_Hit=$(snmpwalk -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.3.2.1.3 | awk '{print $4}')
        #Rules to ARRAY
        Rule_Name_A=($(echo $Rule_Name | tr '"' '\n'))
        Rule_Hit_A=($(echo $Rule_Hit | tr '"' '\n'))
	nr=${#Rule_Name_A[@]}
	for (( i=0; i<$nr; i++ ))
	do
		#curl -i -XPOST 'http://localhost:8086/write?db=$DB' --data-binary "${Rule_Name_A[$i]},host=$IP,Direction=In value=${Rule_Hit_A[$i]}"
		curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Rule=${Rule_Name_A[$i]},host=$IP value=${Rule_Hit_A[$i]}"
	done

# Sleep for 3 sec to get a more true CPU value
sleep 3
Cpu=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.1.1.0 | awk '{print $4}')
Flows=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.1.5.0 | awk '{print $4}')
CpuTemp=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP .1.3.6.1.4.1.5089.1.2.1.11.1.3.1  | awk '{print $4}') 
Mem_used=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.1.18 | awk '{print $4}')
Mem_free=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP  .1.3.6.1.4.1.5089.1.2.1.19 | awk '{print $4}')
Uptime=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.2.1.1.3 |awk '{print $5}' | tr -d ,)
Sys_name=$(snmpget -v3 -l authPriv -u $USER -a SHA1 -A $PW -x AES -X $PW2 $IP 1.3.6.1.2.1.1.1 | awk '{print $5,$6,$7,$8}' | tr '"' '\n')

#Uptime_A=($(echo $Uptime | tr -d , ))

# Post to InfluxDB
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Cpu,host=$IP value=$Cpu"
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Flows,host=$IP value=$Flows"
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "CpuTemp,host=$IP value=$CpuTemp"
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Mem_used,host=$IP value=$Mem_used"
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Mem_free,host=$IP value=$Mem_free"
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Uptime1,host=$IP value="$Uptime""
curl -i -XPOST "http://localhost:8086/write?db=$DB" --data-binary "Sys_name,host=$IP value=\"$Sys_name\""
done

