FROM alpine:latest

LABEL maintainer "Kenji Tsumaki <autechgemz@gmail.com>"

ARG BIND_VERSION="9.11.3"

ENV BIND_SITE https://ftp.isc.org/isc/bind9
ENV BIND_BIN bind-${BIND_VERSION}.tar.gz
ENV BIND_GET ${BIND_SITE}/${BIND_VERSION}/${BIND_BIN}

RUN addgroup -S named \
 && adduser -S -D -H -h /etc/named -s /sbin/nologin -G named -g named named \
 && apk upgrade --update --available \
 && apk add --no-cache \
    runit \
    tzdata \
    rsyslog \
    linux-headers \
    gcc \
    gmp-dev \
    libc-dev \
    libgcc \
    openssl-dev \
    libxml2-dev \
    make \
    perl \
    file \
    wget \
    ca-certificates \
 && update-ca-certificates

ADD $BIND_GET /tmp/${BIND_BIN}

WORKDIR /tmp

RUN tar zxvf ${BIND_BIN} 

WORKDIR /tmp/bind-${BIND_VERSION}

RUN ./configure \
    --prefix=/usr \
    --sysconfdir=/etc/named \
    --localstatedir=/var \
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
    --mandir=/usr/share/man \
    --infodir=/usr/share/info \
 && make \
 && make install

WORKDIR /tmp

RUN rm -rf bind-${BIND_VERSION} && \
    rm bind-${BIND_VERSION}.tar.gz

WORKDIR /

COPY etc/named /etc/named
COPY etc/rsyslog.conf /etc/rsyslog.conf

COPY service /service
RUN chmod 755 /service/*/run

EXPOSE 53/udp 53/tcp

VOLUME ["/etc/named"]

ENTRYPOINT ["runsvdir", "-P", "/service/"]
