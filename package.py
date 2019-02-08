from datetime import datetime
from datetime import datetime, timedelta
import time
import boto3
from dateutil import parser
import os

TAG_FILTER=os.environ['TAG_FILTER']
DELETE_OLDER_THAN_DAYS=os.environ['DELETE_OLDER_THAN_DAYS']
EXCLUSION_TAG =os.environ['EXCLUSION_TAG']

def lambda_handler(event, context):

    client = boto3.client('ec2')
    response = client.describe_images(Filters=[{'Name': 'tag:'+TAG_FILTER, 'Values': ['*']}])
    print('Total images with this tag '+ str(len(response['Images'])))
    i=0
    for img in response['Images']:
        datobj = parser.parse(img['CreationDate'])
        time_between_creation = datetime.now().replace(tzinfo=None) - datobj.replace(tzinfo=None)
        if time_between_creation.days > int(DELETE_OLDER_THAN_DAYS):
            delete = True
            for tag in img['Tags']:
                if tag['Key'] == EXCLUSION_TAG and tag['Value'] == 'True':
                    delete = False
            if delete:
                i+=1
                print("Deleting "+img['ImageId']+" "+img['Name'])
                responsederegister = client.deregister_image(ImageId=img['ImageId'])

    print('Number of images deleted '+str(i))
    return True
