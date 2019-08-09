"""Installs the BASICAuth custom authorizer into an existing APIGateway deployment"""
import sys
import json
import logging

import boto3

APIGW = boto3.client(
    'apigateway'
)


logging.basicConfig(
    stream=sys.stdout,
    level=logging.DEBUG,
    format='%(asctime)s [%(levelname)s] (%(name)s) %(funcName)s: %(message)s'
)

logging.getLogger('urllib3').setLevel(logging.WARNING)
logging.getLogger('botocore').setLevel(logging.WARNING)
logging.getLogger('boto3').setLevel(logging.WARNING)

logger = logging.getLogger('basicauth-installer')


def install_authorizer_to_restapi_methods(restapi_id: str):
    # get authorizer id
    response = APIGW.get_authorizers(
        restApiId=restapi_id,
    )
    assert 'items' in response
    assert len(response['items']) == 1  # should only have one authorizer defined

    authorizer_info = response['items'][0]
    # {
    #     "id": "ym448e",
    #     "name": "BasicAuthAuthorizer-{PROJECTID}",
    #     "type": "REQUEST",
    #     "authType": "custom",
    #     "authorizerUri": "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:REGION:ACCOUNT:function:LAMBDA_FUNCTION/invocations",
    #     "identitySource": "method.request.header.Authorization",
    #     "authorizerResultTtlInSeconds": 300
    # }
    authorizer_id = authorizer_info['id']
    authorizer_name = authorizer_info['name']

    # update resource methods with authorizer
    response = APIGW.get_resources(
        restApiId=restapi_id,
    )
    if 'items' in response:
        for resource in response['items']:
            # {
            #     "id": "i4moabc",
            #     "parentId": "nw3sd3n123",
            #     "pathPart": "{proxy+}",
            #     "path": "/{proxy+}",
            #     "resourceMethods": {
            #         "ANY": {}
            #     }
            # }
            for method in resource['resourceMethods'].keys():  # Not sure what the value is here and if it's needed for anything, ignoring for now.
                resource_id = resource['id']

                # apply authorizer to method
                operations = [
                    {
                        'op': 'replace',
                        'path': '/authorizationType',  # path to the field to update in the Method JSON representation
                        'value': 'CUSTOM',
                    },
                    {
                        'op': 'replace',
                        'path': '/authorizerId',
                        'value': authorizer_id,
                    }
                ]
                response = APIGW.update_method(
                    restApiId=restapi_id,
                    resourceId=resource_id,
                    httpMethod=method,
                    patchOperations=operations
                )
                response.pop('ResponseMetadata')  # remove noisy
                formatted_response = json.dumps(response, indent=4)
                logger.info(f'CUSTOM authorizer "{authorizer_name}({authorizer_id})" applied to restAPI Method: {formatted_response}')


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        '-r', '--restapi-id',
        dest='restapi_id',
        required=True,
        type=str,
        help='RESTAPI ID of api to apply custom authorizer to api member methods',
    )

    args = parser.parse_args()
    install_authorizer_to_restapi_methods(args.restapi_id)
