# lambda-basicauth-authorizer

## Requires

- awscli
- python37


## Install BASIC_AUTH custom authorizer to APIGateway


Create command?
```
pipenv run python -m authorizers.install --user ${USERNAME} --password ${PASSWORD}
```

### Install via SAM Template

1. Create s3 bucket for custom auth function:

    > RESTAPI_ID is the ID to an existing API Gateway RestAPI.
    > List existing RestAPI Ids with the awscli command
    >

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
    ```
