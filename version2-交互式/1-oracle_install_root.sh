#! /bin/bash

######################################################################
#
#                       脚本说明
#  0 执行前需赋予以下3个脚本可执行权限
#  1-oracle_install_root.sh   执行该脚本可进行静默安装
#  2-oracle_install_oracle.sh 静默安装时会调用该脚本
#  3-uninstall.sh             遇到问题无法解决时就使用该脚本进行回退
#
######################################################################

echo "安装开始时间：`date`" >> /tmp/oracle_info.txt
echo "安装开始时间：`date`"
chmod 777 /tmp/oracle_info.txt

# 检查相关安装文件是否存在
# 1. 检查oracle安装包是否存在
if [ ! -e p13390677_112040_Linux-x86-64_1of7.zip -o ! -e p13390677_112040_Linux-x86-64_2of7.zip ]; then
    echo -e "\033[1;1;5m 错误，缺少安oracle装包! 请修复错误后重新执行该安装脚本!!!\033[0m"
    exit 1
fi

# 2. 检查脚本是否存在
if [ ! -e 2-oracle_install_oracle.sh ]; then
  echo -e "\033[1;1;5m 错误，2-oracle_install_oracle.sh脚本文件不存在!!!\033[0m"
  exit 1
fi

# 3. 检查脚本是否存在
if [ ! -e 3-oracle_uninstall.sh ]; then
  echo -e "\033[1;1;5m 错误，3-oracle_uninstall.sh脚本文件不存在!!!\033[0m"
  exit 1
fi


# 4. 检查阿里云repo文件是否存在
if [ ! -e CentOS-Base.repo ]; then
  echo -e "\033[1;1;5m 错误，CentOS-Base.repo文件不存在!!!\033[0m"
  exit 1
fi

# 5. 检查rpms依赖包文件夹是否存在
if [ ! -d rpms ]; then
  echo -e "\033[1;1;5m 错误，依赖包文件夹rpms不存在!!!\033[0m"
  exit 1
fi

# 6. 检查脚本是否存在
if [ ! -e 4-oracle_backup_database.sh ]; then
  echo -e "\033[1;1;5m 错误，4-oracle_backup_database.sh文件不存在!!!\033[0m"
  exit 1
fi

# 7. 检查系统内存是否小于2500M
mem_total_size=`cat /proc/meminfo |grep MemTotal:|grep -v $$|awk '{printf("%.0f\n", $2/1024)}'`
if [ ${mem_total_size} -le 2500 ]; then
  echo -e "\033[1;1;5m 错误，内存最低要求2500M，当前内存为${mem_total_size}M!!!\033[0m"
  exit 1
fi

# 定义oracle安装目录
while (( 1 ))
do
read -p "请输入oracle一级安装路径（默认: /u01）: " oracle_install_dir
if [[ -z ${oracle_install_dir} ]]; then
  echo "您的输入为空，使用一级安装路径: /u01" 
  oracle_install_dir="/u01"
  echo "oracle一级安装路径: ${oracle_install_dir}" >> /tmp/oracle_info.txt
  break
else
  read -p "您输入的oracle一级路径为: ${oracle_install_dir} 请确认（y/n）: " res1
  if [[ ${res1} != 'y' && ${res1} != 'yes' && ${res1} != 'YES' ]]; then
      exit 1
  else
    echo "oracle一级安装路径: ${oracle_install_dir}" >> /tmp/oracle_info.txt
    break
  fi
fi
done
mkdir -p ${oracle_install_dir}/app



# 备份参数文件
mkdir -p oracle_backup/
\cp -rf /etc/sysctl.conf oracle_backup/
\cp -rf /etc/security/limits.conf oracle_backup/
\cp -rf /etc/pam.d/login oracle_backup/
\cp -rf /etc/profile oracle_backup/
echo -e "\033[1;1;5m 0.相关参数文件已备份到oracle_backup目录下 \033[0m"



# 设置系统oracle用户密码
while (( 1 ))
do
read -p "请输入linux oracle用户密码（默认: oracle）: " pass1
if [[ -z ${pass1} ]]; then
  echo "您的输入为空，使用默认密码: oracle" 
  pass1="oracle"
  echo "linux oracle用户密码: ${pass1}" >> /tmp/oracle_info.txt
  break
