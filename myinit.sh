#! /bin/bash

first_start_node=""

log() {
	local msg="myinit.sh: $@"
	echo "$msg" >&2
}

### begin  3 个数据库都没有启动 ， 如果有一个启动了 ， 直接0 常规启动
mysql_host="mysql-0.galera.default.svc.cluster.local"  
if echo 'SELECT 1' | mysql -uroot -p123456a? -h${mysql_host}  &> /dev/null; then
    log 'MySQL 0 has been started ...'
    echo "MySQL 0 has been started ..."
    exit 0
fi

mysql_host="mysql-1.galera.default.svc.cluster.local" 
if echo 'SELECT 1' | mysql -uroot -p123456a? -h${mysql_host}  &> /dev/null; then
    log 'MySQL 1 has been started ...'
    echo "MySQL 1 has been started ..."
    exit 0
fi

mysql_host="mysql-2.galera.default.svc.cluster.local"
if echo 'SELECT 1' | mysql -uroot -p123456a? -h${mysql_host}  &> /dev/null; then
    log 'MySQL 2 has been started ...'
    echo "MySQL 2 has been started ..."
    exit 0
fi

###### 
localname=$(hostname)

###### 读目录下的文件， 直到3个节点都写入 ####
for i in {300..0}; do
    mysql_start_pos_opt_files_len=`ls -l /middle/ | grep mysql |grep "^-"|wc -l`
    if [ $mysql_start_pos_opt_files_len = 3 ];then
        break
    fi

    log "mysql_start_pos_opt_files_len $i is $mysql_start_pos_opt_files_len < 3"
    sleep 1
done

#若i为0值，则表明验证失败
if [ "$i" = 0 ]; then
    exit 1
fi

mysql_header_name=
mysql_header_value=
for filename in $(ls /middle/ | grep mysql)
do
    start_pos_opt_tmp=$(cat /middle/$filename)
    start_pos_opt_tmp="${start_pos_opt_tmp:-0}"
    log "file: $filename $start_pos_opt_tmp"

    if [ ! -n "$mysql_header_name" ]; then
        mysql_header_value=$start_pos_opt_tmp
        mysql_header_name=$filename
        continue
    fi

    if [ "$start_pos_opt_tmp" \> "$mysql_header_value" ]
    then
        mysql_header_value=$start_pos_opt_tmp
        mysql_header_name=$filename
    else
        if [ "$start_pos_opt_tmp" = "$mysql_header_value" ] && [ "$mysql_header_name" \> "$filename" ]
        then
          mysql_header_value=$start_pos_opt_tmp
          mysql_header_name=$filename
        fi
    fi
done

log "first start mysql is : $mysql_header_name  $mysql_header_value"
if [ "$localname" !=  "$mysql_header_name" ];then
    log "I'm $localname , isn't the first node "
    exit 1
fi

log " I am the first node is : $localname"
`rm -rf /middle/mysql*`  #选举完成后， 删除生成的临时文件 ?????
echo "cant start  , is first_start_node"
















