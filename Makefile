SHELL := /bin/bash

ARGUMENT := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGUMENT):;@:)

checkarg:
	@if [ -z "${ARGUMENT}" ]; then echo "missing required argument"; exit 1; fi
	
run: checkarg build
	@echo "Starting  docker-compose for ${ARGUMENT}"
	@eval $$(bash make-env ${ARGUMENT} local) \
		&& docker ps -qa | xargs docker rm -fv && docker-compose up -d && docker-compose logs
	
build:
	@echo "Building local docker-compose stack"
	@docker-compose build
	
push: checkarg
	@echo "Building and pushing images to docker hub ${ARGUMENT} repository"
	@docker build -t ${ARGUMENT} docker/pagespeed
	@docker push ${ARGUMENT}

# The following rules are for Elastic Beanstalk deployment
%.zip: configs/eb/% 
	@if [ ! -f "$<" ]; then echo "Could not find $<"; exit 1; fi
	@echo "Building configuration $< for Amazon Beanstalk"
	@rm -rf target/$(<F)/.ebextensions 
	@rm -f target/$(<F)/*.zip 
	@mkdir -p target/$(<F)/.ebextensions
	@echo -e "option_settings:\n$$(cat $< | cut -d '#' -f 1 | awk '{if (sub(/\\$$/,"")) printf "%s", $$0; else print $$0}' | grep "=" |  while IFS='=' read -r name value; do echo "  - option_name: $$name\n    value: $$value"; done)" > target/$(<F)/.ebextensions/app.config
	@cp Dockerrun.aws.json target/$(<F)/Dockerrun.aws.json
	@cd target/$(<F) && zip -r app.zip Dockerrun.aws.json .ebextensions 

# runs eb init and create enviroment
init: checkarg 
	@mkdir -p target/${ARGUMENT}
	@if [ ! -f configs/eb/${ARGUMENT} ]; then  echo "missing ${ARGUMENT} in configs/eb"; exit 1; fi
	@eval $$(bash make-env ${ARGUMENT} eb) \
	 && rm -rf target/${ARGUMENT} \
	 && make "${ARGUMENT}.zip" \
	 && cd target/${ARGUMENT} && git init && git add Dockerrun.aws.json .ebextensions app.zip && git commit -m "$$(date)" \
	 && eb init ${AWS_OPTIONS} \
	 && mkdir -p .elasticbeanstalk/saved_configs && cp ../../default.cfg.yml .elasticbeanstalk/saved_configs/default.cfg.yml \
	 && eb create --cname $$(echo $${SERVER_NAME} | cut -d '.' -f1) \
	 && cd ../.. && bash make-ingress ${ARGUMENT} $${MEMCACHED} \
	 && make deploy ${ARGUMENT} \
	 && cd target/${ARGUMENT} && eb open

# runs eb terminate and create enviroment
terminate: checkarg 
	@read -r -p "Are you sure? [y/N] " response; \
		[[ $$response =~ ^([yY][eE][sS]|[yY])$$ ]] \
		&& eval $$(bash make-env ${ARGUMENT} eb) \
		&& bash make-ingress ${ARGUMENT} $${MEMCACHED} delete \
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

logs: checkarg 
	cd target/${ARGUMENT} && eb logs ${EB_OPTIONS}
	
speedtest:
	@bash webpagetest.sh ${ARGUMENT}
