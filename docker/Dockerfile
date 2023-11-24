FROM homqyy/dev_env_centos8 as compile

RUN dnf install -y pcre-devel openssl-devel perl-App-cpanminus.noarch

WORKDIR /usr/local/src/hengine-docker

COPY . .

RUN ./build.sh

FROM centos:8

# update yum repos
RUN rm -f /etc/yum.repos.d/* \
        && cd /etc/yum.repos.d/ \
        && curl http://mirrors.aliyun.com/repo/Centos-8.repo > CentOS-Linux-BaseOS.repo \
        && sed -i 's/\$releasever/8-stream/g' CentOS-Linux-BaseOS.repo \
        && cd - \
        && yum clean all \
        && yum makecache

RUN dnf install -y gettext

COPY --from=compile /usr/local/hengine/ /usr/local/hengine/
COPY --from=compile /usr/local/lib/libluajit-5.1.* /usr/local/lib/
COPY --from=compile /usr/local/include/luajit-2.1/ /usr/local/include/luajit-2.1/

WORKDIR /usr/local/hengine

COPY docker/entrypoint.sh /sbin/entrypoint.sh
COPY docker/*.temp /usr/local/hengine/conf/
COPY docker/internal/ /usr/local/hengine/conf/internal/

RUN chmod +x /sbin/entrypoint.sh

ENTRYPOINT [ "/sbin/entrypoint.sh" ]
