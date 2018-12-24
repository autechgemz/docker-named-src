# Docker BIND container

BIND server running on Alpine 

## Start Container

```
# docker run --rm -d --name named -p 53:53/tcp -p 53:53/udp -e TZ=Asia/Tokyo autechgemz/named-src
```
