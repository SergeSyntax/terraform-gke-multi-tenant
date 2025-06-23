#!/usr/bin/env bash
export base_dir=$(git rev-parse --show-toplevel)

export env="${env:-"dev"}"
export tenant="${tenant:-"gcp"}"

export chdir="${base_dir}/terraform/envs/${env}/${tenant}"

export outputs=$(terraform -chdir="${chdir}" output -json)

export project_id=$(echo $outputs | jq -r '.project_id.value')
export database_password=$(echo $outputs | jq -r '.database_details.value.database_password')
export database_public_ip_address=$(echo $outputs | jq -r '.database_details.value.database_public_ip_address')
export database_user=$(echo $outputs | jq -r '.database_details.value.database_user')
export cluster_location=$(echo $outputs | jq -r '.cluster_location.value')

export grafana_username="${grafana_username:-"admin"}"
export grafana_password=$(echo $outputs | jq -r '.grafana_password.value')

export keycloak_username="${keycloak_username:-"admin"}"
export keycloak_password=$(echo $outputs | jq -r '.keycloak_password.value')

export argocd_username="${argocd_username:-"admin"}"
export argocd_password=$(echo $outputs | jq -r '.argocd_password.value')

KEYCLOAK_RANGES="${KEYCLOAK_RESTRICTED_RANGE:-}"
GRAFANA_RANGES="${GRAFANA_RESTRICTED_RANGE:-}"
ARGOCD_RANGES="${ARGOCD_RESTRICTED_RANGE:-}"

helm upgrade ingress-setup "${base_dir}/helm/charts/ingress-setup" \
  --set ingress.keycloak.allowedSourceRanges="${KEYCLOAK_RANGES}" \
  --set ingress.grafana.allowedSourceRanges="${GRAFANA_RANGES}" \
  --set ingress.argocd.allowedSourceRanges="${ARGOCD_RANGES}"

argocd_external_ip=$(kubectl get svc/argocd-ingress-ingress-nginx-controller -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
monitoring_external_ip=$(kubectl get svc/internal-ingress-ingress-nginx-controller -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
services_external_ip=$(kubectl get svc/ingress-ingress-nginx-controller -n services -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "==================================="
echo "SERVICE ACCESS INFORMATION"
echo "==================================="
echo "Grafana:"
echo "  Username: ${grafana_username}"
echo "  Password: ${grafana_password}"
echo "  External IP: ${monitoring_external_ip}"
echo ""
echo "Keycloak:"
echo "  Username: ${keycloak_username}"
echo "  Password: ${keycloak_password}"
echo "  External IP: ${services_external_ip}"
echo ""
echo "ArgoCD:"
echo "  Username: ${argocd_username}"
echo "  Password: ${argocd_password}"
echo "  External IP: ${argocd_external_ip}"
echo "==================================="
