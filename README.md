# idrac6-console
Start the iDAC6 virtual console on the DELL PowerEdge R610 without the need of Java Web Start or accessing it from the web interface.

## Requirements
Java installed

## Usage
```
Usage:
    console.sh [OPTIONS]

Open a virtual console to the DELL PowerEdge R610.

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
