# docker-pagespeed
a docker build of pagespeed, nginx and varnish

# docker-pagespeed
a docker build of pagespeed, nginx and varnish

- SECRET_KEY: a random, hard to guess string, used for the re-beaconing key
- NGINX_PORT: the port on which nginx would listen (typically 8080)
- COOKIES: a pipe (|) delimitited list of cookie names that are whitelisted
- BACKEND: the fully qualified hostname for the backend (i.e. www.example.com)
- BACKENDS: a wildcard for other hostnames that are serving contents for the main site (i.e *.example.com)
- FRONTEND: the URL of the site, as it will appear to users (i.e. http://faster.example.com)
- SERVER_NAME: the fully qualified hostname for the fronted (i.e. faster.example.com) 
- PROXY_DOMAINS: a space separated list of ully qualified hostnames that can be safely considered part of the site (i.e. cdn.somesite.com js.somether.net)


