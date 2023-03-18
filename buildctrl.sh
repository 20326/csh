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
SRV_NAME=""

# fonts color
ERRO(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
INFO(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
WARN(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
SUCC(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
BOLD(){
    echo -e "\033[1m\033[01m$1\033[0m"
}
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

  INFO "usage: control.sh"
  BOLD "./control.sh start | stop | status | reload"
}

build_service() {
  cwd=$(
    cd ./
    pwd
  )
  if [ ! -n "${SRV_NAME}" ]; then
    SRV_NAME=${BIN_FILE}
  fi
  cat <<EOF > ${SRV_NAME}.service
[Unit]
Description="${SRV_NAME}"

[Service]
Type=simple
ExecStart=$cwd/${BIN_FILE}
WorkingDirectory=$cwd

Restart=always
RestartSecs=1s
SuccessExitStatus=0
LimitNOFILE=65536
StandardOutput=file:/var/log/${BIN_FILE}.log
StandardError=file:/var/log/${BIN_FILE}_error.log
SyslogIdentifier=${SRV_NAME}


[Install]
WantedBy=multi-user.target
EOF
  INFO "\nusage: ${SRV_NAME}.service"
  BOLD "cp -a ${SRV_NAME}.service /usr/lib/systemd/system/"
  BOLD "systemctl enable ${SRV_NAME}"
  BOLD "systemctl start ${SRV_NAME}"
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
            -s) SRV_NAME="$2"; shift ;;
            -h | --help) show_help ;;
            *) ERRO "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done
}


main() {
    init_args "$@"
    build_control
    build_service
}

main "$@" || exit 1