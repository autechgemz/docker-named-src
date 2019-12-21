FROM alpine:latest
MAINTAINER autechgemz@gmail.com
ENV TZ Asia/Tokyo
ARG TIMEZONE=${TZ}
ARG BIND_VERSION="9.14.9"
ARG BIND_SITE=https://ftp.isc.org/isc/bind9
ARG BIND_BIN=bind-${BIND_VERSION}.tar.gz
ARG BIND_GET=${BIND_SITE}/${BIND_VERSION}/${BIND_BIN}
RUN addgroup -S named \
 && adduser -S -D -H -h /usr/local/etc/named -s /sbin/nologin -G named -g named named \
 && apk upgrade --update --available \
 && apk add --no-cache \
    tini \
    tzdata \
    rsyslog \
    linux-headers \
    gcc \
    gmp-dev \
    libc-dev \
    libgcc \
    openssl-dev \
    libxml2-dev \
    libcap-dev \
    make \
    perl \
    file \
    wget \
    ca-certificates \
    geoip-dev \
    python3 \
    py3-ply \
 && update-ca-certificates
ADD $BIND_GET /tmp/${BIND_BIN}
WORKDIR /tmp
RUN tar zxvf ${BIND_BIN} 
WORKDIR /tmp/bind-${BIND_VERSION}
RUN ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/named \
    --localstatedir=/var \
    --with-openssl=/usr \
    --enable-linux-caps \
    --with-libxml2 \
    --enable-shared \
    --disable-static \
    --with-libtool \
    --with-randomdev=/dev/random \
    --mandir=/usr/local/share/man \
    --infodir=/usr/local/share/info \
    --with-geoip=/usr \
 && make \
 && make install
WORKDIR /tmp
RUN rm -rf bind-${BIND_VERSION} && \
    rm bind-${BIND_VERSION}.tar.gz
WORKDIR /
COPY etc/named /etc/named
COPY etc/rsyslog.conf /etc/rsyslog.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
EXPOSE 53/udp 53/tcp
VOLUME ["/etc/named"]
ENTRYPOINT ["tini", "--"]
CMD ["/entrypoint.sh"]
