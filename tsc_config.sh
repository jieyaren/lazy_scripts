#!/bin/sh
#if it does't work, dos2unix file and chmod 
echo "--------------------------------------------------------"
echo "|TSC ip config script ,and use for version 5.1 6.0 6.1 |"
echo "|                                                      |"
echo "|I don't check the Parameter Validity , so be carefull |"
echo "--------------------------------------------------------"
echo "eth0 `ifconfig eth0 | grep 'inet ' | sed s/^.*addr://g | sed s/Bcast.*$//g `"
echo "eth1 `ifconfig eth1 | grep 'inet ' | sed s/^.*addr://g | sed s/Bcast.*$//g `"

read -p "TSC IP enter eth0 OR eth1: " eth
if [[ $eth == "eth1" || $eth == "eth0" ]] ; then
	#eth${sed -n "/^[0-9]\+$/p"}
	TSC_IP=`ifconfig $eth | grep 'inet ' | sed s/^.*addr://g | sed s/Bcast.*$//g | sed s/[[:space:]]//g`
else
	TSC_IP='20.0.0.2'
	echo "device  error ,exit !"
	exit
fi

check_number(){
	local ID=$1
	if [ -n "$(echo $1| sed -n "/^[0-9]\+$/p")" ];then 
		return 0
	else 
		echo 'Number Error' 
		return 1
	fi 
}

while true; do
    read -p "Please enter TSC_ID: " TSC_ID
    check_number $TSC_ID
    [ $? -eq 0 ] && break
done


check_ip() {
    local IP=$1
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ $VALID_CHECK == "yes" ]; then
            return 0
        else
            echo "IP $IP not available!"
            return 1
        fi
    else
        echo "IP format error!"
        return 1
    fi
}

while true; do
    read -p "Please enter MSO_IP: " MSO_IP
    check_ip $MSO_IP
    [ $? -eq 0 ] && break
done

read -p "DMR mode 1 for dmr and 0 for pdt :" DMR
check_number $DMR
if [ $? -ne 0  ] ; then
	DMR=0
fi

if [ $DMR -gt 1 ] ; then
	DMR=0
	echo "input ERROR and set with PDT"
fi

datename=$(date +%Y%m%d-%H%M%S) 
cur='/opt/local/bin/VOS/cur/data'
if [ -e $cur/VOS.Config.db ] ; then
	cp $cur/VOS.Config.db $cur/VOS.Config.db.$datename.bak
else
	echo "db doesn't exist"
	exit
fi	

echo "--------------------------------------------------------"
echo "------------------sqlite3 running-----------------------"
sqlite3 $cur/VOS.Config.db <<EOF
insert or replace into Tbl_Config (PID,Tag,Key,Value,Comment) VALUES(0,"VOS", "LOGVIEW/MAXCOUNT","10","");
--update Tbl_Config set Value='0xff004f1f' where Tag='VOS' and Key='LOG/LOGLEVEL'
update Tbl_Config set Value='2/true/$TSC_IP:8000/$MSO_IP:6088' where Tag='VOS/SERVICES/IServices/TRT'  and Key='23:0';
update Tbl_Config set Value='2/true/$TSC_IP:8002/$MSO_IP:5002' where Tag='VOS/SERVICES/IServices/TRT' and Key='36:28672';
/*TSC �޸�*/
update Tbl_Config set Value='$TSC_ID'          where  Tag='TSC'and Key='TSC_ID';
update Tbl_Config set Value='$DMR'           where  Tag='TSC'and Key='DMRCmptMode';
update Tbl_Config set Value='$TSC_IP:0' where  Tag='TSC'and Key='TSC_ExtraNetIP';
/* Agent �����޸�*/
update Tbl_Config set Value='$MSO_IP' where  Tag='Agent'and Key='OM_SERVER_IP';
update Tbl_Config set Value='$MSO_IP' where  Tag='Agent'and Key='OM_SLAVE_IP';
update Tbl_Config set Value='$TSC_IP'  where  Tag='Agent'and Key='AGENT_IP';
update Tbl_Config set Value='$TSC_ID'        where  Tag='Agent'and Key='TSC_ID';
EOF

echo "-------------------------finished-----------------------"
echo "--------------------------------------------------------"