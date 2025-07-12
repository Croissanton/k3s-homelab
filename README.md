# Minecraft Server Exposure via Traefik & Gateway API
This guide details a clean setup to expose a Minecraft server on port 25565 using Traefik v3 with Gateway API.

## 1. Disable the built-in Traefik add‑on in K3s
```bash
sudo mkdir -p /etc/rancher/k3s
cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
disable:
  - traefik
EOF
sudo systemctl restart k3s
````


## 2. Install Gateway API CRDs

```bash
# Core CRDs (Gateway, GatewayClass, HTTPRoute, etc.)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# Experimental CRDs (TCPRoute, UDPRoute, etc.)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml
```

Verify:

```bash
kubectl get crd | grep -E 'gatewayclasses|gateways|tcproutes'
```


## 3. Create Traefik namespace and prepare values

```bash
kubectl create namespace traefik
```

**`traefik-values.yaml`**:

```yaml
hostNetwork: true
dnsPolicy: ClusterFirstWithHostNet

providers:
  kubernetesGateway:
    enabled: true
    experimentalChannel: true

entryPoints:
  minecraft:
    address: ":25565"

service:
  enabled: false
```

## 4. Install Traefik v3 via Helm

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik --namespace traefik -f traefik-values.yaml
```


## 5. Set Minecraft service to ClusterIP

In your Minecraft `values.yaml`:

```yaml
serviceType: ClusterIP
servicePort: 25565
```

```bash
helm upgrade mc minecraft-server/minecraft --namespace minecraft -f values.yaml
```

## 6. Create GatewayClass & Gateway

**`traefik-gateway.yaml`**:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: traefik
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: tcp
      protocol: TCP
      port: 25565
      allowedRoutes:
        namespaces:
          from: All
```

```bash
kubectl apply -f traefik-gateway.yaml
```


## 7. Create TCPRoute to Minecraft

**`minecraft-ingressroute.yaml`**:

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: minecraft
  namespace: minecraft
spec:
  parentRefs:
    - name: traefik
      namespace: traefik
      sectionName: tcp
  rules:
    - backendRefs:
        - name: mc-minecraft
          port: 25565
```

```bash
kubectl apply -f minecraft-ingressroute.yaml
```


## 8. Open port 25565 on the firewall

```bash
sudo ufw allow 25565/tcp
```


## 9. Connect!

In your Minecraft client, use:

```
IP_OF_YOUR_SERVER:25565
```

Enjoy your Minecraft world, securely exposed via Traefik & Gateway API!
