#! /bin/bash
workdir=$PWD
source /etc/profile
#-----------------------------------------------------------------
#                          参数设置-开始
#-----------------------------------------------------------------

# oracle_install_dir="/u01"

#设置全局数据库名
while ((1))
do
read -p "请输入数据库名（默认：orcl）: " cus_gdbname
if [[ -z $cus_gdbname ]]; then
  echo "您的输入为空，使用默认数据库名称: orcl" 
  cus_gdbname=orcl
  echo "oracle数据库名称: $cus_gdbname" >> /tmp/oracle_info.txt
  break
else
  read -p "您输入的数据库名称为: $cus_gdbname 请确认（y/n）: " res2
  if [[ $res2 != 'y' && $res2 != 'yes' && $res2 != 'YES' ]]; then
    continue
  else
    echo "oracle数据库名称: $cus_gdbname" >> /tmp/oracle_info.txt
    break
  fi
fi
done
#cus_gdbname=orcl

#设置实例名
while ((1))
do
read -p "请输入实例名称（默认：orcl）: " cus_instname
if [[ -z $cus_instname ]]; then
  echo "您的输入为空，使用默认实例名称: orcl" 
  cus_instname=orcl
  echo "oracle实例名称: $cus_instname" >> /tmp/oracle_info.txt
  break
else
  read -p "您输入的实例名称为: $cus_instname 请确认（y/n）: " res3
  if [[ $res3 != 'y' && $res3 != 'yes' && $res3 != 'YES' ]]; then
    continue
  else
    echo "oracle实例名称: $cus_instname" >> /tmp/oracle_info.txt
    break
  fi
fi
done
#cus_instname=orcl

#设置ORACLE_BASE
cus_oracle_base=$oracle_install_dir/app/oracle

#设置ORACLE_HOME
cus_oracle_home=$oracle_install_dir/app/oracle/product/11.2.0/db_1

#设置INVENTORY_LOCATION
cus_inventory_location=$oracle_install_dir/app/oracle/oraInventory  

#设置fast_recovery_area
cus_fast_recovery_area=$oracle_install_dir/app/oracle/fast_recovery_area

#设置oracle dataLocation
cus_oracle_dataLocation=$oracle_install_dir/app/oracle/oradata 

#获取本机IP地址
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
    cnt=`ifconfig|grep "inet "|grep $ip_addr|wc -l`
    if [ $cnt -eq 0 ]; then
      echo "本机不存在该IP地址，请重新输入！"
    else
      echo "oracle数据库IP地址: $ip_addr" >> /tmp/oracle_info.txt
      break;
    fi
  fi
fi
done

read -p "oracle设置监听地址需要，请输入oracle监听端口（默认：1521）: " listen_port
if [[ -z $listen_port ]]; then
  listen_port=1521
else
  echo "oracle数据库监听端口: $listen_port" >> /tmp/oracle_info.txt  
fi  


#设置oracle数据库sys/system等用户密码
while ((1))
do
read -p "请输入oracle数据库sys/system等用户密码（默认：oracle）: " cus_oracledb_user_pwd
if [[ -z $cus_oracledb_user_pwd ]]; then
  echo "您的输入为空，使用默认密码: oracle" 
  cus_oracledb_user_pwd=oracle
  echo "oracle/sys/system数据库用户密码: $cus_oracledb_user_pwd" >> /tmp/oracle_info.txt
  break
else
  read -p "您输入的密码为: $cus_oracledb_user_pwd 请确认（y/n）: " res3
  if [[ $res3 != 'y' && $res3 != 'yes' && $res3 != 'YES' ]]; then
    continue
  else
    echo "oracle/sys/system数据库用户密码: $cus_oracledb_user_pwd" >> /tmp/oracle_info.txt
    break
  fi
fi
done
#cus_oracledb_user_pwd=oracle


#-----------------------------------------------------------------
#                         参数设置-结束
#-----------------------------------------------------------------

echo "############################################################"
echo "#   "
echo "#                       安装说明"
echo "#   "
echo "#   默认数据库安装到目录：$oracle_install_dir/app/"
echo "#   "
echo "#   全局数据库名：$cus_gdbname   "
echo "#   "
echo "#   数据库实例名：$cus_instname  "
echo "#   "
echo "#   ORACLE_BASE：$cus_oracle_base"
echo "#   "
echo "#   ORACLE_HOME：$cus_oracle_home  "
echo "#   "
echo "#   recoveryLocation：$cus_inventory_location "
echo "#   "
echo "#   dataLocation：$cus_oracle_dataLocation "
echo "#   "
echo "#   oracle数据库sys/system等用户密码：$cus_oracledb_user_pwd "
echo "#   "
echo "############################################################"

