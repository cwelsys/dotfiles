#!/bin/bash

set -eufo pipefail

if ! command -v dockutil &> /dev/null; then
    echo "dockutil not found, skipping dock configuration"
    exit 0
fi

trap 'killall Dock' EXIT

declare -a remove_labels=(
	Launchpad
	Maps
	Photos
	FaceTime
	Contacts
	Reminders
	Notes
	Freeform
	TV
	Music
	Keynote
	Numbers
	Pages
	"App Store"
)

for label in "${remove_labels[@]}"; do
	dockutil --no-restart --remove "${label}" || true
done
