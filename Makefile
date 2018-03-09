###############
## Variables ##
###############

.DEFAULT_GOAL = build
.PHONY: init-stack validate-stack delete-stack test-stack build dist list-exports prepare deploy test clean help

aws.region := us-east-1
aws.profile := sandbox

project.name := lambda-py2go-flip
project.repo := github.com/scottbrown/$(project.name)

export.name := $(project.name):lambda:arn

template.name := lambda-python.cft

pwd := $(shell pwd)

build.dir := .build
build.filename := main
build.file := $(build.dir)/$(build.filename)

dist.dir := $(pwd)/.dist
dist.filename := artifact.zip
dist.file := $(dist.dir)/$(dist.filename)

#######################
## CFN Stack Targets ##
#######################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Creates the stack in AWS (!!! MAY INCUR COSTS !!!)
	# This is where you would add termination protection if this were
	# a real application so that `make delete-stack` doesn't cause any
	# accidental harm.
	aws cloudformation create-stack --stack-name $(project.name) --region $(aws.region) --template-body file://$(template.name) --profile $(aws.profile) --capabilities CAPABILITY_IAM

validate-stack: ## Check on the stack's status by grabbing its last event from CFN
	aws cloudformation describe-stack-events --stack-name $(project.name) --region $(aws.region) --profile $(aws.profile) --query 'StackEvents[0]'

delete-stack: ## Remove the stack from AWS
	aws cloudformation delete-stack --stack-name $(project.name) --region $(aws.region) --profile $(aws.profile)

test-stack: ## Invokes the Lambda function within AWS
	aws lambda invoke --function-name $(shell aws cloudformation list-exports --region $(aws.region) --query 'Exports[?Name == `$(export.name)`].Value' --profile $(aws.profile) --output text) --region $(aws.region) --profile $(aws.profile) result.out

##################
## Code Targets ##
##################

build: ## Compiles the application
	GOOS=linux GOARCH=amd64 go build -o $(build.file) $(project.repo)

dist: ## Creates a distributable Linux artifact suitable for Lambda
	mkdir -p $(dist.dir)
	cd $(build.dir) && zip $(dist.file) $(build.filename)

list-exports: ## Lists the stack exports (for testing)
	aws cloudformation list-exports --region $(aws.region) --query 'Exports[?Name == `$(export.name)`].Value' --profile $(aws.profile) --output text

prepare: ## Updates the Lambda to accept Go code
	aws lambda update-function-configuration --function-name $(shell aws cloudformation list-exports --region $(aws.region) --query 'Exports[?Name == `$(export.name)`].Value' --profile $(aws.profile) --output text) --handler main --runtime go1.x --region $(aws.region) --profile $(aws.profile)
	
deploy: ## Deploys the artifact to Lambda
	aws lambda update-function-code --function-name $(shell aws cloudformation list-exports --region $(aws.region) --query 'Exports[?Name == `$(export.name)`].Value' --profile $(aws.profile) --output text) --region $(aws.region) --profile $(aws.profile) --zip-file fileb://$(dist.file)

test: ## Performs local testing of app
	go test $(project.repo)

clean: ## Remove any temporary project directories
	rm -rf $(dist.dir)
	rm -rf $(build.dir)

