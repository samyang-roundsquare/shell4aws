#!/usr/bin/env bash
# 루트 사용자 변경 (간단하게 sudo -i 실행)
if [ "$(id -u)" -ne 0 ]; then
    echo "현재 사용자가 루트가 아닙니다. 루트 권한을 얻기 위해 sudo -i를 실행합니다."
    sudo -i
    if [ $? -ne 0 ]; then
        echo "sudo -i 실행에 실패했습니다. sudo로 스크립트를 다시 실행합니다."
        exec sudo bash "$0" "$@"
        exit
    fi
fi

$(aws configure)
# Check params are passed.
# if [ "$#" -ne 4 ]; then
#   echo "***ERROR Parameters not passed. You need to pass two parameters:"
#   echo "The hosted zone ID, the domain name you are about to update."
#   exit
# fi
$(printf '사용하실 도메인을 입력해 주세요.')
read $domain

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
        --hosted-zone-id $domain \
        --change-batch file:///tmp/ipupdate-request.json
fi
