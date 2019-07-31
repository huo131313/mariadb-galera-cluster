#! /bin/bash

all_node_names=("mysql-0.galera.default.svc.cluster.local" "mysql-1.galera.default.svc.cluster.local" "mysql-2.galera.default.svc.cluster.local") 


_mysql_pwd=$2

### begin  3 个数据库都没有启动 ， 如果有一个启动了 ， 直接0 , 常规启动就ok
for _f_node_name in ${all_node_names[@]} 
do
    if echo 'SELECT 1' | mysql -uroot -p123456a? -h${_f_node_name}  &> /dev/null; then
        echo "$_f_node_name has been started ..."
        exit 0  
    fi
done

####################### 本节点 host name     ###############
local_hostname=$(hostname)
###################  本节点  wsrep  position   ###############      
local_wsrep_position=0
echo "init args: $1"
if  [ $1 ] ; then
    local_wsrep_array=(${1//:/ })
    local_wsrep_position=${local_wsrep_array[1]}
fi

echo "local_wsrep_position :  $local_hostname $local_wsrep_position "

echo "" > /tmp/tmpFile
wsrep_result="$local_hostname" # 初始化本节点

echo "begin loop all nodes and find the first node  that allow start"
for _node_name in ${all_node_names[@]} 
do
    if [[ "${_node_name}" == *"${local_hostname}"* ]]; then # 把自己排除出来， 不用获取自己的数据
            echo  "exclude myself $_node_name"
            continue
    fi

    echo  "deal with $_node_name"
    while [ "1" = "1" ]
    do
            # curl -s -w "%{http_code}" -o /tmp/tmpFile  http://mysql-0.galera.default.svc.cluster.local:8899/wsrep
            # curl -s -w "%{http_code}" -o /tmp/tmpFile  http://mysql-1.galera.default.svc.cluster.local:8899/wsrep
            # curl -s -w "%{http_code}" -o /tmp/tmpFile  http://mysql-2.galera.default.svc.cluster.local:8899/wsrep
            #echo "curl -s -w "%{http_code}" -o /tmp/tmpFile  http://$_node_name:8899/wsrep"
            http_code=`curl -s -w "%{http_code}" -o /tmp/tmpFile  http://$_node_name:8899/wsrep`
            if [ "$http_code" != "200" ]; then # 没有正常返回， 接着取
                #echo "curl failed : $http_code"
                continue;
            fi

            #取到结果
            tmp_wsrep=`cat /tmp/tmpFile`
            echo "$http_code    ---   $tmp_wsrep"

            wsrep_array=(${tmp_wsrep//:/ })
            wsrep_position=${wsrep_array[1]}
            wsrep_node=${wsrep_array[2]}
            #echo "1 2 : $wsrep_position  $wsrep_node"

            ## 本节点 number 大
            if [ $local_wsrep_position -gt $wsrep_position ]; then
                break;
            fi

            ###  number 相同 ， 取 hostname 小的节点 FINAL=`echo ${STR: -1}`
            if [ $local_wsrep_position -eq $wsrep_position ] && [ ${wsrep_node: -1} -gt ${local_hostname: -1} ]; then
                break;
            fi

            wsrep_result=$wsrep_node
            break
    done
done
echo " end loop all nodes and find the first node  that allow start"

echo "the first node should be  $wsrep_result "

#如果选举的节点 最后是本节点则 则执行, 否则等到有一个节点起来了，再启动
if [ $wsrep_result != "$local_hostname" ] ; then

    while [ "1" = "1" ]
    do
        ### begin  3 个数据库都没有启动 ， 如果有一个启动了 ， 直接0 , 常规启动就ok
        for _ss_node_name in ${all_node_names[@]} 
        do
            if [[ "${_ss_node_name}" == *"${local_hostname}"* ]]; then # 把自己排除出来， 不检查
                #echo  "exclude myself $_ss_node_name"
                continue
            fi

            if echo 'SELECT 1' | mysql -uroot -p123456a? -h${_ss_node_name}  &> /dev/null; then
                echo "$_ss_node_name has been started ..."

                # Run Galera at non-first node on Kubernetes
                if hash peer-finder 2>/dev/null; then
                	peer-finder -on-start=/opt/galera/on-start.sh -service="${GALERA_SERVICE:-galera}"
                fi

                echo " the other node begin start:  $local_hostname"

                exit 0   
            fi
        done
    done
else
    # Run Galera at first node on Kubernetes
    # if hash peer-finder 2>/dev/null; then
    #     peer-finder -on-start=/opt/galera/on-start-first.sh -service="${GALERA_SERVICE:-galera}"
    # fi

    # hard code , first node should be wsrep_cluster_address=gcomm://
    sed -i -e "s|^wsrep_cluster_address[[:space:]]*=.*$|wsrep_cluster_address=gcomm://|" /etc/mysql/conf.d/galera.cnf
fi

exit 0














