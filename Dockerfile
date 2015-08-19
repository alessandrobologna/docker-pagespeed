# fork from cook/nginx-pagespeed

FROM ubuntu
MAINTAINER Alessandro Bologna <alessandro.bologna@gmail.com>

  
ENV DEBIAN_FRONTEND noninteractive

# nginx - 1.9.3
# pagespeed - 1.9.32.6
# nginx-dav-ext-module - 0.0.3
# ngx_http_auth_pam_module - 1.4
# nginx-upstream-fair - master
# ngx_http_substitutions_filter_module - 0.6.4
# headers-more-nginx-module - v0.261

RUN apt-get update -qq \
    && apt-get install -yqq build-essential libgd2-xpm-dev zlib1g-dev libpcre3 libpcre3-dev openssl libssl-dev libxslt-dev libgeoip-dev libpam0g-dev libperl-dev wget ca-certificates varnish 

    
RUN (wget -qO - https://github.com/pagespeed/ngx_pagespeed/archive/v1.9.32.6-beta.tar.gz | tar zxf  - -C /tmp --owner root --group root --no-same-owner) \
    && (wget -qO - https://dl.google.com/dl/page-speed/psol/1.9.32.6.tar.gz | tar zxf - -C /tmp/ngx_pagespeed-1.9.32.6-beta/ --owner root --group root --no-same-owner) \
    && (wget -qO - http://nginx.org/download/nginx-1.9.3.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner) \
    && (wget -qO - https://github.com/arut/nginx-dav-ext-module/archive/v0.0.3.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner ) \
    && (wget -qO - https://github.com/openresty/echo-nginx-module/archive/v0.57.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner) \
    && (wget -qO - https://github.com/stogh/ngx_http_auth_pam_module/archive/v1.4.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner) \
    && (wget -qO - https://github.com/gnosek/nginx-upstream-fair/archive/master.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner) \
    && (wget -qO - https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v0.6.4.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner) \
    && (wget -qO - https://github.com/openresty/headers-more-nginx-module/archive/v0.261.tar.gz | tar zxf - -C /tmp --owner root --group root --no-same-owner) 
    
RUN cd /tmp/nginx-1.9.3 \
    && ./configure --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' --sbin-path=/usr/sbin/nginx --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --with-debug --with-pcre-jit --with-ipv6 --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module \
    --with-http_auth_request_module --with-http_addition_module --with-http_dav_module --with-http_geoip_module \
    --with-http_gzip_static_module --with-http_image_filter_module --with-http_spdy_module --with-http_sub_module \
    --with-http_xslt_module --with-mail --with-mail_ssl_module \
    --add-module=/tmp/ngx_http_auth_pam_module-1.4 \
    --add-module=/tmp/nginx-dav-ext-module-0.0.3 \
    --add-module=/tmp/nginx-upstream-fair-master \
    --add-module=/tmp/ngx_http_substitutions_filter_module-0.6.4 \
    --add-module=/tmp/ngx_pagespeed-1.9.32.6-beta \
    --add-module=/tmp/headers-more-nginx-module-0.261 \
    && make install \
    && rm -Rf /tmp/* \
    && apt-get purge -yqq wget build-essential \
    && apt-get autoremove -yqq \
    && apt-get clean

RUN mkdir -p /var/lib/nginx
RUN mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi}

VOLUME ["/etc/nginx/sites-enabled","/var/cache/nginx","/var/ngx_pagespeed_cache","/var/log/nginx"]
WORKDIR /etc/nginx/

# Configure nginx
RUN chmod 777 /var/ngx_pagespeed_cache
ADD pagespeed/nginx.conf /etc/nginx/nginx.conf
ADD pagespeed/sites-enabled /etc/nginx/sites-enabled


EXPOSE 80

# add template for varnish
ADD pagespeed/varnish/template /etc/varnish/

ADD start /start
RUN chmod +x /start
ENTRYPOINT ["/start"]