else  
  read -p "请再次输入linux oracle用户密码: " pass2
  if [[ ${pass1} == ${pass2}  && ! -z ${pass1} ]]; then
    echo "linux oracle用户密码: ${pass1}" >> /tmp/oracle_info.txt
    cus_oracle_passwd=${pass1}
    break
  else 
    echo -e "\033[1;1;5m 错误：两次密码不一致，请重新输入! \033[0m"
  fi
fi 
done


# 选择安装依赖包方式
while (( 1 ))
do
read -p "请选择安装依赖包方式，默认离线安装（0:离线安装 1:在线安装 ）: " res
if [[ -z ${res} ]]; then
  res=0
  echo "您选择的是离线安装方式"
  break  
elif [ ${res} -ne 1 -a ${res} -ne 0 ]; then
  echo -e "\033[1;1;5m 输入有误，请重新输入!!! \033[0m"
  continue
elif [ ${res} -eq 1 ]; then
  echo "您选择的是在线安装方式!"
  break
else
  echo "您选择的是离线安装方式!"
  break   
fi
done


# 检测服务器是否联网，是res=1 否res=0
if [ ${res} -eq 1 ]; then
  echo "正在检测网络是否正常"
  ping_cnt=`ping -c 2 www.baidu.com|grep ttl|wc -l`
  if [ ${ping_cnt} -eq 0 ]
    then res=0
  else
    pingres=`ping -c 2 www.baidu.com|awk 'NR==6 {print $4}'`
    if [ ${pingres} -ge 0 ]; then
      res=1
    else
      res=0
      echo -e "\033[1;1;5m 系统检测服务器无法联网，强制离线安装依赖包！ \033[0m"
    fi
  fi
fi


