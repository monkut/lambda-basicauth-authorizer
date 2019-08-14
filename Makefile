.PHONY: clean data lint requireme

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
AWS_ACCOUNT := $(shell aws sts get-caller-identity --profile ${AWS_PROFILE} --query 'Account' --output text)
PROJECT_NAME = authorizers
FUNCTION_BUCKET := lba-apigw-basicauthfunc-${PROJECTID}

#################################################################################
# COMMANDS                                                                      #
#################################################################################


## Run flake8 and pydocstyle
flake8:
	pipenv run flake8 --max-line-length 150 --max-complexity 15 --ignore F403,F405,E252 rcs_api_tester/
	pipenv run pydocstyle --ignore D104,D106,D200,D203,D204,D205,D212,D213,D301,D400 rcs_api_tester/

## run pylint
pylint:
	pipenv run pylint --rcfile .pylintrc authorizers/

mypy:
	export MYPYPATH=./stubs/ mypy
	pipenv run mypy -m authorizers/ --disallow-untyped-defs --ignore-missing-imports

## Run tests (without coverage)
test:
	PIPENV_DOTENV_LOCATION=.env pipenv run pytest -v

## Run tests (with coverage)
coverage:
	PIPENV_DOTENV_LOCATION=.env pipenv run pytest --cov authorizers/ --cov-report term-missing

createfuncbucket:
	aws s3api create-bucket --bucket ${FUNCTION_BUCKET} --region ap-northeast-1 --create-bucket-configuration LocationConstraint=ap-northeast-1

zipcode:
	zip -r function.zip authorizers/

putcode:
	aws s3 cp function.zip s3://${FUNCTION_BUCKET}

updatefunc: zipcode putcode
	aws lambda update-function-code --function-name $(shell aws lambda list-functions --query "Functions[?starts_with(FunctionName, '${FUNCTION_BUCKET}')].[FunctionName]" --output text) --s3-bucket ${FUNCTION_BUCKET} --s3-key function.zip
	aws lambda publish-version --function-name $(shell aws lambda list-functions --query "Functions[?starts_with(FunctionName, '${FUNCTION_BUCKET}')].[FunctionName]" --output text)

installauthorizer:
	pipenv run python -m authorizers.install --restapi-id ${RESTAPI_ID}

deploy: checkenv
	aws cloudformation deploy --template-file ./infrastructure/cfn/apigateway_customauth.cfn.yaml --stack-name ${FUNCTION_BUCKET} \
        --parameter-overrides \
            AwsAccount=${AWS_ACCOUNT} \
            ProjectId=${PROJECTID} \
            BasicAuthUsername=${BASIC_AUTH_USERNAME} \
            BasicAuthPassword=${BASIC_AUTH_PASSWORD} \
            TargetRestApiId=${RESTAPI_ID} \
            FunctionBucket=${FUNCTION_BUCKET} \
        --capabilities CAPABILITY_IAM

install: updatefunc installauthorizer

## Define checks to run on PR
check: flake8 pylint coverage


checkenv:
    ifndef AWS_PROFILE
        $(error Required environment variable, 'AWS_PROFILE' not set!)
    endif
    ifndef BASIC_AUTH_USERNAME
        $(error Required environment variable, 'BASIC_AUTH_USERNAME' not set!)
    endif
    ifndef BASIC_AUTH_PASSWORD
        $(error Required environment variable, 'BASIC_AUTH_PASSWORD' not set!)
    endif
    ifndef RESTAPI_ID
        $(error Required environment variable, 'RESTAPI_ID' not set!)
    endif
    ifndef PROJECTID
        $(error Required environment variable, 'PROJECTID' not set!)
    endif


#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available commands:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
