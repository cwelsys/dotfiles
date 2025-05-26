#!/usr/bin/env bash

chown -R "$(whoami)" $GNUPGHOME
find $GNUPGHOME -type d -exec chmod 700 {} \;
find $GNUPGHOME -type f -exec chmod 600 {} \;
