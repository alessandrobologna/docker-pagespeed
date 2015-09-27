# docker-pagespeed

![Architecture diagram](art/diagram.jpg)

## What is it?
A docker build of [pagespeed](https://developers.google.com/speed/pagespeed/module/), [nginx](http://nginx.org/) and [varnish 4](https://www.varnish-cache.org/), with some convenient tooling to help developing enviromnent configurations that can be deployed to Amazon Elastic Beanstalk

## Running it
This platform can be run locally, within a docker environment, or on AWS, within [Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/). Typically you will testing a configuration in local, and then deploy to AWS.

### Within a local Docker environment
Prerequisites:
- [docker](https://docs.docker.com/installation/)
- [docker-machine](https://docs.docker.com/machine/install-machine/)
- [docker-compose](https://docs.docker.com/compose/install/)
- optionally, the [eb cli](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html) for deploying to Elastic Beanstalk

Please see the [documentation](https://docs.docker.com/machine/get-started/) on the Docker site on how to create a local development machine. Once you have created one, let's say it's called devlocal, run `eval(docker-machine env devlocal)`. This will configure you terminal session to point to the docker daemon running on your local machine.

Then, you need to have a configuration created in the `configs/local` directory. There are a lof of examples in [here](configs/local), so just take one and rename/change it for your needs. If your configuration is called `myslowsite` then just run:

`make run myslowsite`

Then open your browser and point to your local machine ip (`docker-machine ip devlocal` if you don't know it).
If everything goes as expected, you should see your site loading, with all the optimizations you have configured.


## Environment variables
- NGINX_PORT: the port on which nginx would listen (typically 8080)
- COOKIES: a pipe delimited list of cookie names that are whitelisted
- BACKEND: the fully qualified hostname for the backend (i.e. www.example.com)
- BACKENDS: a wildcard for other hostnames that are serving contents for the main site (i.e *.example.com)
- FRONTEND: the URL of the site, as it will appear to users (i.e. http://faster.example.com)
- SERVER_NAME: the fully qualified hostname for the fronted (i.e. faster.example.com) 
- PROXY_DOMAINS: a space separated list of fully qualified hostnames that can be safely considered part of the site (i.e. cdn.somesite.com js.somether.net)


