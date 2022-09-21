#!/usr/bin/env bash

# Copyright (C) 2022 Uco Mesdag
# Description:  Open a virtual console to the DELL PowerEdge R610.

usage () {
  cat <<EOF
Usage:
    $(basename $0) [OPTIONS]

Open a virtual console to the DELL PowerEdge R610.

Options:
    -?                            print this help message
    -h                            idrac host
    -u                            username
    -p                            password or path to a password file
                                    if not provide or left empty than it will
                                    attempt to load a password file (by default
                                    named "passwd") from \$PWD, \$HOME, or from
                                    this scripts directory and else it will
                                    prompt you to enter a password
    -k                            use http instead of https

Requirements: Java installed

The following variables can also be set as environment variables:
  IDRAC_HOST, IDRAC_USER, IDRAC_PASSWD
EOF
}

SCRIPT_DIR="$( cd "$(dirname "$0")" &> /dev/null; pwd -P )"

while getopts "h:u:p:ki" OPTIONS; do
  case ${OPTIONS} in
    h) IDRAC_HOST=${OPTARG};;
    u) IDRAC_USER=${OPTARG};;
    p) IDRAC_PASSWD=${OPTARG};;
    k) PROTO=http;;
    i) INIT=true;;
    \?) usage && exit 0;;
  esac
done

if [ -z ${IDRAC_HOST+x} ]; then
  echo -e "Host not specified.\n"
  usage
  exit 1
fi

if [ -z ${IDRAC_PASSWD+x} ]; then
  IDRAC_PASSWD_FILE=passwd
else
  IDRAC_PASSWD_FILE=${IDRAC_PASSWD}
fi

if [ -f ${IDRAC_PASSWD_FILE} ]; then
  IDRAC_PASSWD=$(cat ${IDRAC_PASSWD_FILE} | xargs)
elif [ -f ${PWD}/${IDRAC_PASSWD_FILE} ]; then
  IDRAC_PASSWD=$(cat ${PWD}/${IDRAC_PASSWD_FILE} | xargs)
elif [ -f ${HOME}/${IDRAC_PASSWD_FILE} ]; then
  IDRAC_PASSWD=$(cat ${HOME}/${IDRAC_PASSWD_FILE} | xargs)
elif [ -f ${SCRIPT_DIR}/${IDRAC_PASSWD_FILE} ]; then
  IDRAC_PASSWD=$(cat ${SCRIPT_DIR}/${IDRAC_PASSWD_FILE} | xargs)
fi

if [ -z ${IDRAC_PASSWD+x} ]; then
  read -sp "Password for ${IDRAC_USER} on ${IDRAC_HOST}: " IDRAC_PASSWD
  echo
fi

if [ "$INIT" == "true" ] || [ ! -d ${SCRIPT_DIR}/bin ] || [ ! -d ${SCRIPT_DIR}/lib ] || [ ! -d ${SCRIPT_DIR}/conf ]; then
  ARCH=$(uname -m)
  case "$OSTYPE" in
    darwin*)  FILES=MACOS_${ARCH^^}_LIBS ;;
    linux*)   FILES=LINUX_${ARCH^^}_LIBS ;;
    msys*)    FILES=WINDOWS_${ARCH^^}_LIBS ;;
    cygwin*)  FILES=WINDOWS_${ARCH^^}_LIBS ;;
    *)        echo "Unsupported OS"; exit 1 ;;
  esac

  SOFTWARE_URL="${PROTO:-https}://${IDRAC_HOST}/software/"
  WINDOWS_X86_LIBS="avctKVMIOWin32.jar avctVMWin32.jar"
  WINDOWS_X86_64_LIBS="avctKVMIOWin64.jar avctVMWin64.jar"
  WINDOWS_AMD64_LIBS="avctKVMIOWin64.jar avctVMWin64.jar"
  LINUX_X86_LIBS="avctKVMIOLinux32.jar avctVMLinux32.jar"
  LINUX_I386_LIBS="avctKVMIOLinux32.jar avctVMLinux32.jar"
  LINUX_I586_LIBS="avctKVMIOLinux32.jar avctVMLinux32.jar"
  LINUX_I686_LIBs="avctKVMIOLinux32.jar avctVMLinux32.jar"
  LINUX_AMD64_LIBS="avctKVMIOLinux64.jar avctVMLinux64.jar"
  LINUX_X86_64_LIBS="avctKVMIOLinux64.jar avctVMLinux64.jar"
  MACOS_X86_64_LIBS="avctKVMIOMac64.jar avctVMMac64.jar"
  JAR="avctKVM.jar"

  if curl -sS ${SOFTWARE_URL} 2>&1 | grep -q "curl: (60)"; then
    echo -e "SSL certificate problem: self signed certificate.\n\nTry with the -k (insecure) option for HTTP instead of HTTPS."
    exit 1
  fi

  mkdir -p ${SCRIPT_DIR}/{bin,lib,conf}
  for FILE in ${!FILES}; do
    curl -s ${SOFTWARE_URL}${FILE} -o ${SCRIPT_DIR}/lib/${FILE}
    cd ${SCRIPT_DIR}/lib; jar -xvf ${FILE} >/dev/null; cd - >/dev/null
    rm -r ${SCRIPT_DIR}/lib/${FILE} ${SCRIPT_DIR}/lib/META-INF
  done

  curl -s ${SOFTWARE_URL}${JAR} -o ${SCRIPT_DIR}/bin/${JAR}

  cp ${JAVA_HOME}/conf/security/java.security ${SCRIPT_DIR}/conf/java.security
  sed -i 's/jdk.tls.disabledAlgorithms=\(.*\) RC4,\(.*\)/jdk.tls.disabledAlgorithms=\1\2/' ${SCRIPT_DIR}/conf/java.security
fi

echo "Connecting to ${IDRAC_HOST} as ${IDRAC_USER:-root}."
java -cp ${SCRIPT_DIR}/bin/avctKVM.jar \
  -Djava.library.path=${SCRIPT_DIR}/lib/ \
  -Djava.security.properties=${SCRIPT_DIR}/conf/java.security \
  com.avocent.idrac.kvm.Main \
  ip=${IDRAC_HOST} \
  kmport=5900 \
  vport=5900 \
  user=${IDRAC_USER:-root} \
  passwd=${IDRAC_PASSWD:-calvin} \
  apcp=1 \
  version=2 \
  vm=1 \
  vmprivilege=true \
  reconnect=1 \
  helpurl=${PROTO:-https}://${IDRAC_HOST}/help/contents.html
