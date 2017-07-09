#!/bin/sh

NODE_TYPE=$1
DB_HOST=${DB_HOST:=db}

bench use localhost

echo 'Waiting for DB to start up'

dockerize -wait tcp://db:3306 -timeout 120s


TASK=$(case "$NODE_TYPE" in
  ("app") echo "/home/frappe/frappe-bench/env/bin/gunicorn -b 0.0.0.0:8000 -w 4 -t 120 frappe.app:application --preload" ;;
  ("setup") echo "echo \"Setup Finished \" " ;;
  ("update") echo "/usr/bin/bench update --no-git" ;;
  ("backup") echo "/usr/bin/bench backup && echo \"Backup Finished \" " ;;
  ("restore") echo "echo \"Restore Finished \" " ;;
  ("migrate") echo "/usr/bin/bench migrate" ;;
  ("scheduler") echo "/usr/bin/bench schedule" ;;
  ("worker-default") echo "/usr/bin/bench worker --queue default" ;;
  ("worker-long") echo "/usr/bin/bench worker --queue long" ;;
  ("worker-short") echo "/usr/bin/bench worker --queue short" ;;
  ("node-socketio") echo "node /home/frappe/frappe-bench/apps/frappe/socketio.js" ;;
  (*) ;;
esac)

if [ ${NODE_TYPE} = "setup" ]; then

  cd /home/frappe/frappe-bench
  bench reinstall && \
  ls apps/ | while read -r file; do  if [ $file != "frappe" ]; then bench install-app $file; fi; done

fi;

if [ ${NODE_TYPE} = "restore" ]; then

  cd /home/frappe/frappe-bench

  i=1
  for file in sites/localhost/private/backups/*
  do
      echo "$i $file"
      i=$(($i+1))
  done

  read -p "Enter the number of file which you want to restore : " n

  i=1
  for file in sites/localhost/private/backups/*
  do
      if [ $n = $i ]; then
        echo "You have choosed $i $file"
        echo "Please wait ..."
        bench --force restore $file
      fi;
      i=$(($i+1))
  done

fi;


if [ ${NODE_TYPE} = "app" ]; then

  cd /home/frappe/frappe-bench/sites

fi;

(eval $TASK | tee /home/frappe/frappe-bench/logs/${NODE_TYPE}.log) 3>&1 1>&2 2>&3 | tee /home/frappe/frappe-bench/logs/${NODE_TYPE}.err.log
