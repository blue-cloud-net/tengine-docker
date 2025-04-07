FROM debian:12 AS build

RUN apt update \
    && apt upgrade -y \
    && apt install -y curl g++ make libpcre3-dev libssl-dev zlib1g-dev \
                            libgeoip-dev libjemalloc-dev \
                            autoconf automake libtool libpcre2-dev

ENV TENGINE_VERSION=3.1.0
ENV TONGSUO_VERSION=8.4.0
ENV LUAJIT_VERSION=2.1-20250117
ENV LUA_RESTY_CORE_VERSION=0.1.27
ENV LUA_RESTY_LRUCACHE_VERSION=0.15
ENV MODSECURITY_VERSION=3.0.14
ENV MODSECURITY_NGINX_VERSION=1.0.3
ENV CORERULESET_VERSION=4.12.0
ENV LIBINJECTION_VERSION=3.10.0
ENV MBED_TLS_VERSION=3.6.3

WORKDIR /workdir
RUN curl -Ljf https://github.com/alibaba/tengine/archive/refs/tags/${TENGINE_VERSION}.tar.gz -o tengine.tar.gz \
    && curl -Ljf https://github.com/Tongsuo-Project/Tongsuo/archive/refs/tags/${TONGSUO_VERSION}.tar.gz -o tongsuo.tar.gz  \
    && curl -Ljf https://github.com/openresty/luajit2/archive/refs/tags/v${LUAJIT_VERSION}.tar.gz -o luajit2.tar.gz  \
    && curl -Ljf https://github.com/openresty/lua-resty-core/archive/refs/tags/v${LUA_RESTY_CORE_VERSION}.tar.gz -o lua-resty-core.tar.gz  \
    && curl -Ljf https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v${LUA_RESTY_LRUCACHE_VERSION}.tar.gz -o lua-resty-lrucache.tar.gz \
    && curl -Ljf https://github.com/owasp-modsecurity/ModSecurity/archive/refs/tags/v${MODSECURITY_VERSION}.tar.gz -o modsecurity.tar.gz \
    && curl -Ljf https://github.com/owasp-modsecurity/ModSecurity-nginx/archive/refs/tags/v${MODSECURITY_NGINX_VERSION}.tar.gz -o modsecurity-nginx.tar.gz \
    && curl -Ljf https://github.com/coreruleset/coreruleset/releases/download/v${CORERULESET_VERSION}/coreruleset-${CORERULESET_VERSION}-minimal.tar.gz -o coreruleset.tar.gz \
    && curl -Ljf https://github.com/libinjection/libinjection/archive/refs/tags/v${LIBINJECTION_VERSION}.tar.gz -o libinjection.tar.gz \
    && curl -Ljf https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-${MBED_TLS_VERSION}.tar.gz -o mbedtls.tar.gz \
    && tar -zxvf tengine.tar.gz \
    && tar -zxvf tongsuo.tar.gz \
    && tar -zxvf luajit2.tar.gz \
    && tar -zxvf lua-resty-core.tar.gz \
    && tar -zxvf lua-resty-lrucache.tar.gz \
    && tar -zxvf modsecurity.tar.gz \
    && tar -zxvf modsecurity-nginx.tar.gz \
    && tar -zxvf coreruleset.tar.gz \
    && tar -zxvf libinjection.tar.gz -C ModSecurity-${MODSECURITY_VERSION}/others/ \
    && tar -zxvf mbedtls.tar.gz -C ModSecurity-${MODSECURITY_VERSION}/others/

