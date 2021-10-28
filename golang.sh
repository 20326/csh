#!/usr/bin/env bash
#
# Copyright (c) 2021-2022 brian
#
# Short: https://git.io/csh-golang.sh
# File name: golang.sh
# Description: Install latest version golang
# System Required: GNU/Linux
# Version: 1.0

##############################################################
## Project Vars
# Name
PROJECT_NAME="golang.sh"
# Release link
RELEASE_URL="https://golang.org/dl/"
# Version link
VERSION_URL="${RELEASE_URL}?mode=json"
# Download archive name
DOWNLOAD_FILE=""
# Set Default GOPATH PATH
INSTALL_PATH="/usr/local"
INSTALL_AUTO="n"

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

detect_network() {
    country_code=$(curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}')
    if [ "$country_code" = "CN" ]; then
        RELEASE_URL="https://mirrors.ustc.edu.cn/golang/"
        VERSION_URL="https://golang.google.cn/dl/?mode=json"
        WARN "Can't download from origin, change to: ${RELEASE_URL}"
    fi
}

# detect env
detect_environment() {
    INFO "Detect system environment ..."
    detect_arch
    detect_platform
    detect_distribution
    detect_shell
    detect_network
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
CUSTOM_VERSION=""

## Show help
show_help() {
  echo "usage: ./${PROJECT_NAME} [-h] [-v version] [-d gopath] [-a]"
  echo '  -d            : set go path (default: %s/go)'
  echo '  -v            : set go version (default: latest version)'
  echo '  -a, --auto    : auto select latest or custom'
  echo '  -h, --help    :  Show help'
  echo ''
  echo '> bash <(curl -fsSL git.io/csh-golang.sh)'
  exit 0
}

# init install path
install_path() {
    if [ ! -d ${INSTALL_PATH} ]; then
        mkdir -p ${INSTALL_PATH}
    fi
    INFO "Install ${PROJECT_NAME} path: ${INSTALL_PATH}"
}

# Pick latest version
pick_version() {
    INFO "Pick version for ${PROJECT_NAME}, custom version: ${CUSTOM_VERSION} ..."

    # fetch latest verion
    LATEST=$(curl -fsSL "${VERSION_URL}")

    OLD_VERSION="none"
    NEW_VERSION=$(echo "${LATEST}" | jq -r '.[0] .version')
    OPT_VERSION=$(echo "${LATEST}" | jq -r '.[1] .version')

    # check installed version
    if which go >/dev/null 2>&1; then
        OLD_VERSION="$(go version | awk '{print $3}')"
        BOLD "Current version: ${OLD_VERSION}"
    fi

    if [ "$OLD_VERSION" = "${NEW_VERSION}" ]; then
        INFO "You have installed this version: ${OLD_VERSION}";
    fi

    BOLD "Latest  version: ${NEW_VERSION}"

    # select version
    INFO "------ Select install version ------"
    echo -e "1) ${NEW_VERSION}"
    echo -e "2) ${OPT_VERSION}"
    if [ -n "$CUSTOM_VERSION" ]; then
        echo -e "3) go${CUSTOM_VERSION} [Custom]"
    fi
    echo -e "0) Exit"

    # auto select
    if [[ ${INSTALL_AUTO} = "y" ]]; then
        if [ -n "$CUSTOM_VERSION" ]; then
            menu_num=3
        else
            menu_num=1
        fi
        INFO "Auto select: ${menu_num}"
    else
        echo && read -n1 -p "Please select: " menu_num
    fi

    # check select
    case $menu_num in
    1 | 2)
        menu_num=$((menu_num-1))
        DOWNLOAD_FILE=$(echo "${LATEST}" | jq -r ".[${menu_num}] .files[] | select(.arch == \"${ARCH}\" and .os ==  \"${PLATFORM}\" and .kind == \"archive\") | .filename")
        install_binary
        ;;
    3)
        DOWNLOAD_FILE="go${CUSTOM_VERSION}.${PLATFORM}-${ARCH}.tar.gz"
        install_binary
        ;;
    0)
        exit 1
        ;;
    *)
        echo && read -n1 -p "Please select: " menu_num
        ;;
    esac
}

# install binary
install_binary() {
    INFO "\nInstalling ${PROJECT_NAME} ..."
    if [[ -f ${DOWNLOAD_FILE} ]] ; then
        echo -e "the archive has been downloaded. ${DOWNLOAD_FILE}"
    else
        download_archive "${RELEASE_URL}${DOWNLOAD_FILE}" ${DOWNLOAD_FILE}
    fi

    rm -rf ${INSTALL_PATH}/go && tar xzf ${DOWNLOAD_FILE} -C ${INSTALL_PATH}
}

# config
install_config() {

    INFO "Configure ${PROJECT_NAME} ..."
    export_data="export PATH=\$PATH:${INSTALL_PATH}/go/bin"
    export_file=""

    if [[ "$USR_SHELL" = "zsh"  ]]; then
        export_file=${ZSHRC}
    else
        export_data="export PATH=\$PATH:${INSTALL_PATH}/go/bin"
        export_file=${BASHRC}
    fi

    if grep "PATH:${INSTALL_PATH}/go/bin"  "${export_file}" ; then
        BOLD "You has the following lines to ${export_file}"
        BOLD "    ${export_data} >> ${export_file}"
   else
        echo -e "${export_data}" >> "${export_file}"
        INFO "You must use:  source ${export_file}"
        INFO "Finished install ${DOWNLOAD_FILE}"
        $SHELL ${export_file}
    fi
}

# install result
install_result() {
    if which go >/dev/null 2>&1; then
        SUCC "Current version : $(go version) !"
    fi
}

# init args
init_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -v) CUSTOM_VERSION="$2"; shift ;;
            -d) INSTALL_PATH="$2"; shift ;;
            -a | --auto) INSTALL_AUTO="y" ;;
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

    pick_version

    install_config
    install_result
}

main "$@" || exit 1
