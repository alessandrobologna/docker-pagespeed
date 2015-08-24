SHELL := /bin/bash
	
%.zip: configs/%
	@echo "Building configuration for Amazon Beanstalk $@"
	@rm -f .ebextensions/* 
	@mkdir -p .ebextensions && eval $$(cat $< | grep "=" | sed "s/^/export /g") && echo "$$(eval "echo -e \"$$(sed 's/\"/\\\"/g' sample.config)\"")" > .ebextensions/$(@F).config
	@zip -r $@ Dockerrun.aws.json .ebextensions

