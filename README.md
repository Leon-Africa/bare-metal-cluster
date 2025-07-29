## Production-Grade Kubernetes Cluster on Kind

This repository contains a production-grade example of a Kubernetes cluster setup on Kind with:
- FluxCD for GitOps-based continuous deployment
- Traefik as the ingress controller managed via Helm and Flux
- Cilium as the CNI for advanced networking and network policies
- Kustomize for declarative and reusable Kubernetes manifests
- Example workload deployment (Echo server) reachable via Traefik at /echo
- Secure networking enforced by Cilium and Kubernetes NetworkPolicies
- Full infrastructure and workloads managed declaratively in Git

This project serves as a reference implementation, designed to be a solid foundation to build production-ready Kubernetes environments.

### Requirements:
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [helm](https://helm.sh/docs/intro/install/)
- [cilium](https://github.com/cilium/cilium-cli)
- [flux](https://fluxcd.io/flux/cmd/)
- [hubble](https://docs.cilium.io/en/stable/observability/hubble/hubble-cli/)

### Usage
````
./create_cluster.sh
````
