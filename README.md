# idrac6-console
Start the iDAC6 virtual console on the DELL PowerEdge R610 without the need of Java Web Start or accessing it from the web interface.

## Requirements
Java installed

## Usage
```
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

Default behavior: If no password or password file is given, then it will try to
      load a file named 'passwd' from the current directory ($PWD), your home
      ($HOME) and else from this scripts directory.

      If no password is found it will default to the default root:calvin login.

The following variables can also be set as environment variables:
  IDRAC_HOST, IDRAC_USER, IDRAC_PASSWD
```
