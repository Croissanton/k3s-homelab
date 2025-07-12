#!/bin/bash
ENV_FILE="../secrets/minecraft-secrets.env"
[ -f "$ENV_FILE" ] && export $(grep -v '^#' "$ENV_FILE" | xargs) || { echo "Env file $ENV_FILE not found!"; exit 1; }

[ -z "$MC_RCON_PASSWORD" ] && { echo "MC_RCON_PASSWORD not set"; exit 1; }

NAMESPACE="rcon-web-admin"
RELEASE="rcon-web-admin"
CHART="minecraft-server/rcon-web-admin"
WEB_USER="admin"
WEB_PASSWORD="$MC_RCON_PASSWORD"
RCON_HOST="mc-minecraft-rcon.minecraft.svc.cluster.local"
RCON_PORT=25575

kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" --create-namespace \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set rconWeb.username="$WEB_USER" \
  --set rconWeb.password="$WEB_PASSWORD" \
  --set "rconWeb.rconHost=$RCON_HOST" \
  --set rconWeb.rconPort="$RCON_PORT" \
  --set rconWeb.rconPassword="$MC_RCON_PASSWORD" 

echo "Deployment complete!"

