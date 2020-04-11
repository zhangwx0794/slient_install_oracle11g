#!/bin/bash
source /home/oracle/.bash_profile


function qywx_inform()
{
  curl "${qywx_webhook}" \
   -H 'Content-Type: application/json' \
   -d "
   {
        \"msgtype\": \"text\",
        \"text\": {
            \"content\": \"${inform_content}\"
        }
   }"
}

if [ -z "$1" ]; then
  echo "oracle system用户密码不能为空!!!"
  exit 1
fi

TIMESTAMP=`date +%Y%m%d`
deletime=`date -d "7 days ago" +%Y%m%d`
file=/boss/bak/oracle
username=system
system_pwd="$1"
sid=orcl

# 配置企业微信机器人地址
qywx_webhook=''



expdp_dir=$file/$TIMESTAMP
mkdir -p $expdp_dir
chown -R oracle.oinstall ${file}

# exp默认不会导出空表，使用expdp的好处是可以导出空表
cat << EOF > /boss/shell/oracle_backup_full_db.sql
create or replace directory expdp_dir as '${expdp_dir}';
grant all on directory expdp_dir to public;
exit;
EOF

cat << EOF > /boss/shell/oracle_language_temp.sql
select userenv('language') from dual;
exit;
EOF

su - oracle << EOF
export NLS_LANG=`sqlplus ${username}/${system_pwd}@${sid} @/boss/shell/oracle_language_temp.sql|grep USERENV -A 2|tail -n 1`
sqlplus  ${username}/${system_pwd}@${sid} @/boss/shell/oracle_backup_full_db.sql
expdp ${username}/${system_pwd}@${sid} DIRECTORY=expdp_dir DUMPFILE=exp_full_database_${TIMESTAMP}.dmp LOGFILE=exp_full_database_${TIMESTAMP}.log FULL=y
cd $expdp_dir
zip -r exp_full_database_${TIMESTAMP}.zip  exp_full_database_${TIMESTAMP}.dmp
rm -rf exp_full_database_${TIMESTAMP}.dmp
rm -rf $file/$deletime
EOF

backup_file_size=`du -sh $expdp_dir|awk '{print $1}'`


if [ ! -z "${qywx_webhook}" ]; then
  inform_content="`ifconfig|grep 'inet '|grep -v '127.0.0.1'|head -1|awk '{print $2}'` Oracle数据库备份完成！ 大小$backup_file_size" 
  qywx_inform
fi

# 远程备份数据库
# scp -r $file/$TIMESTAMP root@192.168.0.4:/data/backup/jydba
