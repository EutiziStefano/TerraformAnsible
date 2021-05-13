#!/bin/bash
mongo_dump_user=""
mongo_dump_password=""
mongo_dump_host="127.0.0.1"
mongo_dump_port="27017"
mongo_dump_db="db"
mongo_dump_storage="/data/backup"

find ${mongo_dump_storage} -name "*.gz" -type f -mtime +6 -exec rm -f {} \;

echo "create backup" $(date +%Y-%m-%d)

#mongodump --host ${mongo_dump_host} --db ${mongo_dump_db} --username ${mongo_dump_user} --password ${mongo_dump_password}  --gzip --archive=${mongo_dump_storage}/parser_$(date +%Y-%m-%d).gz


mongodump --host ${mongo_dump_host} --gzip --archive=${mongo_dump_storage}/backup_$(date +%Y-%m-%d).gz
