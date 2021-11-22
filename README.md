# lambda-basicauth-authorizer

## Requires

- awscli
- python39


## Install BASIC_AUTH custom authorizer to APIGateway

### Deploy and install Authorizer

1. Create s3 bucket for custom auth function:

    > RESTAPI_ID is the ID to an existing API Gateway RestAPI.
    > List existing RestAPI Ids with the awscli command:
    > `aws apigateway get-rest-apis`

    > PROJECTID is a unique identifier for your project so that S3 buckets do not collide

    ```bash
    export BASIC_AUTH_USERNAME={YOUR USERNAME}
    export BASIC_AUTH_PASSWORD={YOUR PASSWORD}
    export PROJECTID={YOUR PROJECT IDENTIFIER}
    export RESTAPI_ID={YOUR RESTAPI ID}
    make createfuncbucket
    ```

2. Create Package, place in bucket, integrate custom auth function to existing :

    ```bash
    make deploy
    make install
    ```

### Update authorizer code

The following procedure is used to make updates to the deployed authorizer, should any code changes be made within the authorizer:

    > Assumes you have already performed the initial _Deploy and install Authorizer_ steps above.

    ```bash
    export BASIC_AUTH_USERNAME={YOUR USERNAME}
    export BASIC_AUTH_PASSWORD={YOUR PASSWORD}
    export PROJECTID={YOUR PROJECT IDENTIFIER}
    export RESTAPI_ID={YOUR RESTAPI ID}
    make updatefunc
    ```