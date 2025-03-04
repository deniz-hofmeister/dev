#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd $SCRIPT_DIR/..

echo 'docker build . -t hofmeister.dev/dev:latest -f test/Dockerfile'
docker build . -t hofmeister.dev/dev:latest -f test/Dockerfile
