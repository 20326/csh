#!/usr/bin/env bash
#
# Copyright (c) 2021-2022 brian
#
# Short: https://git.io/csh-buildctrl.sh
# File name: lego.sh
# Description: Build control.sh
# System Required: GNU/Linux
# Version: 1.0
##############################################################
## Project Vars
BIN_FILE=""
BIN_PARAM=""

##############################################################
## Project code
build_control() {
  cat <<EOF > control.sh
#!/bin/bash

binfile=BIN_FILE

cwd=\$(
  cd $(dirname \$0)/
  pwd
)
cd \$cwd

usage() {
  echo \$"Usage: \$0 {start|stop|restart|status}"
  exit 0
}

start() {
  if [ ! -f \$binfile ]; then
    echo "file[\$binfile] not found"
    exit 1
  fi

  if [ \$(pidof "\$binfile") ]; then
    echo "\${binfile} already started"
    return
  fi

  # add custom cmd for start service

  echo "[run] \$cwd/\$binfile BIN_PARAM &> stdout.log &"
  nohup \$cwd/\$binfile BIN_PARAM &> stdout.log &

  for ((i = 1; i <= 15; i++)); do
    if [ \$(pidof "\$binfile") ]; then
      echo "\${binfile} started"
      return
    fi
    sleep 0.5
  done

  echo "cannot start \${binfile}"
  exit 1
}

stop() {
  if [ ! \$(pidof "\$binfile") ]; then
    echo "\${binfile} already stopped"
    return
  fi

  pidof "\$binfile" | xargs kill
  for ((i = 1; i <= 15; i++)); do
    if [ ! \$(pidof "\$binfile") ]; then
      echo "\${binfile} stopped"
      return
    fi
    sleep 0.5
  done

  echo "cannot stop \${binfile}"
  exit 1
}

restart() {
  stop
  start
  status
}

status() {
  ps aux | grep -v grep | grep \${binfile}
  echo "pid: \$(pidof \$binfile)"
}

case "\$1" in
start)
  start
  ;;
stop)
  stop
  ;;
restart)
  restart
  ;;
status)
  status
  ;;
*)
  usage
  ;;
esac
EOF
sed -i "s/BIN_FILE/${BIN_FILE}/g" ./control.sh
sed -i "s/BIN_PARAM/${BIN_PARAM}/g" ./control.sh
chmod +x ./control.sh
}


## Show help
show_help() {
  echo "usage: ./${PROJECT_NAME} [-h] -b bin_file -p parameter"
  echo '  -b            : set bin file name'
  echo '  -p            : set bin parameter'
  echo '  -h, --help    :  Show help'
  echo ''
  echo '> bash <(curl -fsSL git.io/csh-buildctrl.sh)'
  exit 0
}

# init args
init_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -b) BIN_FILE="$2"; shift ;;
            -p) BIN_PARAM="$2"; shift ;;
            -h | --help) show_help ;;
            *) ERRO "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done
}


main() {
    init_args "$@"
    build_control
}

main "$@" || exit 1