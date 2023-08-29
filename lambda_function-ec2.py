import boto3
import datetime

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    # Define the tag key and value to identify instances to start or stop
    tag_key = 'AutoStartStop'
    tag_value = 'true'

    # Get current time in IST
    current_time = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=5, minutes=30)))

    # Determine action based on time
    if current_time.weekday() < 5:  # Monday to Friday
        if current_time.time() >= datetime.time(9, 00) and current_time.time() < datetime.time(21, 00):
            action = 'start'
        else:
            action = 'stop'
    else:
        action = 'stop'

    # Get instances based on tag
    filters = [{'Name': f'tag:{tag_key}', 'Values': [tag_value]}]
    instances = ec2.describe_instances(Filters=filters)

    instance_ids = [instance['InstanceId'] for reservation in instances['Reservations'] for instance in reservation['Instances']]
    
    # Print instance IDs
    #print(f"Instances to {action}: {', '.join(instance_ids)}")

    # Start or stop instances based on action
    if action == 'start':
        ec2.start_instances(InstanceIds=instance_ids)
    elif action == 'stop':
        ec2.stop_instances(InstanceIds=instance_ids)

    return {
        'statusCode': 200,
        'body': f'Instances {action}ed successfully'
    }