#!/usr/bin/env bash

podman=`command -v podman`

if [ -z "$podman" ]; then
  echo "podman needs to be in PATH for this script to work."
  exit 1
fi
