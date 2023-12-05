import base64
import boto3
import json

def lambda_handler(event, context):
    bucket_name = "92023-typaladin-dndapp"
    s3_obj_key = "images/ty.jpg"
    s3_client = boto3.client('s3', 'us-east-1')

    response = s3_client.get_object(
        Key=s3_obj_key,
        Bucket=bucket_name
    )
    
    print("response=", response)
    image = response['Body'].read()
    print("image=", image)
    res_body = {"base64_image_data": base64.b64encode(image).decode('utf-8')}
    print("res_body=", res_body)
   
    res = {
        "headers": {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "image/jpeg"
        },
        "statusCode": 200,
        "body": json.dumps(res_body)
        # "isBase64Encoded": True
    }
    return res
