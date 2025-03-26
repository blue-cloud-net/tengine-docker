FROM debian:12 AS build

RUN apt update \
    && apt upgrade -y \
    && apt install -y curl g++ make libpcre3-dev libssl-dev zlib1g-dev \
                            libgeoip-dev libjemalloc-dev

ENV TENGINE_VERSION=3.1.0
ENV LUAJIT_VERSION=2.1-20250117
ENV LUA_RESTY_CORE_VERSION=0.1.27
ENV LUA_RESTY_LRUCACHE_VERSION=0.15

WORKDIR /workdir
RUN curl -Lj https://github.com/alibaba/tengine/archive/refs/tags/${TENGINE_VERSION}.tar.gz -o tengine.tar.gz \
    && curl -Lj https://github.com/openresty/luajit2/archive/refs/tags/v${LUAJIT_VERSION}.tar.gz -o luajit2.tar.gz  \
    && curl -Lj https://github.com/openresty/lua-resty-core/archive/refs/tags/v${LUA_RESTY_CORE_VERSION}.tar.gz -o lua-resty-core.tar.gz  \
    && curl -Lj https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v${LUA_RESTY_LRUCACHE_VERSION}.tar.gz -o lua-resty-lrucache.tar.gz \
    && tar -zxvf tengine.tar.gz \
    && tar -zxvf luajit2.tar.gz \
    && tar -zxvf lua-resty-core.tar.gz \
    && tar -zxvf lua-resty-lrucache.tar.gz

# 编译lua模块
WORKDIR /workdir/luajit2-${LUAJIT_VERSION}
RUN make -j2 \
    && make install
WORKDIR /workdir/lua-resty-core-${LUA_RESTY_CORE_VERSION}
RUN make install
WORKDIR /workdir/lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION}
RUN make install

ENV LUAJIT_LIB=/usr/local/lib
ENV LUAJIT_INC=/usr/local/include/luajit-2.1

WORKDIR /workdir/tengine-${TENGINE_VERSION}
RUN  ./configure \
        --with-ld-opt="-Wl,-lpcre,-rpath,/usr/local/lib" \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/lock/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_geoip_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-ipv6 \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream_realip_module \
        --with-stream_sni \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-threads \
        --with-openssl-async \
        --with-pcre \
        --with-pcre-jit \
        --with-jemalloc \
        --with-debug \
        --add-module=./modules/ngx_http_concat_module \
        --add-module=./modules/ngx_http_footer_filter_module \
        --add-module=./modules/ngx_http_lua_module \
        --add-module=./modules/ngx_http_reqstat_module \
        --add-module=./modules/ngx_http_slice_module \
        --add-module=./modules/ngx_http_sysguard_module \
        --add-module=./modules/ngx_http_trim_filter_module \
        --add-module=./modules/ngx_http_upstream_check_module \
        --add-module=./modules/ngx_http_upstream_consistent_hash_module \
        --add-module=./modules/ngx_http_upstream_keepalive_module \
        # 需要移除nginx原有的keepalive模块
        --without-http_upstream_keepalive_module \
        --add-module=./modules/ngx_http_upstream_session_sticky_module \
        --add-module=./modules/ngx_http_upstream_vnswrr_module \
        --add-module=./modules/ngx_slab_stat \
    && make -j2 \
    && make install

FROM debian:12 AS runtime
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /usr/local/lib/lua /usr/local/lib/lua
COPY conf/ /etc/nginx/
COPY html/ /usr/share/nginx/html/

# create nginx user/group first, to be consistent throughout docker variants \
RUN groupadd --system nginx \
    && useradd --system -d /var/cache/nginx --shell /sbin/nologin -g nginx nginx \
    # install runtime dependencies
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl dnsutils net-tools iputils-ping \
        libpcre3 \
        libluajit2-5.1-2 \
        libgeoip1 \
    # clean up
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # link lua libraries
    && install -d -m 755 /usr/local/share/lua/5.1 \
    && ln -sf /usr/local/lib/lua/ngx /usr/local/share/lua/5.1 \
    && ln -sf /usr/local/lib/lua/resty /usr/local/share/lua/5.1 \
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