#! /bin/bash

source /home/oracle/.bash_profile
cus_oracledb_user_pwd=oracle
#设置本机IP地址
while ((1))
do
read -p "oracle设置监听地址需要，请输入本机IP地址: " ip_addr
if [[ -z $ip_addr ]]; then
  echo "您的输入为空，请重新输入！"
else
  cnt=`echo $ip_addr.|egrep '^[1-9]{1,3}.([0-9]{1,3}.){3}$'|wc -l`
  if [ $cnt -eq 0 ]; then
    echo "您输入的IP地址不符合IP地址规范，请重新输入！"
  else
    cnt=`ifconfig |grep $ip_addr|wc -l`
    if [ $cnt -eq 0 ]; then
      echo "本机不存在该IP地址，请重新输入！"
    else
      break;
    fi
  fi
fi
done

read -p "oracle设置监听地址需要，请输入oracle监听端口（默认：1521）: " listen_port
if [[ -z $listen_port ]]; then
  listen_port=1521
fi  

# 修改默认端口为listen_port

cat << EOF > /tmp/alter_oracle_listen_port.sql
alter system set local_listener='(ADDRESS=(PROTOCOL=TCP)(HOST=${ip_addr})(PORT=${listen_port}))';
exit 0;
EOF

sqlplus sys/$cus_oracledb_user_pwd as sysdba @/tmp/alter_oracle_listen_port.sql

lsnrctl stop
sleep 5s
sed -i 's/(HOST = .*)(PORT = .*))/(HOST = '"${ip_addr}"')(PORT = '"${listen_port}"'))/g' $ORACLE_HOME/network/admin/listener.ora
sed -i 's/(HOST = .*)(PORT = .*))/(HOST = '"${ip_addr}"')(PORT = '"${listen_port}"'))/g' $ORACLE_HOME/network/admin/tnsnames.ora
lsnrctl start
echo "默认端口已修改为${listen_port}"



