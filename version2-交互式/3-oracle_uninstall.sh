#! /bin/bash

#卸载
#一定要注意 ps -ef|grep -v grep|grep -v $$ ; $$（当前脚本的进程ID）


while ((1))
do
read -p "请输入oracle一级安装路径（例如: /u01）: " oracle_install_dir
if [[ ! -d ${oracle_install_dir} ]]; then
  echo -e "\033[1;1;5m 错误，该安装路径不存在！ \033[0m"
  read -p "是否重新输入路径？（y/n）: " res
  if [[ $res != 'y' && $res != 'yes' && $res != 'YES' ]]; then
    exit 1
  fi
else
  break 
fi
done



cnt=`ps -ef|grep oracle|grep -v grep|grep -v $$|wc -l`
if [ ! $cnt -eq 0 ]; then
  ps -ef|grep oracle|grep -v grep|grep -v $$|awk '{print $2}'|xargs kill -9
fi

sleep 5s

if [ -d /home/oracle/database ]; then
  mv /home/oracle/database oracle_backup/
fi

cnt=`egrep '^oracle' /etc/passwd|wc -l`
if [ ! $cnt -eq 0 ]; then
  userdel -r oracle
fi

cnt=`egrep '^oinstall' /etc/group|wc -l`
if [ ! $cnt -eq 0 ]; then
  groupdel oinstall
fi

cnt=`egrep '^dba' /etc/group|wc -l`
if [ ! $cnt -eq 0 ]; then
  groupdel dba
fi


if [ -f oracle_backup/sysctl.conf -a -f oracle_backup/limits.conf -a -f oracle_backup/login -a -f oracle_backup/profile ]; then
  \cp -rf oracle_backup/sysctl.conf /etc/sysctl.conf          
  \cp -rf oracle_backup/limits.conf /etc/security/limits.conf 
  \cp -rf oracle_backup/login       /etc/pam.d/login          
  \cp -rf oracle_backup/profile     /etc/profile
  /sbin/sysctl -p
  source /etc/profile  
fi  


if [ -f /etc/oraInst.loc ]; then
  rm -rf /etc/oraInst.loc
fi

if [ -f /etc/oratab ]; then
  rm -rf /etc/oratab
fi

if [ -d $oracle_install_dir ]; then
  rm -rf $oracle_install_dir
fi

echo -e "\033[1;1;5m 恭喜您，oracle卸载成功 \033[0m"
