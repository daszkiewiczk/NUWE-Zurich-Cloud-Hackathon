import boto3
import json
from json import JSONDecodeError
import os
from jsonschema import Draft202012Validator
from jsonschema import SchemaError

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

    clients_data = load_clients_data(s3_bucket, s3_key)
    validate_clients_data(clients_data)
    clients_data = preprocess_clients_data(clients_data)
    update_table(clients_data)

    return {
        'statusCode': 200,
        'body': 'Success'
    }

def load_clients_data(s3_bucket, s3_key):
    try:
        obj = s3.Object(s3_bucket, s3_key)
        file_content = obj.get()['Body'].read().decode('utf-8')
        clients_data = json.loads(file_content)
    except s3.meta.client.exceptions.ClientError as e:
        logger.error(f"UNHANDLED error: {e}")
        return handle_error(e)   
    except JSONDecodeError as e:
        logger.error(f"{s3_key} is a corrupted json: {e}")
        return handle_error(e)
    else:
        return clients_data


def validate_clients_data(clients_data: dict):
    logger.info("Validating clients data.")
    try:
        clients_schema = json.loads(open("schema.json", "r").read())
        Draft202012Validator.check_schema(clients_schema)
    except JSONDecodeError as e:
        logger.error(f"schema.json file is corrupted: {e}")
        return handle_error(e)
    except SchemaError as e:
        print(f"schema.json is not a valid schema {e}")
        return handle_error(e)
    except FileNotFoundError as e:
        logger.error(f"schema.json file not found: {e}")
        return handle_error(e)
    except Exception as e:
        logger.error(f"Unhandled error: {e}")
        return handle_error(e)
    else:
        return clients_data
    
def preprocess_clients_data(clients_data: dict):
    """
    This function is used to add the plate attribute to items in clients_data.
    """
    logger.info("Preprocessing clients data.")
    for client in clients_data:
        plate = client['car']['plate']
        client['plate'] = plate
    return clients_data

def update_table(clients_data: dict):
    logger.info("Inserting data into dynamodb.")
    try:
        with dynamodb_table.batch_writer(overwrite_by_pkeys=[hash_key, sort_key]) as batch:
        # the overwrite_by_pkeys parameter is to handle duplicate entries
            for client in clients_data:
                batch.put_item(Item=client)
    except dynamodb.meta.client.exceptions.ClientError as e:
        logger.error(f"UNHANDLED error: {e}")
        return handle_error(e)
    else:
        return clients_data

def handle_error(e: Exception):
    return {
        'statusCode': 500,
        'body': f'Error: {e}'
    }