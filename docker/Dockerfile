FROM tomcat:8.5.100-jdk8

LABEL maintainer="梦想歌 <shiyindaxiaojie@gmail.com>"

ENV HOME "/data"
ENV TZ "Asia/Shanghai"
ENV LANG "C.UTF-8"
ENV JAVA_OPTS ""
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
ENV RESOLVE_SERVER_URL "N"

COPY cat-home/target/cat-home.war /usr/local/tomcat/webapps/cat.war
COPY docker/tomcat-server.xml /usr/local/tomcat/conf/server.xml
COPY docker/datasources.xml /data/appdatas/cat/datasources.xml
COPY docker/datasources.sh /data/appdatas/cat/datasources.sh
COPY docker/client.xml /data/appdatas/cat/client.xml
COPY docker/client.sh /data/appdatas/cat/client.sh
COPY docker/env.sh /data/appdatas/cat/env.sh
COPY docker/entrypoint.sh /data/appdatas/cat/entrypoint.sh

RUN chmod +x /data/appdatas/cat/datasources.sh \
    && chmod +x /data/appdatas/cat/client.sh \
    && chmod +x /data/appdatas/cat/env.sh \
    && chmod +x /data/appdatas/cat/entrypoint.sh

ENTRYPOINT ["/data/appdatas/cat/entrypoint.sh"]
CMD ["catalina.sh", "run"]
