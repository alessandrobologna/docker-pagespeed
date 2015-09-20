SHELL := /bin/bash
VPATH=configs/eb

ARGUMENT := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGUMENT):;@:)

checkarg:
	@if [ -z "${ARGUMENT}" ]; then echo "missing required argument"; exit 1; fi
	
run: checkarg build
	@echo "Starting  docker-compose for ${ARGUMENT}"
	@eval $$(cat configs/local/${ARGUMENT} | cut -d '#' -f 1 |  awk '{if (sub(/\\$$/,"")) printf "%s", $$0; else print $$0}' \
	  | sed "s/^/export /g" | grep "=" ) \
	  && docker ps -qa | xargs docker rm -fv && docker-compose up -d && docker-compose logs
	
build:
	@echo "Building local docker-compose stack"
	@docker-compose build
	
push: checkarg
	@echo "Building and pushing images to docker hub ${ARGUMENT} repository"
	@docker build -t ${ARGUMENT} docker/pagespeed
	@docker push ${ARGUMENT}

# The following rules are for Elastic Beanstalk deployment
%.zip: % 
	@echo "Building configuration $< for Amazon Beanstalk"
	@rm -rf target/$(<F)/.ebextensions 
	@rm -f target/$(<F)/*.zip 
	@mkdir -p target/$(<F)/.ebextensions
	@echo -e "option_settings:\n$$(cat $< | cut -d '#' -f 1 | awk '{if (sub(/\\$$/,"")) printf "%s", $$0; else print $$0}' | grep "=" |  while IFS='=' read -r name value; do echo "  - option_name: $$name\n    value: $$value"; done)" > target/$(<F)/.ebextensions/app.config
	@cp Dockerrun.aws.json target/$(<F)/Dockerrun.aws.json
	@cd target/$(<F) && zip -r app.zip Dockerrun.aws.json .ebextensions 

# runs eb init
init: checkarg 
	@mkdir -p target/${ARGUMENT}
	@if [ ! -f configs/eb/${ARGUMENT} ]; then  echo "missing ${ARGUMENT} in configs/eb, copying local"; cp configs/local/${ARGUMENT} configs/eb/${ARGUMENT}; fi
	@cd target/${ARGUMENT} && git init && eb init

# deploys the app to the specified environment	
deploy: checkarg ${ARGUMENT}.zip
	@echo "Deploying ${ARGUMENT} to Amazon Beanstalk"
	@mkdir -p target/${ARGUMENT}
	@cd target/${ARGUMENT} && git init && git add Dockerrun.aws.json .ebextensions app.zip && git commit -m "$$(date)" && eb deploy 


# deploy all apps
deployall:
	@echo "Deploying all apps to Amazon Beanstalk"
	@for target in target/*; do (if [ -d "$${target}/.elasticbeanstalk" ]; then echo "Deploying $$(basename $$target)";  make deploy $$(basename $$target)  &> "deploy-$$(basename $$target).log"; fi &) done; sleep 5; tail -f *.log

logs: checkarg 
	@cd target/${ARGUMENT} && eb logs
	
speedtest:
	@bash webpagetest.sh ${ARGUMENT}
