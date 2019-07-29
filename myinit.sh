#! /bin/bash

first_start_node=""


all_node_names=("mysql-0.galera.default.svc.cluster.local" "mysql-1.galera.default.svc.cluster.local" "mysql-2.galera.default.svc.cluster.local") 

log() {
	local msg="myinit.sh: $@"
	echo "$msg" >&2
}

### begin  3 个数据库都没有启动 ， 如果有一个启动了 ， 直接0 , 常规启动就ok
for node_name in ${all_node_names[@]} 
do
    if echo 'SELECT 1' | mysql -uroot -p123456a? -h${node_name}  &> /dev/null; then
        log "$node_name has been started ..."
        echo "$node_name has been started ..."
        exit 0   
    fi
done

###############    ###############
hostname=$(hostname)
local_wsrep_position="$xxxx;$hostname"
echo "local_wsrep_position :  $local_wsrep_position "

###### 读目录下的文件， 直到3个节点都写入 ####
# for i in {300..0}; do
#     mysql_start_pos_opt_files_len=`ls -l /middle/ | grep mysql |grep "^-"|wc -l`
#     if [ $mysql_start_pos_opt_files_len = 3 ];then
#         break
#     fi

#     log "mysql_start_pos_opt_files_len $i is $mysql_start_pos_opt_files_len < 3"
#     sleep 1
# done   curl -s -w"%{http_code}n" -o/dev/null http://localhost:8899/wsrep

#mkfifo tmpFifo 管道临时文件

echo "" > /tmp/tmpFile
wsrep_result="$local_wsrep_position" # 初始化本节点
for _node_name in ${all_node_names[@]} 
do
   if [ $_node_name == "*$localname" ]; then # 把自己排除出来， 不用获取自己的数据
        continue
   fi

   while [ "1" = "1" ]
   do
        http_code=`curl -s -w "%{http_code}" -o /tmp/tmpFile  http://$_node_name:8899/wsrep`
        echo "$http_code    --- `cat /tmp/tmpFile` "
        if [ $http_code != 200 ]; then # 没有正常返回， 接着取
            continue;
        fi

        #取到结果
        tmp_wsrep=`cat /tmp/tmpFile`
        
        if [ "$tmpFifo" \> "$wsrep_result" ];then
            wsrep_result=$tmpFifo;
        fi

        break
   done
done

echo “ result -----  $wsrep_result ---- ”

#如果选举的节点 最后是本节点则 返回 1 , 等着
if [ $wsrep_result != "$local_wsrep_position" ] ; then

    while [ "1" = "1" ]
    do
        ### begin  3 个数据库都没有启动 ， 如果有一个启动了 ， 直接0 , 常规启动就ok
        for node_name in ${all_node_names[@]} 
        do
            if [ $_node_name == "*$localname" ]; then # 把自己排除出来， 不检查
                continue
            fi

            if echo 'SELECT 1' | mysql -uroot -p123456a? -h${node_name}  &> /dev/null; then
                log "$node_name has been started ..."
                echo "$node_name has been started ..."
                exit 0   
            fi
        done
    done
fi

#如果选举的节点 最后是本节点则 返回成功 开始启动
exit 0;  # 成功启动
