#设置oracle环境变量
cat << EOF >> /home/oracle/.bash_profile
export ORACLE_BASE=$cus_oracle_base
export ORACLE_SID=$cus_instname
EOF

#使设置生效
source /home/oracle/.bash_profile
echo -e "\033[1;1;5m 12.完成环境变量设置，基础环境设置完毕 \033[0m"


#复制响应文件模板
mkdir /home/oracle/etc/
cp /home/oracle/database/response/* /home/oracle/etc/

#设置响应文件权限
chmod 700 /home/oracle/etc/*.rsp
echo -e "\033[1;1;5m 13.完成复制响应文件模板并完成权限修改 \033[0m"


#修改数据库静默安装配置文件
cat << EOF > /home/oracle/etc/db_install.rsp
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0
#标注响应文件版本，这个版本必须和要,安装的数据库版本相同，安装检验无法通过,不能更改
oracle.install.option=INSTALL_DB_AND_CONFIG
#只装数据库软件INSTALL_DB_SWONLY;安装数据库软件并建库INSTALL_DB_AND_CONFIG
ORACLE_HOSTNAME=$HOSTNAME                  
#指定操作系统主机名，通过hostname命令获得
ORACLE_BASE=$cus_oracle_base          
#设置ORALCE_BASE的路径
ORACLE_HOME=$cus_oracle_home       
#设置ORALCE_HOME的路径
oracle.install.db.InstallEdition=EE     
#选择Oracle安装数据库软件的版本（企业版EE，标准版SE，标准版1SEONE），不同的版本功能不同
UNIX_GROUP_NAME=oinstall
#指定oracle inventory目录的所有者，通常会是oinstall或者dba
INVENTORY_LOCATION=$cus_inventory_location        
#指定产品清单oracle inventory目录的路径,如果是Win平台下可以省略
SELECTED_LANGUAGES=en,zh_CN,zh_TW       
#指定数据库语言，可以选择多个，用逗号隔开。选择en, zh_CN(英文和简体中文)
oracle.install.db.EEOptionsSelection=false
oracle.install.db.optionalComponents=oracle.rdbms.partitioning:11.2.0.4.0,oracle.oraolap:11.2.0.4.0,oracle.rdbms.dm:11.2.0.4.0,oracle.rdbms.dv:11.2.0.4.0,oracle.rdbms.lbac:11.2.0.4.0,oracle.rdbms.rat:11.2.0.4.0
oracle.install.db.DBA_GROUP=dba
#指定拥有OSDBA权限的用户组，通常会是dba组
oracle.install.db.OPER_GROUP=oinstall
#指定拥有OSOPER权限的用户组，通常会是oinstall组
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE  
#选择数据库的用途，一般用途/事物处理，数据仓库  
oracle.install.db.config.starterdb.globalDBName=$cus_gdbname  
#指定GlobalName
oracle.install.db.config.starterdb.SID=$cus_instname            
#指定SID
oracle.install.db.config.starterdb.characterSet=ZHS16GBK 
#选择字符集，不正确的字符集会给数据显示和存储带来麻烦无数
oracle.install.db.config.starterdb.memoryOption=true     
#自动管理内存的最小内存(M)，也就是SGA_TARGET和PAG_AGGREGATE_TARGET
oracle.install.db.config.starterdb.memoryLimit=1024       
#指定Oracle自动管理内存的大小，最小是256MB
oracle.install.db.config.starterdb.password.ALL=$cus_oracledb_user_pwd   
#设定所有数据库用户使用同一个密码
oracle.install.db.config.starterdb.enableSecuritySettings=true 
#是否启用安全设置 
oracle.install.db.config.starterdb.installExampleSchemas=false 
#是否载入模板
oracle.install.db.config.starterdb.control=DB_CONTROL    
#数据库本地管理工具DB_CONTROL，远程集中管理工具GRID_CONTROL
oracle.install.db.config.starterdb.automatedBackup.enable=false
#设置自动备份，和OUI里的自动备份一样。
oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE   
#自动备份，要求指定使用的文件系统存放数据库文件还是ASM
oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=$cus_fast_recovery_area
#使用文件系统存放数据库文件才需要指定备份恢复目录
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=$cus_oracle_dataLocation
#使用文件系统存放数据库文件才需要指定数据文件、控制文件、Redo log的存放目录 
DECLINE_SECURITY_UPDATES=TRUE          
#必须指定为true，否则会提示错误,不管是否正确填写了邮件地址
oracle.install.db.CLUSTER_NODES=
oracle.install.db.isRACOneInstall=
oracle.install.db.racOneServiceName=
oracle.install.db.config.starterdb.password.SYS=
oracle.install.db.config.starterdb.password.SYSTEM=
oracle.install.db.config.starterdb.password.SYSMAN=
oracle.install.db.config.starterdb.password.DBSNMP=
oracle.install.db.config.starterdb.gridcontrol.gridControlServiceURL=
oracle.install.db.config.starterdb.automatedBackup.osuid=
oracle.install.db.config.starterdb.automatedBackup.ospwd=  	
oracle.install.db.config.asm.diskGroup=
oracle.install.db.config.asm.ASMSNMPPassword=
MYORACLESUPPORT_USERNAME=
MYORACLESUPPORT_PASSWORD=
SECURITY_UPDATES_VIA_MYORACLESUPPORT=
PROXY_HOST=
PROXY_PORT=
PROXY_USER=
PROXY_PWD=
PROXY_REALM=
COLLECTOR_SUPPORTHUB_URL=
oracle.installer.autoupdates.option=
oracle.installer.autoupdates.downloadUpdatesLoc=
AUTOUPDATES_MYORACLESUPPORT_USERNAME=
AUTOUPDATES_MYORACLESUPPORT_PASSWORD=
EOF
echo -e "\033[1;1;5m 14.完成修改数据库静默安装配置文件 \033[0m"

#静默安装Oracle软件，可根据提示查看日志
/home/oracle/database/runInstaller -silent -responseFile /home/oracle/etc/db_install.rsp -ignorePrereq
echo -e "\033[1;1;5m \n15.系统正在安装oracle数据库 \033[0m"

#循环每2s监听数据库安装日志，根据关键字"Read: 100%"和"Exit Status is 0"判断安装是否完成
#flag = 0说明安装没有出错，flag=1说明安装过程有报错
flag=0
date_start=`date +%s`
while (( 1 ))
do
  if [ -f $oracle_install_dir/app/oracle/oraInventory/logs/installActions*.log ]; then
    cnt1=`grep -rn "Read: 100%" $oracle_install_dir/app/oracle/oraInventory/logs/installActions*.log|wc -l`
    cnt2=`grep -rn "Exit Status is 0" $oracle_install_dir/app/oracle/oraInventory/logs/installActions*.log|wc -l`
    date_end=`date +%s`
	if [[ $cnt1 -eq 1 && $cnt2 -eq 1 ]]; then
	  sleep 1s
      break
	elif [ $(($date_end - $date_start)) -gt 3600 ]; then
	  #如果安装时间超过1小时依然不成功，则标记flag=1退出循环
	  flag=1
	  break
    fi
  fi
  sleep 2s
done

#判断flag是否等于1，是则执行卸载脚本
if [ $flag -eq 1 ]; then
  sudo $workdir/3-uninstall.sh
  echo -e "\033[1;1;5m !!!数据库安装失败，已卸载回退!!! \033[0m"
  exit
fi



#使用root用户执行root.sh（使用expect实现在不切换用户的情况下使用root用户执行命令）
sudo $oracle_install_dir/app/oracle/oraInventory/orainstRoot.sh
sudo $oracle_install_dir/app/oracle/product/11.2.0/db_1/root.sh
echo -e "\033[1;1;5m 成功执行$oracle_install_dir/app/oracle/product/11.2.0/db_1/root.sh \033[0m"


#修改oracle环境变量文件
cat <<\EOF >> /home/oracle/.bash_profile
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=.:${PATH}:$HOME/bin:$ORACLE_HOME/bin
export PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/JRE
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/JRE/lib
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export LIBPATH=${CLASSPATH}:$ORACLE_HOME/lib:$ORACLE_HOME/ctx/lib
export ORACLE_OWNER=oracle
export SPFILE_PATH=$ORACLE_HOME/dbs
export ORA_NLS10=$ORACLE_HOME/nls/data
EOF


#使设置生效
source /home/oracle/.bash_profile
echo -e "\033[1;1;5m 设置oracle环境变量完毕 \033[0m"

sleep 1s

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

#检查数据库实例是否启动成功
cnt=`ps -ef|grep ora_smon|grep -v grep|wc -l`
if [ $cnt == 1 ] ; then
  echo -e "\033[1;1;5m 16.Oracle实例创建并启动成功，可登陆验证！ \033[0m"
else
  echo -e "\033[1;1;5m 16.Oracle实例创建失败 \033[0m"
fi



