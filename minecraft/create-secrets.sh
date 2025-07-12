#!/bin/bash

ENV_FILE="../secrets/minecraft-secrets.env"

# Load .env variables if file exists
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Env file $ENV_FILE not found!"
  exit 1
fi

if [ -z "$MC_RCON_PASSWORD" ]; then
  echo "MC_RCON_PASSWORD not set. Add it to your .env file."
  exit 1
fi

kubectl create secret generic mc-minecraft-rcon \
  --from-literal=rcon-password="$MC_RCON_PASSWORD" \
  -n minecraft \
  --dry-run=client -o yaml | kubectl apply -f -
