SHELL := /bin/bash

ARGUMENT := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGUMENT):;@:)

checkarg:
	@if [ -z "${ARGUMENT}" ]; then echo "missing required argument"; exit 1; fi
	
run: checkarg
	@echo "Starting  docker-compose for ${ARGUMENT}"
	@eval $$(bash scripts/environment ${ARGUMENT} local) \
		&& SITE=${ARGUMENT} && echo "$$(eval "echo -e \"$$(sed 's/\"/\\\"/g' templates/docker-compose.yml)\"")" > "docker-compose.yml" 
	@docker ps -qa | xargs docker rm -fv && docker-compose build && docker-compose  up -d && docker-compose logs

scale: checkarg 
	@echo "Scaling pagespeed to ${ARGUMENT} containers"
	@docker-compose scale pagespeed=${ARGUMENT} && docker-compose up -d  --force-recreate --no-deps nginx && docker-compose logs
	
push: checkarg
	@echo "Building and pushing images to docker hub ${ARGUMENT} repository"
	@docker build -t ${ARGUMENT} docker/pagespeed
	@docker push ${ARGUMENT}

# The following rules are for Elastic Beanstalk deployment
%.zip: configs/eb/% 
	@if [ ! -f "$</config" ]; then echo "Could not find $</config"; exit 1; fi
	@echo "Building configuration $< for Amazon Beanstalk"
	@rm -rf target/$(<F)/.ebextensions 
	@rm -f target/$(<F)/*.zip 
	@mkdir -p target/$(<F)/.ebextensions
	@echo -e "option_settings:\n$$(cat $</config | cut -d '#' -f 1 | awk '{if (sub(/\\$$/,"")) printf "%s", $$0; else print $$0}' | grep "=" | while IFS='=' read -r name value; do echo "  - option_name: $$name\n    value: $$value"; done)" > target/$(<F)/.ebextensions/app.config
	@[ -d "$</files" ] && tar -zcf target/$(<F)/.ebextensions/files.tgz -C "$</files" ./ 
	@[ -d "configs/shared/files" ] && tar -zcf target/$(<F)/.ebextensions/shared.tgz -C "configs/shared/files" ./ 
	@echo -e "container_commands:\n  copy:\n    command: cp .ebextensions/*.tgz /tmp/"  >> target/$(<F)/.ebextensions/app.config
	@eval $$(bash scripts/environment $(<F) eb) \
	 && echo "$$(eval "echo -e \"$$(sed 's/\"/\\\"/g' templates/Dockerrun.aws.json)\"")" > target/$(<F)/Dockerrun.aws.json 
	@cd target/$(<F) && zip -r app.zip Dockerrun.aws.json .ebextensions 

# runs eb init and create enviroment
init: checkarg 
	@mkdir -p target/${ARGUMENT}
	@if [ ! -f configs/eb/${ARGUMENT}/config ]; then  echo "missing config in configs/eb/${ARGUMENT}"; exit 1; fi
	@eval $$(bash scripts/environment ${ARGUMENT} eb) \
	 && rm -rf target/${ARGUMENT} \
	 && make "${ARGUMENT}.zip" \
	 && cd target/${ARGUMENT} && git init && git add Dockerrun.aws.json .ebextensions app.zip && git commit -m "$$(date)" \
	 && eb init ${EB_OPTIONS} \
	 && mkdir -p .elasticbeanstalk/saved_configs \
	 && echo "$$(eval "echo -e \"$$(sed 's/\"/\\\"/g' ../../templates/default.cfg.yml)\"")" > .elasticbeanstalk/saved_configs/default.cfg.yml \
	 && eb create --cname $$(echo $${EB_DOMAIN:-$${SERVER_NAME}} | sed s/.elasticbeanstalk.com//g) \
	 && cd ../.. && bash scripts/memcached ${ARGUMENT} $${MEMCACHED} \
	 && make deploy ${ARGUMENT} \
	 && cd target/${ARGUMENT} && eb open

# runs eb terminate and create enviroment
terminate: checkarg 
	@read -r -p "Are you sure? [y/N] " response; \
		[[ $$response =~ ^([yY][eE][sS]|[yY])$$ ]] \
		&& eval $$(bash scripts/environment ${ARGUMENT} eb) \
		&& bash scripts/memcached "${ARGUMENT}" "$${MEMCACHED}" delete \
		&& cd target/${ARGUMENT}  && eb terminate --force
		

# deploys the app to the specified environment	
eb: checkarg ${ARGUMENT}.zip
	@echo "Deploying ${ARGUMENT} to Amazon Beanstalk"
	@mkdir -p target/${ARGUMENT}
	@cd target/${ARGUMENT} && git init && git add Dockerrun.aws.json .ebextensions app.zip && git commit -m "$$(date)"  


# deploy all listed apps
deploy:
	@echo "Deploying ${ARGUMENT} to Amazon Beanstalk"
	@for target in ${ARGUMENT}; \
		do (if [ -d "target/$${target}/.elasticbeanstalk" ]; then echo "Deploying $$target";  make eb $$target && cd target/$$target && eb deploy  &> "../../logs/deploy-$$target.log"; fi &) done; \
		sleep 5; echo "done, tailing logs, safe to ctrl-c"; tails=$$(for target in ${ARGUMENT}; do echo "logs/deploy-$$target.log"; done); tail -f $$tails


cloudfront: checkarg
	@if [ ! -f configs/eb/${ARGUMENT}/config ]; then  echo "missing config in configs/eb/${ARGUMENT}"; exit 1; fi
	@eval $$(bash scripts/environment ${ARGUMENT} eb) \
	&& bash scripts/cloudfront ${ARGUMENT}
	
logs: checkarg 
	@cd target/${ARGUMENT} && eb logs ${EB_OPTIONS}
	
speedtest:
	@bash scripts/speedtest ${ARGUMENT}
