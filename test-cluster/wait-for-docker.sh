#!/usr/bin/env sh
set -eu

if ! command -v docker >/dev/null 2>&1; then
    echo "docker command not found; provisioning failed before Docker was installed" >&2
    exit 1
fi

attempts=0
until docker info >/dev/null 2>&1
do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 60 ]; then
        echo "docker did not become ready within 60 seconds" >&2
        exit 1
    fi
    echo "waiting for docker info"
    sleep 1
done
