#!/bin/sh
exec xdg-open "$(realpath "$(wine winepath -u "${1%\"}")")"
