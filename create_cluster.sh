#!/bin/bash
set -e

KIND_CLUSTER_NAME="kind"
KIND_CONFIG="cluster/kind-config.yaml"

if [ -f .env ]; then
  echo "Loading environment variables from .env"
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found! Required for FluxCD"
  exit 1
fi

if kind get clusters | grep -q "^${KIND_CLUSTER_NAME}$"; then
  echo "Kind cluster '${KIND_CLUSTER_NAME}' already exists. Deleting it first..."
  kind delete cluster --name "${KIND_CLUSTER_NAME}"
fi

kind create cluster --config "${KIND_CONFIG}"

echo -e "Installing Cilium"
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=kind-control-plane \
  --set k8sServicePort=6443 \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.enabled=true
kubectl -n kube-system rollout status daemonset/cilium --timeout=300s
echo -e "Cilium CNI installed and ready!"
sleep 10
cilium status --wait
# cilium connectivity test

echo -e "Installing FluxCD"
flux install

echo -e "Creating FluxCD Git authentication secret"
kubectl -n flux-system delete secret flux-system-git-auth --ignore-not-found
kubectl -n flux-system create secret generic flux-system-git-auth \
   --from-literal=username="$GIT_USERNAME" \
   --from-literal=password="$GIT_PASSWORD" \
   --type=kubernetes.io/basic-auth

echo -e "Bootstrapping FluxCD from Git"
 flux bootstrap git \
   --token-auth=true \
   --url="$GIT_URL" \
   --username="$GIT_USERNAME" \
   --password="$GIT_PASSWORD" \
   --branch="main" \
   --path="cluster"
echo -e "FluxCD bootstrapped! Cluster state is now managed from Git."

flux get kustomizations

echo "Starting Hubble port-forward on :4245..."
cilium hubble port-forward &

sleep 5

echo "Checking Hubble status..."
hubble status

echo "Showing recent Hubble flows..."
hubble observe --last 5

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n prod && kubectl wait --for=condition=ready pod -l app=echo-server -n prod
kubectl port-forward svc/traefik -n prod 8080:80 &
