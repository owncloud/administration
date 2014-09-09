#!/bin/sh

cat > /etc/haproxy/haproxy.cfg << EOF
global
    log 127.0.0.1   local0
    log 127.0.0.1   local1 notice
    maxconn 128
    # chroot /usr/share/haproxy
    uid 99
    gid 99
    # daemon
    debug
    # quiet

defaults
    log global
    mode    http
    option  tcplog
    option  dontlognull
    retries 3
    option  redispatch
    maxconn 32
    contimeout  5000
    clitimeout  50000
    srvtimeout  50000

listen stats 127.0.0.1:1936
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
    stats auth name:password
    stats refresh 10s

frontend front
    bind *:80
    # 443 ssl crt /etc/haproxy/ssl/server.pem
    mode http

    # acl url_trans path_beg /transmission /rpc #/memcached

    default_backend owncloud

listen haproxy-stats 127.0.0.1:1936
    mode http
    option httpclose
    server haproxy-stats 127.0.0.1:1936 check inter 5000 rise 2 fall 3

backend owncloud
    mode http
    balance roundrobin
    option httpclose
    server  oc-server-1 172.17.0.5:80 weight 15  check inter 5000 rise 2 fall 3
    server  oc-server-2 172.17.0.6:80 weight 10  check inter 5000 rise 2 fall 3
    server  oc-server-3 172.17.0.7:80 weight 200 check inter 5000 rise 2 fall 3
