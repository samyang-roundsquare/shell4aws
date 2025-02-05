#!/usr/bin/env bash
# preconfig : sudo -i (root's configure)
# aws configure
# AWS Access Key ID [None]: 해당되는 Key ID를 입력합니다.
# AWS Secret Access Key [None]: 해당되는 Secret Access Key를 입력합니다.
# Default region name [None]: 기본 레전을 입력합니다. ie) ap-northeast-2
# Default output format [None]:

########################################################################
# Utility script to update a domain in Route53 with current IP address.
#
# Parameters:
#       $1: The hosted zone ID
#       $2: The name of the domain
########################################################################

# Check params are passed.
if [ "$#" -ne 2 ]; then
  echo "***ERROR Parameters not passed. You need to pass two parameters:"
  echo "The hosted zone ID, the domain name you are about to update."
  exit
fi


# Define the JSON payload to send to Route53.
UPDATE_REQUEST='
{
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "__domain__",
          "Type": "A",
          "TTL": 600,
          "ResourceRecords": [
            {
              "Value": "__ip__"
            }
          ]
        }
      }
    ]
  }
'

# Get the current IP and store it in a file, so that we don't perform unnecessary updates.
touch /tmp/ipupdate-lastip.txt
# CURRENT_IP=$(curl -s http://ifconfig.co)
CURRENT_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PREVIOUS_IP=$(</tmp/ipupdate-lastip.txt)
echo $CURRENT_IP > /tmp/ipupdate-lastip.txt

# Debug output.
echo Current IP: $CURRENT_IP
echo Previous IP: $PREVIOUS_IP

# Check if the IP has changed and proceed with update if necessary.
if [ "$CURRENT_IP" == "$PREVIOUS_IP" ]; then
  logger -s "IP not changed (IP: $CURRENT_IP)"
else
  logger -s "IP changed (Before: $PREVIOUS_IP, Now: $CURRENT_IP)"
  UPDATE_REQUEST=$(echo $UPDATE_REQUEST | sed s/__domain__/$2/)
  UPDATE_REQUEST=$(echo $UPDATE_REQUEST | sed s/__ip__/$CURRENT_IP/)
  #echo $UPDATE_REQUEST
  echo $UPDATE_REQUEST > /tmp/ipupdate-request.json
  aws route53 change-resource-record-sets \
        --hosted-zone-id $1 \
        --change-batch file:///tmp/ipupdate-request.json
fi
