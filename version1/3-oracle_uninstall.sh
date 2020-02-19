#! /bin/bash
#卸载
#一定要注意 ps -ef|grep -v grep|grep -v $$ ; $$（当前脚本的进程ID）
cnt=`ps -ef|grep oracle|grep -v grep|grep -v $$|wc -l`
if [ ! $cnt -eq 0 ]; then
  ps -ef|grep oracle|grep -v grep|grep -v $$|awk '{print $2}'|xargs kill -9
fi

if [ -d /home/oracle/database ]; then
  mv /home/oracle/database /root/oracle_install_pkg/backup/database
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

cd /root/oracle_install_pkg
if [ -f backup/sysctl.conf -a -f backup/limits.conf -a -f backup/login -a -f backup/profile ]; then
  \cp -rf /root/oracle_install_pkg/backup/sysctl.conf /etc/sysctl.conf          
  \cp -rf /root/oracle_install_pkg/backup/limits.conf /etc/security/limits.conf 
  \cp -rf /root/oracle_install_pkg/backup/login       /etc/pam.d/login          
  \cp -rf /root/oracle_install_pkg/backup/profile     /etc/profile
  /sbin/sysctl -p
  source /etc/profile  
fi  


if [ -f /etc/oraInst.loc ]; then
  rm -rf /etc/oraInst.loc
fi

if [ -f /etc/oratab ]; then
  rm -rf /etc/oratab
fi

if [ -d /u01 ]; then
  rm -rf /u01
fi

echo -e "\033[1;1;5m 恭喜您，oracle卸载成功 \033[0m"
