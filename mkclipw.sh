#!/usr/bin/env bash
PROPERTY=$1
VALUE=$2
if [ -z $3 ]
then
  KEY=$(cat key.pub)
else
  KEY=$3
fi
printf '{ "key": "%s"}' $KEY > file.json
curl -H  "Content-Type: application/json" -X POST -d @file.json 'https://portal.muuktest.com:8081/generate_token_executer' -o "token.json"
curl -X POST https://portal.muuktest.com:8081/api/v1/downloadpwfiles -k -d @file.json -H "Content-Type: application/json" -o ./config.zip
unzip -o config.zip -d .
TOKEN=$(jq --raw-output .token token.json)
printf "Authorization: Bearer %s" $TOKEN > header.txt
MUUK_USERID=$(jq --raw-output .userId token.json)
printf '{"property": "%s", "value": ["%s"], "platform": "pw", "userId": "%s"}' $PROPERTY $VALUE $MUUK_USERID > body.json
curl -X POST https://portal.muuktest.com:8081/download_byproperty -H @header.txt -d @body.json -H "Content-Type: application/json" -o ./test.zip
[ -d "./test" ] && rm -r test
unzip test.zip -d ./test
echo "Executing tests on Playwright"
npx playwright test --workers=4
echo "Execution Completed."
