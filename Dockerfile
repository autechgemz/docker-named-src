FROM alpine:latest
ENV TZ Asia/Tokyo
ENV BIND_VERSION 9.16.2
ARG TIMEZONE=${TZ}
ENV BIND_USER=named
ENV BIND_HOME=/var/named
ENV BUILD_ROOT /chroot
ENV GOPATH $BIND_HOME
ENV PATH $BUILD_ROOT/sbin:$BUILD_ROOT/bin:$PATH
RUN apk upgrade --update --available \
 && apk add --no-cache \
    tini \
    tzdata \
    runit \
    rsyslog \
    logrotate \
    bash \
    build-base \
    linux-headers \
    automake \
    autoconf \
    libtool \
    git \
    tar \
    openssl-dev \
    expat-dev \
    libxml2-dev \
    py3-ply \
    libgcc \
    libuv-dev \
    libcap-dev \
 && ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
 && addgroup -S ${BIND_USER} \
 && adduser -S -g 'BIND USER' -h ${BIND_HOME} -s /sbin/nologin -G ${BIND_USER} -H ${BIND_USER} 
ADD https://ftp.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz /bind-${BIND_VERSION}.tar.xz
RUN tar Jxvf /bind-${BIND_VERSION}.tar.xz -C / \
 && cd /bind-${BIND_VERSION} \
 && ./configure \
    --prefix=${BUILD_ROOT} \
    --sysconfdir=${BUILD_ROOT}/etc/named \
    --with-openssl=/usr \
    --enable-linux-caps \
    --with-libxml2 \
    --enable-threads \
    --enable-filter-aaaa \
    --enable-ipv6 \
    --enable-shared \
    --enable-static \
    --with-libtool \
    --with-randomdev=/dev/random \
 && make \
 && make install \
 && rm -rf /bind-${BIND_VERSION} \
 && rm -f /bind-${BIND_VERSION}.tar.xz \
 && rm -rf ${BIND_HOME}/src \
 && rm -rf ${BIND_HOME}/pkg \
 && apk del --no-cache \
    build-base \
    linux-headers \
    automake \
    autoconf \
    libtool \
    git \
    tar
COPY services /services
COPY files/etc/named ${BUILD_ROOT}/etc/named
COPY files/var/named ${BUILD_ROOT}/var/named
COPY files/etc/rsyslog.conf /etc/rsyslog.conf
RUN chmod 755 /services/*/run \
 && mkdir -p ${BUILD_ROOT}/var/named \
 && mkdir -p ${BUILD_ROOT}/var/named/dynamic \
 && mkdir -p ${BUILD_ROOT}/dev \
 && mknod ${BUILD_ROOT}/dev/random c 1 8 \
 && mknod ${BUILD_ROOT}/dev/null c 1 3 \
 && chown -R ${BIND_USER}.${BIND_USER} ${BUILD_ROOT}
VOLUME ["${BUILD_ROOT}/etc/named", "${BUILD_ROOT}/var/named"]
EXPOSE 53/tcp 53/udp
ENTRYPOINT ["runsvdir", "-P", "/services/"]
COPY Dockerfile /Dockerfile
