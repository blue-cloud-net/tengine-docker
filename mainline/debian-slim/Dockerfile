FROM debian:12 AS build

RUN apt update \
    && apt upgrade -y \
    && apt install -y curl g++ libgd-dev libgeoip-dev libxslt1-dev libpcre3-dev liblua5.1-0-dev lua5.1 cpanminus libssl-dev libjemalloc-dev

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
        --pid-path=/run/nginx.pid \
        --lock-path=/run/lock/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_auth_request_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_v2_module \
    && make -j2 \
    && make install

FROM debian:12-slim AS runtime
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY conf/ /etc/nginx/
COPY html/ /usr/share/nginx/html/

# create nginx user/group first, to be consistent throughout docker variants \
RUN groupadd --system nginx \
    && useradd --system -d /var/cache/nginx --shell /sbin/nologin -g nginx nginx \
    # install runtime dependencies
    && apt-get -y update \
    && apt upgrade -y \
    && apt-get install -y \
        libssl3 \
        libpcre3 \
    # clean up
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # create cache directories
    && install -d -m 755 /var/cache/nginx \
    # create modules folder
    && install -d -m 755 /usr/lib/nginx/modules \
    && ln -sf /usr/lib/nginx/modules /etc/nginx/modules \
    # forward request and error logs to docker log collector
    && install -d -m 755 /var/log/nginx \
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