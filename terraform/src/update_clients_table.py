import boto3
import json
from json import JSONDecodeError
import os
import logging

# logger = logging.getLogger()
# logger.setLevel(logging.DEBUG)

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()


def handler(event: dict, context: LambdaContext):
    if os.environ.get("LOCALSTACK_HOSTNAME"):
        logger.info("Using localstack.")
        localstack_endpoint = f'http://{os.getenv("LOCALSTACK_HOSTNAME")}:{os.getenv("EDGE_PORT")}'
        s3 = boto3.resource('s3',endpoint_url=localstack_endpoint)
        dynamodb = boto3.resource('dynamodb', endpoint_url=localstack_endpoint)
    else:
        s3 = boto3.resource('s3')
        dynamodb = boto3.resource('dynamodb')
    
    clients_table = dynamodb.Table('clients')

    s3_bucket = event['Records'][0]['s3']['bucket']['name']
    s3_key = event['Records'][0]['s3']['object']['key']
  
    obj = s3.Object(s3_bucket, s3_key)
    file_content = obj.get()['Body'].read().decode('utf-8')
    try:
        json_data = json.loads(file_content)
    except JSONDecodeError as e:
        logger.error(f"Encountered corrupted JSON: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
    logger.info("Inserting data into dynamodb.")

    with clients_table.batch_writer() as batch:
        for item in json_data:
            batch.put_item(Item=item)

    some_binary_data = b'Here we have some data'
    obj = s3.Object(s3_bucket, 'test2.txt')
    print("Inserting data into s3...")
    obj.put(Body=some_binary_data)

    return {
        'statusCode': 200,
        'body': 'Successfully inserted data into dynamodb'  # Echo back the first key value
    }