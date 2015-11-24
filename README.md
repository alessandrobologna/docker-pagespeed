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

Please see the [documentation](https://docs.docker.com/machine/get-started/) on the Docker site on how to create a local development machine, or check this asciicast:

[![asciicast](https://asciinema.org/a/38q72m1cpxupcdng4h7klfmkc.png)](https://asciinema.org/a/38q72m1cpxupcdng4h7klfmkc)

Once you have created one, let's say it's called _pagespeed_, run `eval "$(docker-machine env pagespeed)"`. This will configure you terminal session to point to the docker daemon running on your local machine.

Then, you need to have a configuration created in the `configs/local` directory. There are a lof of examples in [here](configs/local), so just take one and rename/change it for your needs. If your configuration is called `myslowsite` then just run:

`make run myslowsite`

If it's the first time you are running this, it will take quite some time, because docker will need to download the base images, compile nginx, a varnish module and then finally start:

[![asciicast](https://asciinema.org/a/9xqra2khlvrxap1crhk431w01.png)](https://asciinema.org/a/9xqra2khlvrxap1crhk431w01)

Then open your browser and point to your local machine ip (try `open $(docker-machine ip devlocal)` if you don't know it).
If everything goes as expected, you should see your site loading, with all the optimizations you have configured.

You can make further changes, and run again, this time it will take just a few seconds:
[![asciicast](https://asciinema.org/a/d3r596ztv4l6ylym28co3spkg.png)](https://asciinema.org/a/d3r596ztv4l6ylym28co3spkg)

### On Elastic Beanstalk

This assumes that you know how to [create an application](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.deployment.newapp.html) (use the latest docker based option). Once your application is created, you will need to [launch an enviroment] (http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.environments.html) which will be used by your site.  The makefile will help you to create an environment for each site. Make sure your configuration for `myslowsite` is the configs/eb directory. Then run
`make init myslowsite`
and answer to the prompts to let Elastic Beanstalk know what environment you intend to use.
Also, you can watch this asciicast:
[![asciicast](https://asciinema.org/a/buetw5q0n15uc89p6g4plhkkh.png)](https://asciinema.org/a/buetw5q0n15uc89p6g4plhkkh)

You can deploy anytime, just using run `make deploy myslowsite` and wait until it's done. You should have a site running at whatever URL you assigned to it.
[![asciicast](https://asciinema.org/a/4yenmdqwk187j61ex5ykvczn8.png)](https://asciinema.org/a/4yenmdqwk187j61ex5ykvczn8)

### Deployment of the CDN on CloudFront

If you want to test integration with CloudFront as a downstream caching layer, you can just run `make cloudfront myslowsite` which will also locate the zone on Route53 and setup the DNS names (as CNAMES to the Elastic Beanstalk environment, and, if you have defined a CDN sharding, the corresponding CNAMES).
[![asciicast](https://asciinema.org/a/4zc9udjikuh02mnlumklulrok.png)](https://asciinema.org/a/4zc9udjikuh02mnlumklulrok)





## Environment variables
  - BACKEND: This is the address of the origin servers (for instance, origin.myslowsite.com)
  - BACKENDS: If the origin server is doing some kind of domain sharding, where cdn1.mysite.com/js/jsfile.cs and cdn2.mysite.com/css/cssfile.css are really just aliases for www.mysite.com/js or www.mysite.com/css, you can just add here a "*.mysite.com" to indicate that all those domains are really something that pagespeed can handle more efficienlty by fetching resources from the origin. 
  - SERVER_NAME: This is the plain hostname, so www.mysite.com.
  - FRONTEND: This is the domain that you will use, facing the internet. Typically, www.mysite.com
  - PROXY_DOMAINS: (Optional) This is a white space delimited list of domains that your site is fetching resources from. Third party JS, CSS, images. They all go there. The resources they are serving will be optimized and served from www.mysite.com/proxy/the.other.domain
  - PROXY_HTTPS_DOMAINS: (Optional) Same as above, but for third party that want you to use their ssl servers.
  - COOKIES: if cookies are really needed for your backend to work, you can list them here. Remember, cookies are really a _bad thing_. But if you need cookieA and cookieB, just specify "cookieA|cookieB" 
  - ALLOW_ROBOTS: (Optional) Don't set this variable if you are testing, it will by default send all crawlers somewhere else (because you are just testing and don't want that to be on google). If instead you want the serve the proper robots.txt from your origin, set this to "true" or "yes".
  - FILTERS_ON: (Optional) A white space delimited list of settings (yes, they are actually pagespeed settings, not filters, don't ask) that you want to activate for your site. Note that a sane set of settings is already configured. You may want to check [here](https://github.com/alessandrobologna/docker-pagespeed/blob/master/docker/pagespeed/sites-enabled/template) to see what's already enabled. For instance, "UseExperimentalJsMinifier"
  - FILTERS_OFF: (Optional) Just the opposite of the above. Does one setting break your site? Does it slow it down? List it here (white spaces delimited list). For instance, "AvoidRenamingIntrospectiveJavascript".
  - FILTERS_ENABLED: (Optional) The filters that you want, on top of what's already  [here](https://github.com/alessandrobologna/docker-pagespeed/blob/master/docker/pagespeed/sites-enabled/template), in the usual white space delimited list. For instance "inline_preview_images resize_mobile_images"
  - FILTERS_DISABLED: (Optional) The filters that you don't want to have running on your site out of those enabled by default [here](https://github.com/alessandrobologna/docker-pagespeed/blob/master/docker/pagespeed/sites-enabled/template)
  - CUSTOM_SETTINGS: (Optional) As the name says, custom setting for Pagespeed that are not just "on" or off". For instance, "pagespeed MaxSegmentLength 250;". Note that in this case, you will need to respect the full syntax for pagespeed.
  - MEMCACHED: (Optional) In a local configuration, this is not required, as a memcached daemon will be started automatically for you. If you are running this on AWS (or elsewhere), just list the address of the memcached servers.  The port number is assumed to be the standard one, so you don't need to specifiy it here.
    MEMCACHED_SIZE: (Optional)
    MAX_REQUESTS: (Optional)
    HEALTCHECK: (Optional)
    TTL: (Optional)
    S_MAXAGE: (Optional)
    GRACE: (Optional)
    S_MAXAGE: (Optional)
    DEBUG: (Optional)
    IF_DESKTOP: (Optional)
    IF_MOBILE: (Optional)