# 移除文件夹版本号
RUN mv tengine-${TENGINE_VERSION} tengine \
    && mv Tongsuo-${TONGSUO_VERSION} tongsuo \
    && mv luajit2-${LUAJIT_VERSION} luajit2 \
    && mv lua-resty-core-${LUA_RESTY_CORE_VERSION} lua-resty-core \
    && mv lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION} lua-resty-lrucache \
    && mv ModSecurity-${MODSECURITY_VERSION} modsecurity \
    && mv ModSecurity-nginx-${MODSECURITY_NGINX_VERSION} modsecurity-nginx \
    && mv coreruleset-${CORERULESET_VERSION} coreruleset \
    && rm -rf modsecurity/others/libinjection modsecurity/others/mbedtls \
    && mv modsecurity/others/libinjection-${LIBINJECTION_VERSION} modsecurity/others/libinjection \
    && mv modsecurity/others/mbedtls-mbedtls-${MBED_TLS_VERSION} modsecurity/others/mbedtls

# 编译lua模块
WORKDIR /workdir/luajit2
RUN make -j2 \
    && make install
WORKDIR /workdir/lua-resty-core
RUN make install
WORKDIR /workdir/lua-resty-lrucache
RUN make install

# 编译ModSecurity
WORKDIR /workdir/modsecurity
RUN ./build.sh \
    && ./configure \
        --prefix=/usr/local/lib/modsecurity \
        --disable-doxygen-doc \
        --disable-doxygen-html \
        --disable-examples \
        --with-geoip \
        --with-pcre2 \
    && make -j2 \
    && make install

# 设置编译环境变量
ENV LUAJIT_LIB=/usr/local/lib
ENV LUAJIT_INC=/usr/local/include/luajit-2.1
ENV MODSECURITY_INC=/workdir/modsecurity/headers/
ENV MODSECURITY_LIB=/workdir/modsecurity/src/.libs/

# fix tongsuo build warning (https://github.com/Tongsuo-Project/Tongsuo/commit/3b84722dcd68e4f008534a15cb1c9e38835237cf)
RUN sed -i '/while (out_len > 0)/,/\}/c\    memset(out, 0, out_len * sizeof(BN_ULONG));' /workdir/tongsuo/crypto/bn/rsaz_exp_x2.c

WORKDIR /workdir/tengine
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
        # 添加ModSecurity模块
        --add-module=../modsecurity-nginx \
        # 添加Tongsuo模块，并启用NTLS
        --add-module=./modules/ngx_tongsuo_ntls \
        --with-openssl=../tongsuo \
        --with-openssl-opt="--strict-warnings enable-ntls" \
    && make -j2 \
    && make install

FROM debian:12 AS runtime
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /usr/local/lib/lua/ /usr/local/lib/lua/
COPY --from=build /usr/local/lib/modsecurity/lib/ /usr/local/lib/modsecurity/
COPY conf/ /etc/nginx/
COPY --from=build /workdir/modsecurity/unicode.mapping /etc/nginx/modsecurity/unicode.mapping
COPY --from=build /workdir/modsecurity/modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
COPY --from=build /workdir/coreruleset/rules/ /etc/nginx/modsecurity/owasp-crs/rules/
COPY --from=build /workdir/coreruleset/crs-setup.conf.example /etc/nginx/modsecurity/owasp-crs/crs-setup.conf
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
    # link modsecurity libraries
    && ln -sf /usr/local/lib/modsecurity/libmodsecurity.so.3 /lib/libmodsecurity.so.3 \
    # set modsecurity
    && echo -e "modsecurity on;" > /etc/nginx/conf.d/modsecurity.conf \
    && echo -e "modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;" >> /etc/nginx/conf.d/modsecurity.conf \
    && sed -i 's|SecAuditLogType Serial|SecAuditLogType Concurrent|g' /etc/nginx/modsecurity/modsecurity.conf \
    && echo -e "\n\n\n" >> /etc/nginx/modsecurity/modsecurity.conf \
    && echo -e "SecAuditLogStorageDir /var/log/audit/\n\n" >> /etc/nginx/modsecurity/modsecurity.conf \
    && echo -e "Include /etc/nginx/modsecurity/owasp-crs/crs-setup.conf" >> /etc/nginx/modsecurity/modsecurity.conf \
    && echo -e "Include /etc/nginx/modsecurity/owasp-crs/rules/*.conf" >> /etc/nginx/modsecurity/modsecurity.conf \
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