FROM mariadb:10.3

#跟换国内源 下载
RUN cp /etc/apt/sources.list /etc/apt/sources_init.list
ADD ["sources.list", "/etc/apt/sources.list"]

RUN set -x && \
    apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/* 
    # chmod +x /usr/local/bin/peer-finder && \
    # \
    
    #apt-get purge -y --auto-remove ca-certificates wget

ADD ["galera/", "/opt/galera/"]

ADD ["galera-peer-finder/galera-peer-finder", "/"]
ADD ["peer-finder", "/usr/local/bin/"]

RUN chmod +x /usr/local/bin/peer-finder /galera-peer-finder


RUN set -x && \
    cd /opt/galera && chmod +x *.sh


ADD ["docker-entrypoint.sh", "/usr/local/bin/"]
ADD ["myinit.sh", "/"]
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /myinit.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["mysqld"]
