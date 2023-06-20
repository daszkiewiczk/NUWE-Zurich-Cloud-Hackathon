import boto3
import json
from json import JSONDecodeError
import os

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

if os.environ.get("LOCALSTACK_HOSTNAME"):
    logger.info("Using localstack.")
    localstack_endpoint = f'http://{os.getenv("LOCALSTACK_HOSTNAME")}:{os.getenv("EDGE_PORT")}'
    logger.info(localstack_endpoint)
    s3 = boto3.resource('s3',endpoint_url=localstack_endpoint)
    dynamodb = boto3.resource('dynamodb', endpoint_url=localstack_endpoint)
else:
    s3 = boto3.resource('s3')
    dynamodb = boto3.resource('dynamodb')

table_name = os.environ.get('TABLE_NAME')
dynamodb_table = dynamodb.Table(table_name)

hash_key = os.environ.get('HASH_KEY')
sort_key = os.environ.get('SORT_KEY')

def handler(event: dict, context: LambdaContext):
    print("hot reload test")
    s3_bucket = event['Records'][0]['s3']['bucket']['name']
    s3_key = event['Records'][0]['s3']['object']['key']

    return update_table(s3_bucket, s3_key)
  

def update_table(s3_bucket: str, s3_key: str):
    try:
        obj = s3.Object(s3_bucket, s3_key)
        file_content = obj.get()['Body'].read().decode('utf-8')
        json_data = json.loads(file_content)
    except s3.meta.client.exceptions.ClientError as e:
        logger.error(f"UNHANDLED error: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }    
    except JSONDecodeError as e:
        logger.error(f"Encountered corrupted JSON: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
    
    logger.info("Inserting data into dynamodb.")
    try:
        with dynamodb_table.batch_writer(overwrite_by_pkeys=[hash_key, sort_key]) as batch:
        # the overwrite_by_pkeys parameter is to handle duplicate entries
            for item in json_data:
                # if hash_key not in item:
                #     logger.warning(f"missing id")
                #     continue
                # if 'car' not in item or 'plate' not in item['car']:
                #     logger.warning(f"missing car data")
                #     continue
                # plate = item['car']['plate']
                # item['plate'] = plate
                try:
                    r = batch.put_item(Item=item)
                    print(r.status_code)
                except Exception as e:
                    logger.debug(e)
                    continue
    except dynamodb.meta.client.exceptions.ClientError as e:
        logger.error(f"UNHANDLED error: {e}")
        return {
            'statusCode': 500,
            'body': f'Error: {e}'
        }
    

    return {
        'statusCode': 200,
        'body': 'Successfully inserted data into dynamodb',
    }