# 服务器非联网状态离线安装
if [ ${res} -eq 0 ]; then
  # yum离线安装oracle依赖组件
  echo -e "\033[1;1;5m 即将离线安装oracle依赖组件 \033[0m"
  yum localinstall -y rpms/*.rpm --nogpgcheck --skip-broken > /dev/null
  echo -e "\033[1;1;5m 1. 完成yum离线安装oracle依赖组件 \033[0m"
else
  # yum在线安装oracle依赖组件
  echo -e "\033[1;1;5m 网络通畅，即将在线安装oracle依赖组件 \033[0m"
  mkdir -p /etc/yum.repos.d/bak
  \mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  \cp -rf CentOS-Base.repo /etc/yum.repos.d/
  yum clean all
  yum makecache
  yum -y install net-tools glibc-*.i686 glibc-devel*.i386 glibc-devel.i686 gcc gcc-c++ make binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel elfutils-libelf-devel-static glibc glibc-common glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel numactl-devel sysstat unixODBC unixODBC-devel kernelheaders ksh pcre-devel readline rlwrap
  echo -e "\033[1;1;5m 1. 完成yum在线安装oracle依赖组件 \033[0m"
  # 还原yum文件/etc/yum.repos.d/
  \mv -f /etc/yum.repos.d/bak/* /etc/yum.repos.d/
fi  


# 设置共享内存大小为系统的80%+200M
shm_size=`cat /proc/meminfo |grep MemTotal:|grep -v $$|awk '{printf("%.0f\n", $2/1024*0.8+200)}'`
# 如果shm_size小于2000M，则强制设置为2100M
if [ ${shm_size} -le 2000 ]; then
  shm_size=2100
fi
flag=`cat /etc/fstab|grep '/dev/shm'|wc -l`
if [ ${flag} -eq 1 ]; then
  line=`cat /etc/fstab|grep -n '/dev/shm'|awk -F ':' '{print $1}'`
  # 注释原shm配置
  sed -i "${line}s/^/#/" /etc/fstab
  echo "tmpfs /dev/shm tmpfs defaults,size=${shm_size}M 0 0" >> /etc/fstab
else
  echo "tmpfs /dev/shm tmpfs defaults,size=${shm_size}M 0 0" >> /etc/fstab
fi
mount -o remount /dev/shm


# 创建oracle用户和oinstall/dba用户组
cnt=`egrep '^oracle' /etc/passwd|wc -l`
if [ ! ${cnt} -eq 0 ]; then
  userdel -r oracle
fi
groupadd oinstall
groupadd dba
useradd -g oinstall -G dba oracle
echo -e "\033[1;1;5m 2. 完成创建oracle用户和oinstall/dba用户组 \033[0m"


# 检测备份目录下是否存在database目录，是则移动到/home/oracle目录下，否则将oracle安装包解压到/home/oracle目录下
if [ -d oracle_backup/database ]; then
  \mv oracle_backup/database /home/oracle/database
else
  echo -e "\033[1;1;5m 正在解压安装包……\033[0m"
  unzip -d /home/oracle p13390677_112040_Linux-x86-64_1of7.zip > /dev/null
  unzip -d /home/oracle p13390677_112040_Linux-x86-64_2of7.zip > /dev/null
fi  
echo -e "\033[1;1;5m 3. 完成将oracle安装包解压到/home/oracle目录下 \033[0m"
  

# 修改/home/oracle/database文件夹权限
chown -R oracle:oinstall /home/oracle/database
echo -e "\033[1;1;5m 4. 完成修改/home/oracle/database文件夹权限 \033[0m"


# 设置oracle用户的密码为orcl
echo oracle:${cus_oracle_passwd}|chpasswd
sleep 1s
echo -e "\033[1;1;5m 5.完成修改oracle密码 \033[0m"


# 修改内核参数/etc/sysctl.conf
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
sysctl -p


# 修改用户限制 /etc/security/limits.conf
cat << EOF >> /etc/security/limits.conf
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
EOF
echo -e "\033[1;1;5m 7.完成用户打开进程数和文件数限制修改 \033[0m"


# 修改/etc/pam.d/login
cat << EOF >> /etc/pam.d/login
session required /lib64/security/pam_limits.so
session required pam_limits.so
EOF
echo -e "\033[1;1;5m 8.完成/etc/pam.d/login登录参数修改 \033[0m"


# 修改/etc/profile
cat << EOF >> /etc/profile
if [ ${USER} = "oracle" ]; then
  if [ ${SHELL} = "/bin/ksh" ]; then
    ulimit -p 16384
    ulimit -n 65536
  else
    ulimit -u 16384 -n 65536
  fi
fi
oracle_install_dir=${oracle_install_dir}
EOF


# 使设置生效
source /etc/profile
echo -e "\033[1;1;5m 9.完成/etc/profile限制修改并使限制生效 \033[0m"

# 创建安装目录(可根据情况，选择比较多空间的目录创建)
mkdir -p ${oracle_install_dir}/app
chown -R oracle:oinstall ${oracle_install_dir}/app
chmod -R 775 ${oracle_install_dir}/app
echo -e "\033[1;1;5m 完成oracle home目录创建 \033[0m"


#创建/etc/oraInst.loc文件,内容如下
touch /etc/oraInst.loc
cat <<\EOF > /etc/oraInst.loc
Inventory_loc=${oracle_install_dir}/app/oracle/oraInventory
inst_group=oinstall
EOF
echo -e "\033[1;1;5m 11.完成/etc/oraInst.loc文件创建 \033[0m"


#更改文件的权限
chown oracle:oinstall /etc/oraInst.loc
chmod 664 /etc/oraInst.loc
\cp -rf *.sh /home/oracle/
chown oracle.oinstall /home/oracle/*.sh
chmod +x /home/oracle/*.sh
chmod u+w /etc/sudoers
echo "oracle    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
su - oracle -c "/home/oracle/2-oracle_install_oracle.sh"
sed -i '/oracle    ALL=(ALL)/d' /etc/sudoers
chmod u-w /etc/sudoers
echo "安装结束时间：`date`"
echo "安装结束时间：`date`" >> /tmp/oracle_info.txt
\mv /tmp/oracle_info.txt ./
echo "数据库相关信息请查看 oracle_info.txt"




