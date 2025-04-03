# tengine-docker 编译tengine镜像

## 计划

1. [x] 编译tengine压缩镜像
2. [x] 编译tengine基础镜像
3. [ ] 编译tengine较为完整模块镜像
4. [ ] 编译tengine完整模块镜像

## 问题

1. [x] ngx_http_lua_module requires LuaJIT 2.x，未解决，先不加入该模块编译

2. [ ] ngx_http_upstream_iwrr_module未发布，暂不编译

3. [ ] http_perl_module编译最小化安装未能解决，先不加入该模块编译

    Can't locate nginx.pm in @INC (you may need to install the nginx module) (@INC contains: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.34.0 /usr/local/share/perl/5.34.0 /usr/lib/x86_64-linux-gnu/perl5/5.34 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl/5.34 /usr/share/perl/5.34 /usr/local/lib/site_perl).

4. [ ] ubuntu-all tongsuo报错 error: iteration 19 invokes undefined behavior [-Werror=aggressive-loop-optimizations]

5. [x] alpine3.21编译modsecurity-nginx失败，找不到modsecurity库 [issues 329](https://github.com/owasp-modsecurity/ModSecurity-nginx/issues/329)