#!/bin/bash

#config
FILE=loadwatch.`date +%F.%H.%M`
DIR=/root/loadwatch
COLUMNS=512
EMAIL="admin@overit.com"
EMAILMESSAGE="/tmp/emailmessage.txt"

#Load Threshold for doing a dump.
THRESH=1

#pull load average, log
LOAD=`cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}'`
echo `date +%F.%X` - Load: $LOAD >> $DIR/checklog

SUBJECT="LoadWatch on $HOSTNAME triggered. Load is $LOAD. Please Check it out."

#trip
if [ $LOAD -ge $THRESH ]
then
	#log 
	echo Loadwatch tripped, dumping info to $DIR/$FILE >> $DIR/checklog
	echo `date +%F.%H.%M` > $DIR/$FILE
	echo "LoadWatch on $HOSTNAME triggered. $LOAD load. Please Check it out." > $EMAILMESSAGE

	#email (optional, set email address to customer and uncomment below lines)
	EMAIL="admin@overit.com"
	/bin/mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE

	#summary

        #uncomment this if reseater.sh installed from https://wiki.int.liquidweb.com/articles/ResourceEaters
        /root/bin/reseaters.sh >> $DIR/$FILE
	echo -e "\n\nSummary------------------------------------------------------------\n\n" >> $DIR/$FILE
	NUMHTTPD=`ps aux|grep httpd|wc -l`
	echo "Number of HTTPD Processes: $NUMHTTPD" >> $DIR/$FILE
	HTTPDCPU=`ps aux|grep httpd|awk '{sum+=$3} END {print sum}'`
	echo "HTTPD CPU consumption: $HTTPDCPU %" >> $DIR/$FILE 
	HTTPDMEM=`ps aux|grep httpd|awk '{sum+=$6} END {print sum}'`
	HTTPDMEMMEG=$((HTTPDMEM/1024))
	echo "HTTPD memory consumption: $HTTPDMEM Kilobytes ($HTTPDMEMMEG Megabytes)" >> $DIR/$FILE
	NUMPROCS=`grep -c processor /proc/cpuinfo`
	echo "Number of CPU Cores: $NUMPROCS" >> $DIR/$FILE
	NUMPHP=`ps aux|grep php|wc -l`
	echo "Number of PHP Processes: $NUMPHP" >> $DIR/$FILE
	PHPCPU=`ps aux|grep php|awk '{sum+=$3} END {print sum}'`
	echo "PHP CPU consumption: $PHPCPU %" >> $DIR/$FILE
	PHPMEM=`ps aux|grep php|awk '{sum+=$6} END {print sum}'`
	PHPMEMMEG=$((PHPMEM/1024))
	echo "PHP memory consumption: $PHPMEM Kilobytes ($PHPMEMMEG Megabytes)" >> $DIR/$FILE
	MYSQLCPU=`top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $9'}`
	echo "MYSQL CPU consumption: $MYSQLCPU %" >> $DIR/$FILE
	MYSQLMEM=`top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $6'}`
	echo "MYSQL RAM consumption: $MYSQLMEM" >> $DIR/$FILE
	top -bcn1 | head -n 5 >> $DIR/$FILE
	uptime >> $DIR/$FILE
	free -m >> $DIR/$FILE

	#mysql
	echo -e "\n\nMySQL:------------------------------------------------------------\n\n" >> $DIR/$FILE
	mysqladmin stat >> $DIR/$FILE
	mysqladmin proc >> $DIR/$FILE

	#apache
	#echo -e "\n\nApache------------------------------------------------------------\n\n" >> $DIR/$FILE
	#/sbin/service httpd fullstatus >> $DIR/$FILE

	#network
	echo -e "\n\nNetwork------------------------------------------------------------\n\n" >> $DIR/$FILE
	netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head >> $DIR/$FILE

	#email
	echo -e "\n\nEmail------------------------------------------------------------\n\n" >> $DIR/$FILE
	#EXIMQUEUE=`exim -bpc`
	#echo "Exim Queue: $EXIMQUEUE " >> $DIR/$FILE 
	/usr/sbin/exiwhat >> $DIR/$FILE

	#process list
	echo -e "\n\nProcesses------------------------------------------------------------\n\n" >> $DIR/$FILE
	ps auxf >> $DIR/$FILE

	#iostat
	echo -e "\n\nIOSTAT---------------------------------------------------------------\n\n" >> $DIR/$FILE
	iostat >> $DIR/$FILE

	echo -e "\n\nWHM Stuff---------------------------------------------------------------\n\n" >> $DIR/$FILE
	/usr/bin/lynx -dump -width 500 http://127.0.0.1/whm-server-status >> $DIR/$FILE

	echo -e "\n\nlsof---------------------------------------------------------------\n\n" >> $DIR/$FILE
	lsof >> $DIR/$FILE

fi