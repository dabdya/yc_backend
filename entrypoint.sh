#!bin/sh

# If database connection is changed, then replace this variables and update target group
DB_PATH="/ru-central1/b1g2msa8lla6blo6ic69/etn369sc1sguo6j3j2fm"
DB_ENDPOINT="grpcs://ydb.serverless.yandexcloud.net:2135"

python3 main.py -d $DB_PATH -e $DB_ENDPOINT -c key-ydb-fiit.json