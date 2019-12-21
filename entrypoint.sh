#!/usr/bin/env sh
set -e

BIND_ROOT=/etc/named

BIND_RNDC_KEY=$BIND_ROOT/rndc.key
if [ ! -f $BIND_RNDC_KEY ]; then
  rndc-confgen -b 512 -a -c $BIND_RNDC_KEY > /dev/null 2>&1
  chmod 0440 $BIND_RNDC_KEY
  chown root.named $BIND_RNDC_KEY
fi

BIND_HINT=${BIND_ROOT}/zone/root.cache
if [ ! -f $BIND_HINT ]; then
  wget -q -O $BIND_HINT https://www.internic.net/domain/named.root
fi

if [ ! -d /var/run/named ]; then
  mkdir -p /var/run/named
  chown named.named /var/run/named
fi

find ${BIND_ROOT} -type d -exec chmod 0755 {} \;
find ${BIND_ROOT} -type f -exec chmod 0644 {} \;

find ${BIND_ROOT} -type d -exec chown named.named {} \;
find ${BIND_ROOT} -type f -exec chown named.named {} \;

/usr/sbin/rsyslogd &&
exec /usr/local/sbin/named -u named -f
