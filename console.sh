#!/usr/bin/env bash

# Copyright (C) 2022-2023 Uco Mesdag
# Description:  Open a virtual console to the DELL PowerEdge R610.
# This script assumes basic system tools are available:
# bash >= 4.0, uname, xargs, basename, dirname, readlink

# shellcheck disable=SC2034

usage () {
  cat <<EOF
Usage:
    ./$(basename "$0") [OPTIONS]

    If Java 7 is not the default java on your system, use this command instead:

    JAVA_HOME="/path/to/java7" ./$(basename "$0") [OPTIONS]

    The correct JAVA_HOME directory is where bin/java lives.

Open a virtual console to the DELL server with idrac version 6,
such as PowerEdge R610 or R710.

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

Requirements:     Java installed

Default behavior: If no password is found it will default to the default
                  root:calvin login.

                  On arm64 it will default to x86_64 and try to download the
                  x86_64 libraries.

The following variables can also be set as environment variables:
  IDRAC_HOST, IDRAC_USER, IDRAC_PASSWD
EOF
}

echoerr () { echo "$@" 1>&2; }

die () {
  MSG="$1"
  shift
  CODE="$1"
  shift
  if [ -z "${CODE}" ]; then
    CODE=1
  fi
  echoerr "${MSG}"
  exit "${CODE}"
}

SCRIPT_DIR="$( cd "$(dirname "$0")" &> /dev/null || die "Can't cd to $(dirname "$0")"; pwd -P )"

while getopts "h:u:p:ki" OPTIONS; do
  case ${OPTIONS} in
    h) IDRAC_HOST=${OPTARG};;
    u) IDRAC_USER=${OPTARG};;
    p) IDRAC_PASSWD=${OPTARG};;
    k) PROTO=http;;
    i) INIT=true;;
    \?) die "$(usage)" 0 ;;
  esac
done

if [ -z "${JAVA_HOME}" ]; then
  JAVA_PATH="$(which java)"
  if [ -h "${JAVA_PATH}" ]; then
    JAVA_PATH="$(readlink -e "${JAVA_PATH}" || die "Cannot resolve java symlink")"
  fi
  if [ -x "${JAVA_PATH}" ]; then
    JAVA_BIN_PATH="$(dirname "${JAVA_PATH}")"
    JAVA_HOME="$(dirname "${JAVA_BIN_PATH}")"
  else
    die "No java executable found on PATH"
  fi
fi

if [ -z "${IDRAC_HOST+x}" ]; then
  echo -e "Host not specified.\n"
  die "$(usage)"
fi

if [ -z ${IDRAC_PASSWD+x} ]; then
  IDRAC_PASSWD_FILE=passwd
else
  IDRAC_PASSWD_FILE=${IDRAC_PASSWD}
fi

if [ -f "${IDRAC_PASSWD_FILE}" ]; then
  IDRAC_PASSWD="$(xargs < "${IDRAC_PASSWD_FILE}")"
elif [ -f "${PWD}/${IDRAC_PASSWD_FILE}" ]; then
  IDRAC_PASSWD="$(xargs < "${PWD}/${IDRAC_PASSWD_FILE}")"
elif [ -f "${HOME}/${IDRAC_PASSWD_FILE}" ]; then
  IDRAC_PASSWD="$(xargs < "${HOME}/${IDRAC_PASSWD_FILE}")"
elif [ -f "${SCRIPT_DIR}/${IDRAC_PASSWD_FILE}" ]; then
  IDRAC_PASSWD="$(xargs < "${SCRIPT_DIR}/${IDRAC_PASSWD_FILE}")"
fi

if [ -z ${IDRAC_PASSWD+x} ]; then
  read -rsp "Password for ${IDRAC_USER} on ${IDRAC_HOST}: " IDRAC_PASSWD
  echo
fi

if [ "$INIT" == "true" ] || [ ! -d "${SCRIPT_DIR}/bin" ] || [ ! -d "${SCRIPT_DIR}/lib" ] || [ ! -d "${SCRIPT_DIR}/conf" ]; then
  ARCH=$(uname -m)
  [ "$ARCH" == "arm64" ] && ARCH="x86_64"
  case "$OSTYPE" in
    darwin*)  FILES=MACOS_${ARCH^^}_LIBS ;;
    linux*)   FILES=LINUX_${ARCH^^}_LIBS ;;
    msys*)    FILES=WINDOWS_${ARCH^^}_LIBS ;;
    cygwin*)  FILES=WINDOWS_${ARCH^^}_LIBS ;;
    *)        die "Unsupported OS" ;;
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

  if curl -sS "${SOFTWARE_URL}" 2>&1 | grep -q "curl: (60)"; then
    MSG="$(echo -e "SSL certificate problem: self signed certificate.\n\n")"
    MSG="${MSG}Try with the -k (insecure) option for HTTP instead of HTTPS."
    die "${MSG}"
  fi

  mkdir -p "${SCRIPT_DIR}"/{bin,lib,conf}
  for FILE in ${!FILES}; do
    curl -s "${SOFTWARE_URL}${FILE}" -o "${SCRIPT_DIR}/lib/${FILE}"
    cd "${SCRIPT_DIR:?}/lib" || die "Can't cd to ${SCRIPT_DIR:?}/lib"; jar -xvf "${FILE}" >/dev/null; cd - >/dev/null || die "Can't cd to -"
    rm -r "${SCRIPT_DIR:?}/lib/${FILE}" "${SCRIPT_DIR}/lib/META-INF"
  done

  curl -s "${SOFTWARE_URL}${JAR}" -o "${SCRIPT_DIR}/bin/${JAR}"

  cp "${JAVA_HOME}/conf/security/java.security" "${SCRIPT_DIR}/conf/java.security"
  sed -i 's/jdk.tls.disabledAlgorithms=\(.*\) RC4,\(.*\)/jdk.tls.disabledAlgorithms=\1\2/' "${SCRIPT_DIR}/conf/java.security"
fi

echo "Connecting to ${IDRAC_HOST} as ${IDRAC_USER:-root}."
if [ -x "$(which screen)" ]; then
  SCREEN_CMD="screen -d -m -S idrac6console "
fi
${SCREEN_CMD:-} "${JAVA_HOME}/bin/java" -cp "${SCRIPT_DIR}/bin/avctKVM.jar" \
  -Djava.library.path="${SCRIPT_DIR}/lib/" \
  -Djava.security.properties="${SCRIPT_DIR}/conf/java.security" \
  com.avocent.idrac.kvm.Main \
  ip="${IDRAC_HOST}" \
  kmport=5900 \
  vport=5900 \
  user="${IDRAC_USER:-root}" \
  passwd="${IDRAC_PASSWD:-calvin}" \
  apcp=1 \
  version=2 \
  vm=1 \
  vmprivilege=true \
  reconnect=1 \
  helpurl="${PROTO:-https}://${IDRAC_HOST}/help/contents.html"
