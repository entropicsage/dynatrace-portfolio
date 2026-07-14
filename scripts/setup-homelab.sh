#!/bin/bash
# EasyTrade Observability Lab: Dynatrace Operator + applicationMonitoring DynaKube + nginx ingress with network exposure and mobile support
set -e
export PATH=~/.local/bin:$PATH

echo "=== 1. Ensure kind K8s cluster (dt-homelab) with network exposure config ==="
if ! kind get clusters | grep -q dt-homelab; then
  kind create cluster --name dt-homelab --config k8s/kind-config.yaml --wait 5m
else
  echo "Cluster dt-homelab already exists. (Delete with 'kind delete cluster --name dt-homelab' if you want a fresh one.)"
fi

echo "=== 2. Deploy EasyTrade microservices via official Helm ==="
helm install easytrade oci://europe-docker.pkg.dev/dynatrace-demoability/helm/easytrade \
  --create-namespace --namespace easytrade --kube-context kind-dt-homelab \
  || helm upgrade --install easytrade oci://europe-docker.pkg.dev/dynatrace-demoability/helm/easytrade \
     --namespace easytrade --kube-context kind-dt-homelab

echo "=== 3. Full monitoring hookup: Dynatrace Operator + DynaKube (applicationMonitoring mode) ==="
helm install dynatrace-operator dynatrace/dynatrace-operator --namespace dynatrace --create-namespace --kube-context kind-dt-homelab || true
# NOTE: Create dedicated token in DT UI with scopes "PaaS integration" + "Kubernetes monitoring"
# Then: kubectl create secret generic dynatrace --from-literal=apiToken=THE_TOKEN -n dynatrace --context kind-dt-homelab
kubectl apply -f k8s/dynakube.yaml --context kind-dt-homelab || true

echo "=== 4. Force pod restart for code module injection ==="
kubectl delete pods -n easytrade --all --context kind-dt-homelab || true
sleep 10

echo "=== 5. dtctl declarative portfolio (dashboards, etc.) ==="
dtctl apply -f dashboards/ --context my-env || echo "dtctl apply done (check tenant)"

echo "=== 6. Network exposure via Ingress (main UI on host port 8081) + mobile CSS ==="
# Enable snippet support in ingress controller (required for on-the-fly mobile CSS injection)
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --context kind-dt-homelab --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-snippet-annotations=true"}]' || true
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx --context kind-dt-homelab || true
sleep 15
kubectl apply -f k8s/easytrade-ingress.yaml --context kind-dt-homelab || true

echo "=== 7. Status ==="
kubectl get pods -n dynatrace --context kind-dt-homelab | head -5
kubectl get dynakube dynakube -n dynatrace --context kind-dt-homelab
kubectl get pods -n easytrade --context kind-dt-homelab | head -5
kubectl get ingress -n easytrade --context kind-dt-homelab
dtctl get dashboards -o json --context my-env | grep -i -E 'easytrade|Portfolio' || true

echo ""
echo "=== Access ==="
echo "EasyTrade UI (via Ingress): http://localhost:8081 or http://YOUR_WSL_IP:8081"
echo "Mobile: The ingress now injects responsive CSS for phones (scrollable grids, larger buttons). Use landscape or hard-refresh (Ctrl+Shift+R) on phone after controller restarts."
echo "For other devices on your home network, run the Windows portproxy + firewall commands from the README."
echo "Login example: demouser / demopass. Loadgen + problem-operator generate data for DT."
echo ""
echo "Done. Fix token in secret if DynaKube shows TokenError, then re-delete pods."
echo "Frontend/reverse proxy on easytrade-frontendreverseproxy:8080 (exposed via ingress on 8081)."