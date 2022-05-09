#!/usr/bin/env bash
#
# Copyright (c) 2021-2022 brian
#
# Short: https://git.io/csh-lego.sh
# File name: lego.sh
# Description: Install latest version lego
# System Required: GNU/Linux
# Version: 1.0

##############################################################
## Project Vars
# Name
PROJECT_NAME="lego.sh"
# Release link
# Version link
VERSION_URL="https://api.github.com/repos/go-acme/lego/releases/latest"
# Download archive name
DOWNLOAD_FILE=""
# Set Default GOPATH PATH
INSTALL_PATH="/usr/local/bin"

##############################################################
## Global Vars
ARCH=""
PLATFORM=""
DISTRIBUTION=""
PACKAGING=""
# Shell
USR_SHELL="bash"
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"
# root required
SUDO=""

# Common
set -o errexit
set -o errtrace
set -o pipefail

export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

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
## Detect
# Get OS arch
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        amd64) ARCH="amd64";;
        x86_64) ARCH="amd64";;
        i386) ARCH="386";;
        armv6l) ARCH="armv6l";;
        armv7l) ARCH="armv6l";;
        aarch64) ARCH="arm64";;
       *) ERRO "Unsupported architecture: ${ARCH}"; exit 1;;
    esac
    echo -e "ARCH     = ${ARCH}"
}

# Get OS version
detect_platform() {
    # check os name
    PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $PLATFORM in
        darwin) PLATFORM='darwin';;
        linux) PLATFORM='linux';;
        freebsd) PLATFORM='freebsd';;
        *) ERRO "Unsupported platform: ${PLATFORM}"; exit 1;;
    esac
    echo -e "PLATFORM = ${PLATFORM}"
}

detect_distribution() {
    # check os release
    DISTRIBUTION=""
    if [[ -f /etc/redhat-release ]]; then
        DISTRIBUTION="centos"
        PACKAGING="yum"
    elif [ -f /etc/issue  ]; then
        if grep -Eqi "debian|raspbian" /etc/issue; then
            DISTRIBUTION="debian"
            PACKAGING="apt-get"
        elif grep -Eqi "ubuntu" /etc/issue; then
            DISTRIBUTION="ubuntu"
            PACKAGING="apt-get"
        elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
            DISTRIBUTION="centos"
            PACKAGING="yum"
        fi
    elif [ -f /proc/version ]; then
        if grep -Eqi "debian|raspbian" /proc/version; then
            DISTRIBUTION="debian"
            PACKAGING="apt-get"
        elif grep -Eqi "ubuntu" /proc/version; then
            DISTRIBUTION="ubuntu"
            PACKAGING="apt-get"
        elif grep -Eqi "centos|red hat|redhat" /proc/version; then
            DISTRIBUTION="centos"
            PACKAGING="yum"
        fi
    elif which sw_vers >/dev/null 2>&1; then
        DISTRIBUTION=$(sw_vers -productName)
        PACKAGING="brew"
        SUDO=""
    else
        ERRO "Unsupported os distribution: ${DISTRIBUTION}"; exit 1;
    fi

    echo -e "DISTRIB  = ${DISTRIBUTION}"
}

detect_shell() {
    USR_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
    echo -e "Current shell is ${USR_SHELL}"
}

# detect env
detect_environment() {
    INFO "Detect system environment ..."
    detect_arch
    detect_platform
    detect_distribution
    detect_shell
}

##############################################################
## Depend
# install depend list
install_depend() {
    if [[ $(id -u) -ne 0 ]]; then
        SUDO="sudo"
    fi

    depend_list=""
    if ! which curl >/dev/null 2>&1; then
        depend_list="${depend_list} curl"
    fi

    if ! which jq >/dev/null 2>&1; then
         depend_list="${depend_list} jq"
    fi

    if [ -n "$depend_list" ]; then
        installed=$(${SUDO} ${PACKAGING} install -y ${depend_list})
        echo  -e "Installing: \n${installed}"
   fi
}

# download archive
download_archive() {
    src="$1"
    dst="$2"

    INFO "Downloading $src to $dst"

    if which curl >/dev/null 2>&1; then
        curl -L -o "$dst" "$src"
    elif which wget >/dev/null 2>&1; then
        wget "$src" -O "$dst"
    else
        ERRO "No curl or wget found, how to download the archive?"
        exit 1
    fi
}

##############################################################
## Project Code

## Show help
show_help() {
  echo "usage: ./${PROJECT_NAME} [-h] [-d install_path]"
  echo '  -h, --help    :  Show help'
  echo ''
  echo '> bash <(curl -fsSL git.io/csh-lego.sh)'
  exit 0
}

# init install path
install_path() {
    if [ ! -d ${INSTALL_PATH} ]; then
        mkdir -p ${INSTALL_PATH}
    fi
    INFO "Install ${PROJECT_NAME} path: ${INSTALL_PATH}"
}

# install binary
install_binary() {
    INFO "\nInstalling ${PROJECT_NAME} ..."

    # fetch latest verion
    LATEST=$(curl -fsSL "${VERSION_URL}" )
    VERSION_TAG=$(echo "${LATEST}" | jq -r '.tag_name' | head -1)

    BOLD "Latest tag: ${VERSION_TAG}"
    DOWNLOAD_URL=$(echo "${LATEST}" | jq -r '.assets[].browser_download_url' |grep -v ".dgst" | grep "${PLATFORM}_${ARCH}")
    DOWNLOAD_FILE="${DOWNLOAD_URL##*/}"

    download_archive ${DOWNLOAD_URL} ${DOWNLOAD_FILE}

    BOLD "Tar to ${INSTALL_PATH}"
    tar xzf ${DOWNLOAD_FILE} -C ${INSTALL_PATH}
}

install_service() {
    INFO "\nInstalling service ..."

    SUCC "\n Finished install ${DOWNLOAD_FILE}"
    BOLD "You can use use the follow lines cmd to start"
    BOLD "> DNSPOD_API_KEY=xxxxxx lego --email myemail@example.com --dns dnspod --domains=*.example.com --domains=my.example.org --key-type=rsa4096 --accept-tos --pem run "
}

# init args
init_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h | --help) show_help ;;
            *) ERRO "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done
}


main() {

    init_args "$@"

    detect_environment

    install_depend
    install_path

    install_binary
    install_service
}

main "$@" || exit 1
