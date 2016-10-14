#!/bin/bash

check(){
	ip=$(ifconfig | awk '/inet addr/{print substr($2,6)}' | grep -v 127)
	check_log=${ip}_check
	>$check_log
	#check uptime if less than one day (86400s)
	awk '($1>86400){print "uptime more than one day"}' >>$check_log /proc/uptime
	
	#check the max number of open file
	max_open_file=$(sed -e '/^#/d' -e '/^$/d' /etc/security/limits.conf | awk '/nofile/{print $4}')
	[ $max_open_file -eq 65535 ] || echo "max number of open file is not 65535" >> $check_log
	
	#check SUID and GUID of /usr/sbin/ntpdate
	command="/usr/sbin/ntpdate"
	if [ ! -u $command ] || [ ! -g $command ];then
		echo "$command has no SUID or SGID" >> $check_log
	fi
	
	#check ntpdate if ok
	crontab -l 2>&1 | grep "ntpdate"
	if [ $? -eq 0 ];then
		for ip in $(crontab -l | sed -n '/ntpdate/p' | grep -o '\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}')
		do
			/usr/sbin/ntpdate -s $ip || echo "can't ntpdate to $ip" >> $check_log
		done
	else
		echo "crontab not set ntpdate" >> $check_log
	fi
	
	#check hardware if have error
	dmesg | grep error
	[ $? -eq 0 ] && echo "hardware error" >> $check_log

	#check disk Read/Write 
	touch /home/touch && rm -fr /home/touch || echo "/home can't write or read" >> $check_log
	
	#check route 10.0.0.0
	net="10.0.0.0"
	route | grep $net
	[ $? -ne 0 ] && echo "route $net not set" >> $check_log
	
	if [ -s "$check_log" ];then
		return 101
	else
		rm -fr $check_log
		return 100
	fi
}

#check the size of memory
mem_total=$(awk '(NR==1){print int($2/1024)}' /proc/meminfo)


ip_check(){
	ip_list=$1
	while read line
	do
		ip_out=$(echo $line|awk '{print $1}')
		ip_in=$(echo $line|awk '{print $2}')
		real_ip_in=$(ssh $ip_out "ifconfig | awk '/inet addr/{print substr(\$2,6)}' | grep -v 127" </dev/null)

		if [ "$ip_in" == "$real_ip_in" ];then
			echo "$line is ok"
		else
			echo -e "\033[91m$line is not match,real_ip is $real_ip_in\033[0m"
		fi
	done < $ip_list
}
check
ip_check $@
