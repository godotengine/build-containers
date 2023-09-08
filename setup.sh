#!/usr/bin/env bash

set -e

podman=`which podman || true`

if [ -z "$podman" ]; then
  echo "podman needs to be in PATH for this script to work."
  exit 1
fi
