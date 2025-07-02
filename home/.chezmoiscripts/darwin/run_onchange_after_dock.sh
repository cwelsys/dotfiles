#!/bin/bash

set -eufo pipefail

trap 'killall Dock' EXIT

declare -a remove_labels=(
	Launchpad
	Safari
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
