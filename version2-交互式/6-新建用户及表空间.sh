#! /bin/bash
source /home/oracle/.bash_profile

username='phealth'

now_user=`whoami`
if [ ${now_user} != 'oracle' ]; then
  echo "请以oracle用户执行该脚本！"
  exit 1
fi

if [ -z ${username} ]; then
  echo "数据库用户名不能为空！"
  exit 1
fi




cat << EOF > /tmp/create_oracle_user.sql

--Oracle11g 脚本创建表空间和用户
--分为四步
--第1步：创建临时表空间
select '1. create temporary tablespace' as step_1 from dual;

create temporary tablespace ${username}_temp 
tempfile '${ORACLE_BASE}/oradata/${ORACLE_SID}/${username}_temp.dbf'
size 10m 
autoextend on 
next 10m maxsize 20480m 
extent management local; 

--第2步：创建数据表空间
select '2. create tablespace' as step_2 from dual;

create tablespace ${username} 
logging 
datafile '${ORACLE_BASE}/oradata/${ORACLE_SID}/${username}.dbf'
size 10m 
autoextend on 
next 10m maxsize 20480m 
extent management local; 

--第3步：创建用户并指定表空间
select '3. create user' as step_3 from dual;

create user ${username} identified by ${username} 
default tablespace ${username}
temporary tablespace ${username}_temp; 

--第4步：给用户授予权限
select '4. grant privileges to user' as step_4 from dual;
grant connect,resource,dba to ${username};

--查询当前表空间
select file_name,tablespace_name from dba_data_files where tablespace_name=upper('${username}') order by file_id;
exit;
EOF

sqlplus / as sysdba @/tmp/create_oracle_user.sql