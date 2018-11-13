#!/bin/bash
export DB_HOST=${db_ip}
cd /home/ubuntu/app
pm2 start app.js
