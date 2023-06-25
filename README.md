# NUWE-Zurich-Cloud-Hackathon
This repository is my entry in online phase of the NUWE x Zurich Cloud Challenge.

# How to run and test the solution
Install required dependencies (the auto-install.sh script has been extended to install awslocal and tflocal):
```
chmod u+x auto-install.sh
./auto-install.sh
```
Start localstack:
```
DEBUG=1 localstack start -d
```
Apply the terraform configuration:
```
cd terraform
tflocal init
tflocal apply -auto-approve
export BUCKET_NAME=$(tflocal output -raw bucket_name)
export TABLE_NAME=$(tflocal output -raw table_name)
```
Test the solution:
```
awslocal s3 cp ../client_data.json s3://$BUCKET_NAME
awslocal dynamodb scan --table-name $TABLE_NAME
```
To run in real AWS environment, run terraform with `stage` variable set to `prod`:
```
terraform apply -auto-approve -var stage=prod
```

# Architecture

### Storage
S3 bucket has been created with versioning enabled (as manual json file updates pose a data loss risk).

### Database
DynamoDB table has been created with a primary key of `id` and a sort key of `plate` (composite key).
This is to allow one client id to own multiple car objects, and to allow for quick lookups of cars by plate.

The table has been configured as global.

### Lambda
Lambda function is invoked on writes to the bucket. The function performs the following actions:
1. Reads the json file from the S3 bucket.
2. Validates the json file against the schema.
3.
   * If the json file is valid, prepares the data for insertion into the DynamoDB table (adds 'plate' as sort key).
   * If the json file is invalid, logs the error and exits. In the future it could be extended to send an email with the error message via SNS.
4. Inserts the data into the DynamoDB table.

As a workaround for LocalStack Community Edition not supporting Lambda Layers the dependencies have been packaged with Lambda function itself.

# Identified table access patterns
1. Get all cars owned by a client
2. Get cars with a specific plate
3. Get all cars with a specific plate owned by a client