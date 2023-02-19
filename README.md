# idrac6-console
Start the iDRAC6 virtual console on the DELL PowerEdge without the
need of Java Web Start or accessing it from the web interface.
This script assumes basic system tools are available.

## Requirements
- basename
- bash >= 4.0
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

Open a virtual console to the DELL server with idrac version 6,
such as PowerEdge R610 or R710.

Options:
    -?                            print this help message
    -h                            idrac host
    -u                            username
    -p                            password or path to a password file
                                    if not provide or left empty than it will
                                    attempt to load a password file (by default
                                    named "passwd") from $PWD, $HOME, or from
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
```
