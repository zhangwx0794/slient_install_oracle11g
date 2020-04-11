#! /bin/bash
source /home/oracle/.bash_profile

sys_pwd=oracle
sid=orcl

cat << EOF > /home/oracle/oracle_init_config.sql
-- 1. 设置空表强制分配segment
alter system set deferred_segment_creation=false;
show parameter deferred_segment_creation;

-- 2. 设置sga大小 系统内存的70%
alter system set memory_max_target=${sga_size}M scope=spfile;
alter system set memory_target=${sga_size}M scope=spfile;

-- 3. 设置pga大小 系统内存的10%
alter system set pga_aggregate_target=${pga_size}M scope=spfile;

-- 4. 修改最大连接数为1000
alter system set processes=1000 scope=spfile;

-- 5. 修改最大会话数为(1000*1.1+5)=1105
alter system set sessions=1105 scope=spfile;
shutdown immediate;
startup;
show parameter sga;
show parameter pga;
show parameter process;
show parameter session;
exit;
EOF

su - oracle << EOF
source /home/oracle/.bash_profile
sqlplus  sys/${sys_pwd} as sysdba@${sid}  @/home/oracle/oracle_init_config.sql
EOF

echo "oracle 初始化完成！"
