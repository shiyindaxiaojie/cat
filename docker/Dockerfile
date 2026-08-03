FROM tomcat:8.5.78-jdk8

LABEL maintainer="梦想歌 <shiyindaxiaojie@gmail.com>"
LABEL version="3.4.2"

ENV HOME "/data"
ENV TZ "Asia/Shanghai"
ENV LANG "C.UTF-8"
ENV XMS "1g"
ENV XMX "1g"
ENV XSS "256k"
ENV GC_MODE "G1"
ENV USE_GC_LOG "Y"
ENV USE_HEAP_DUMP "Y"
ENV USE_LARGE_PAGES "N"
ENV USE_ALWAYS_PRETOUCH "N"
ENV USE_STRING_DEDUPLICATION "N"
ENV PRINT_JVM_FLAGS "N"
ENV MYSQL_URL ""
ENV MYSQL_PORT "3306"
ENV MYSQL_USERNAME ""
ENV MYSQL_PASSWORD ""
ENV MYSQL_SCHEMA "cat"
ENV SERVER_URL ""
ENV RESOLVE_SERVER_URL "N"

COPY cat-home/target/cat-home.war /usr/local/tomcat/webapps/cat.war
COPY docker/tomcat-server.xml /usr/local/tomcat/conf/server.xml
COPY docker/datasources.xml /usr/local/share/cat/datasources.xml
COPY docker/datasources.xml /data/appdatas/cat/datasources.xml
COPY docker/datasources.sh /usr/local/tomcat/datasources.sh
COPY docker/client.xml /usr/local/share/cat/client.xml
COPY docker/client.xml /data/appdatas/cat/client.xml
COPY docker/client.sh /usr/local/tomcat/client.sh
COPY docker/env.sh /usr/local/tomcat/env.sh
COPY docker/entrypoint.sh /usr/local/bin/cat-entrypoint.sh

RUN chmod +x /usr/local/tomcat/datasources.sh \
    && chmod +x /usr/local/tomcat/client.sh \
    && chmod +x /usr/local/tomcat/env.sh \
    && chmod +x /usr/local/bin/cat-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/cat-entrypoint.sh"]
CMD ["catalina.sh", "run"]
