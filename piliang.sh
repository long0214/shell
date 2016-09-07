#!/bin/bash
#批量复制脚本到远程服务器并执行

#如果参数不为2，退出
if [ "$#" -ne "2" ];then
	echo "Usage:piliang.sh <scripts_file> <iplist_file>"
	exit
fi

#全局变量
scripts_file=$1
iplist=$2

#创建有名管道,控制并发量为2
mkfifo fd1
if [ "$?" -eq "0" ];then
	exec 9<>fd1
	rm -fr fd1
else
	echo "can not touch fifo fd1!"
	exit 
fi
echo -ne "1\n1\n" 1>&9

#批量执行
for ip in `cat $iplist`
do
	read -u 9
	{
		#echo -ne "======$ip======\n"
		scp  -o ConnectTimeout=5 -o NumberOfPasswordPrompts=0 -o StrictHostkeyChecking=no $scripts_file $ip:/tmp/ 2>/dev/null && 
		ssh $ip "sh /tmp/$scripts_file" &>/tmp/piliang.log
		if [ "$?" -eq "0" ];then
			echo "======$ip======ok"
		else
			echo "======$ip======failed"
		fi
		#ssh $ip "iptables -t filter -A INPUT -p tcp -s 10.12.4.213 -d $ip --dport 514"
		echo -ne "1\n" 1>&9
	}&
done
wait
exec 9<&-

