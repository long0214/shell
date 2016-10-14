#!/bin/bash
#date:2016-09-14
#check disk

disk_check() {

	>disk_check.log
	
	#最大分区是否挂载home
	max_mount=$(df | egrep -v 'Filesystem|tmpfs' | sort -r -n -k 4 | awk '{if(NR==1)print $6}')
	[ "$max_mount" != "/home" ] && echo  "Max Size part is not mount on /home" >>disk_check.log
	
	#分区使用情况,超过MAX为异常
	MAX=30
	df -h | sed 's/%//g' | awk -v max=$MAX '{if(NR>1 && $5>max)print $1}' | xargs -i echo {}使用异常，超过$MAX >>disk_check.log

	#检查/etc/fstab
	cat /etc/fstab | sed -e '/^#/d' -e '/^$/d' | awk '{print $2}' | egrep -q '^/home$'
	[ "$?" -ne "0" ] && echo  "/etc/fatab has no /home" >>disk_check.log
	
	if [ -s disk_check.log ];then
		return 101
	else
		return 100
	fi
	
}
disk_info() {
	#磁盘数量
	Disk_Num=$(lsblk | grep -c disk)
	echo "磁盘:$Disk_Num"

	#分区使用情况
	df -h | awk '{if(NR>1)print $1,$2,$5}'

	#检查RAID
	dmidecode -s system-product-name | awk '{print $1}' | xargs -i [ {} = "PowerEdge" ]
	if [ "$?" -eq "0" ];then
		echo "物理机"
		raid=$(cat /proc/mdstat | awk -F ':' '{if(NR==1)print $2}')
		[ "$raid" = " " ] && echo  "└─RAID:没有RAID" || echo "└─RAID:$raid"
	else
		echo "虚拟机"
	fi
}
main() {
	opt=$1
	case $opt in
			info)
			disk_info
			;;
			check)
			disk_check
			;;
			*)
			echo "Usage: disk_check.sh <check|info>"
	esac
}
main $@
