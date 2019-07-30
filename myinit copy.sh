#! /bin/bash

first_start_node=""

### begin  3 个数据库都没有启动 ， 如果有一个启动了 ， 直接0 常规启动
mysql_host="mysql-0.galera.default.svc.cluster.local"  
if echo 'SELECT 1' | mysql -uroot -p123456a? -h${mysql_host}  &> /dev/null; then
    echo 'MySQL 0 has been started ...'
    exit 0
fi

mysql_host="mysql-1.galera.default.svc.cluster.local" 
if echo 'SELECT 1' | mysql -uroot -p123456a? -h${mysql_host}  &> /dev/null; then
    echo 'MySQL 1 has been started ...'
    exit 0
fi

mysql_host="mysql-2.galera.default.svc.cluster.local"
if echo 'SELECT 1' | mysql -uroot -p123456a? -h${mysql_host}  &> /dev/null; then
    echo 'MySQL 2 has been started ...'
    exit 0
fi

###### 
localname=$(hostname)

### 已经有数据了， 找到恢复的点
if [ -f /var/lib/mysql/ibdata1 ]; then
    echo "Galera - Determining recovery position..."
    set +e  ###
    start_pos_opt=$(/opt/galera/galera-start-pos.sh)
    set -e
    if [ $? -eq 0 ]; then
        echo "Galera recovery position: $start_pos_opt"
        echo $start_pos:$localname > /middle/$localname.txt
    else
        echo "FATAL - Galera recovery failed!"
        exit 1
    fi
fi

##如果数据库未创建 start_pos_opt 是 0
if [ ! -d "$DATADIR/mysql" ]; then
    echo 0 >> /middle/$localname.txt
fi    

###### 读目录下的文件， 直到3个节点都写入 ####
while [ "1" = "1" ]
do  
    mysql_start_pos_opt_files_len=`ls -l /middle/ | grep mysql |grep "^-"|wc -l`
    if [ $mysql_start_pos_opt_files_len = 3 ];then
        break
    fi

    echo "mysql_start_pos_opt_files_len is $mysql_start_pos_opt_files_len < 3"
    sleep 1
done


######   选举出  header 第一个启动， name 和 value 都最小的  ##########
mysql_header_name=
mysql_header_value=
for filename in $(ls /middle/ | grep mysql)
do
    start_pos_opt_tmp=$(cat /middle/$filename)
    echo "file: $filename $start_pos_opt_tmp"

    if [ ! -n "$mysql_header_name" ]; then
        mysql_header_value=$start_pos_opt_tmp
        mysql_header_name=$filename
        continue
    fi

    if [ "$start_pos_opt_tmp" -gt "$mysql_header_value" ]
    then
        echo ’change‘
        mysql_header_value=$start_pos_opt_tmp
        mysql_header_name=$filename
    else
        echo "$start_pos_opt_tmp  ---  $mysql_header_value "
        if [ "$start_pos_opt_tmp" -eq "$mysql_header_value" ] && [ "$mysql_header_name" \> "$filename" ]
        then
          echo '============='
          mysql_header_value=$start_pos_opt_tmp
          mysql_header_name=$filename
        fi
    fi
done

echo "first start mysql is : $mysql_header_name  $mysql_header_value"
if [ "$localname" ==  "$mysql_header_name" ];then
    echo " I am the first node is : $localname"
    `rm -rf /middle/mysql*`  #选举完成后， 删除生成的临时文件
    first_start_node="1"
    echo "is first node : $first_start_node"
    exit 0
fi

echo "I'm $localname , isn't the first node "
exit 1



echo "show global status 'WSREP_READY';" | mysql -uroot -p123456a? -hk8s3 -P31586








