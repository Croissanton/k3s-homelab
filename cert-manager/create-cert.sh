#!/bin/bash

export EMAIL="$1"
export DOMAIN="$2"
export BACKEND_SERVICE="$3"
export BACKEND_PORT="$4"

envsubst < cert.yaml.template | kubectl apply -n cert-manager -f -
