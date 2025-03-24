FROM alpine:3.21 AS build

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
        && apk add --no-cache --virtual .build-deps \
        curl gcc libc-dev make openssl-dev pcre2-dev perl zlib-dev linux-headers bash alpine-sdk findutils

ENV TENGINE_VERSION=3.1.0

WORKDIR /workdir
RUN curl -Lj https://github.com/alibaba/tengine/archive/refs/tags/${TENGINE_VERSION}.tar.gz -o tengine.tar.gz \
    && tar -zxvf tengine.tar.gz

WORKDIR /workdir/tengine-${TENGINE_VERSION}
RUN  ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_sni \
    && make -j16 \
    && make install

FROM alpine:3.21-slim AS runtime
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY conf/ /etc/nginx/
COPY html/ /usr/share/nginx/html/
COPY --from=build /var/log/nginx /var/log/nginx

# create nginx user/group first, to be consistent throughout docker variants \
RUN addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx \
    # add runtime package
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache \
        pcre2 \
    # mkdir cache
    && mkdir -p /var/cache/nginx \
    # forward request and error logs to docker log collector
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/access.log \
    && touch /var/log/nginx/error.log \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    # create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d
    
COPY entrypoint/docker-entrypoint.sh /
COPY entrypoint/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY entrypoint/15-local-resolvers.envsh /docker-entrypoint.d
COPY entrypoint/20-envsubst-on-templates.sh /docker-entrypoint.d
COPY entrypoint/30-tune-worker-processes.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]

WORKDIR /usr/local/nginx
EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]