#! /bin/bash

# 定义暂停函数

function get_char()
{
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
enable_=1
function pause()
{
    if [ "x$1" != "x" ]; then
        echo $1
    fi
    if [ $enable_ -eq 1 ]; then
        echo "按任意键继续……"
        char=`get_char`
    fi
}

######################################################################
#
#                       脚本说明
#
#  1-oracle_install_root.sh   执行该脚本可进行静默安装
#  2-oracle_install_oracle.sh 静默安装时会调用该脚本
#  3-uninstall.sh             遇到问题无法解决时就使用该脚本进行回退
#
######################################################################

# 自定义安装路径
oracle_install_dir="/u01"

#备份相关参数文件
mkdir oracle_backup/
\cp -rf /etc/sysctl.conf oracle_backup/
\cp -rf /etc/security/limits.conf oracle_backup/
\cp -rf /etc/pam.d/login oracle_backup/
\cp -rf /etc/profile oracle_backup/
echo -e "\033[1;1;5m 0.相关参数文件已备份到oracle_backup目录下 \033[0m"


date
echo "安装开始时间：`date`"

#设置系统oracle用户密码
cus_oracle_passwd=oracle

#检测共享内存是否不足1024M，否则修改共享内存值为1200M
shm_size=`df -m|grep '/dev/shm'|awk '{print $4}'`
if [ ${shm_size} -le 1024 ]; then
  flag=`cat /etc/fstab|grep '/dev/shm'|wc -l`
  if [ $flag -eq 1 ]; then
    hang=`cat /etc/fstab|grep -n '/dev/shm'|awk -F ':' '{print $1}'`
    sed -i "${hang}s/^/#/" /etc/fstab
    echo 'tmpfs /dev/shm tmpfs defaults,size=1200M 0 0' >> /etc/fstab
  else
    echo 'tmpfs /dev/shm tmpfs defaults,size=1200M 0 0' >> /etc/fstab
  fi
fi
mount -o remount /dev/shm

#检测服务器是否联网，是res=1 否res=0
ping_cnt=`ping -c 2 www.baidu.com|grep ttl|wc -l`
if [ $ping_cnt -eq 0 ]
  then res=0
else
  pingres=`ping -c 2 www.baidu.com|awk 'NR==6 {print $4}'`
  if [ $pingres -ge 0 ]; then
    res=1
  else
    res=0
  fi
fi

#取消下面的注释强制离线安装
res=0

#如果不能联网那就离线安装
if [ $res -eq 0 ]; then
  #yum离线安装oracle依赖组件 
  echo -e "\033[1;1;5m 网络异常，即将离线安装oracle依赖组件 \033[0m"
  yum localinstall -y rpms/*.rpm > /dev/null
  echo -e "\033[1;1;5m 1.完成yum离线安装oracle依赖组件 \033[0m"
else
  #yum在线安装oracle依赖组件
  echo -e "\033[1;1;5m 网络通畅，即将在线安装oracle依赖组件 \033[0m"
  mkdir -p /etc/yum.repos.d/bak
  mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  cp CentOS-Base.repo /etc/yum.repos.d/
  yum clean all
  yum makecache
  yum -y install binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel gcc gcc-c++ glibc-common glibc-devel glibc-headers ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel make sysstat unixODBC unixODBC-devel expect
  echo -e "\033[1;1;5m 1.完成yum在线安装oracle依赖组件 \033[0m"
  
  #还原yum文件/etc/yum.repos.d/
  mv /etc/yum.repos.d/bak/* /etc/yum.repos.d/
fi  


#创建oracle用户和oinstall/dba用户组
cnt=`egrep '^oracle' /etc/passwd|wc -l`
if [ ! $cnt -eq 0 ]; then
  userdel -r oracle
fi
groupadd oinstall
groupadd dba
useradd -g oinstall -G dba oracle
echo -e "\033[1;1;5m 2.完成创建oracle用户和oinstall/dba用户组 \033[0m"



#检测database目录是否已经在备份目录下，是则移动到目标目录，否则将oracle安装包解压到/home/oracle目录下
if [ -d backup/database ]; then
  mv backup/database /home/oracle/database
else
  if [ ! -e p13390677_112040_Linux-x86-64_1of7.zip -o ! -e p13390677_112040_Linux-x86-64_2of7.zip ]; then
    echo -e "\033[1;1;5m 错误，缺少安oracle装包! 请修复错误后重新执行该安装脚本\033[0m"
    pause
    sh 3-oracle_uninstall.sh
  fi
  echo -e "\033[1;1;5m 正在解压安装包……\033[0m"
  unzip -d /home/oracle p13390677_112040_Linux-x86-64_1of7.zip > /dev/null
  unzip -d /home/oracle p13390677_112040_Linux-x86-64_2of7.zip > /dev/null
fi  
  echo -e "\033[1;1;5m 3.完成将oracle安装包解压到/home/oracle目录下 \033[0m"
  

#修改/home/oracle/database文件夹权限
chown -R oracle:oinstall /home/oracle/database
echo -e "\033[1;1;5m 4.完成修改/home/oracle/database文件夹权限 \033[0m"



#设置oracle用户的密码为orcl
echo oracle:$cus_oracle_passwd|chpasswd
sleep 1s
echo -e "\033[1;1;5m 5.完成修改oracle密码 \033[0m"



#修改内核参数/etc/sysctl.conf
cat << EOF >> /etc/sysctl.conf
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 4294967296
kernel.shmmax = 68719476736
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 6291456
net.core.rmem_max = 12582912
net.core.wmem_default = 6291456
net.core.wmem_max = 12582912
EOF
echo -e "\033[1;1;5m 6.完成内核参数修改 \033[0m"



#使设置生效
/sbin/sysctl -p

#修改用户限制 /etc/security/limits.conf
cat << EOF >> /etc/security/limits.conf
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
EOF
echo -e "\033[1;1;5m 7.完成用户打开进程数和文件数限制修改 \033[0m"



#修改/etc/pam.d/login
cat << EOF >> /etc/pam.d/login
session required /lib/security/pam_limits.so
session required pam_limits.so
EOF
echo -e "\033[1;1;5m 8.完成/etc/pam.d/login登录参数修改 \033[0m"



#修改/etc/profile
cat << EOF >> /etc/profile
if [ $USER = "oracle" ]; then
if [ $SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi
fi
EOF


#使设置生效
source /etc/profile
echo -e "\033[1;1;5m 9.完成/etc/profile限制修改并使限制生效 \033[0m"



#创建安装目录(可根据情况，选择比较多空间的目录创建)
mkdir -p $oracle_install_dir/app
chown -R oracle:oinstall $oracle_install_dir/app
chmod -R 775 $oracle_install_dir/app
echo -e "\033[1;1;5m 10.完成oracle home目录创建 \033[0m"



#创建/etc/oraInst.loc文件,内容如下
touch /etc/oraInst.loc
cat <<\EOF > /etc/oraInst.loc
Inventory_loc=$oracle_install_dir/app/oracle/oraInventory
inst_group=oinstall
EOF
echo -e "\033[1;1;5m 11.完成/etc/oraInst.loc文件创建 \033[0m"



#更改文件的权限
chown oracle:oinstall /etc/oraInst.loc
chmod 664 /etc/oraInst.loc
cp *.sh /home/oracle/
chown oracle.oinstall /home/oracle/*.sh
chmod +x /home/oracle/*.sh
chmod u+w /etc/sudoers
echo "oracle    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
su - oracle -c "/home/oracle/2-oracle_install_oracle.sh"
sed -i '/oracle    ALL=(ALL)/d' /etc/sudoers
chmod u-w /etc/sudoers
