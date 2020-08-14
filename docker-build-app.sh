#!/bin/bash
source ./setup_vars.sh
docker image build -t "example/app"  -f app/Dockerfile app/
