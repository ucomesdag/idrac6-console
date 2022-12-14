# idrac6-console
Start the iDRAC6 virtual console on the DELL PowerEdge without the
need of Java Web Start or accessing it from the web interface.
This script assumes basic system tools are available.

## Requirements
- basename
- bash
- dirname
- java 7
- readlink
- uname
- xargs

## Usage
```
Usage:
    ./console.sh [OPTIONS]

    If Java 7 is not the default java on your system, use this command instead:

    JAVA_HOME="/path/to/java7" ./console.sh [OPTIONS]

    The correct JAVA_HOME directory is where bin/java lives.

Open a virtual console to the DELL server with iDRAC version 6,
such as PowerEdge R610 or R710.

Options:
    -?                              print this help message
    -h                              idrac host
    -u                              username
    -p                              password or path to a password file
    -k                              use http instead of https

Requirements: Java installed

The following variables can also be set as environment variables:
  IDRAC_HOST, IDRAC_USER, IDRAC_PASSWD
```
