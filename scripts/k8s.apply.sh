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

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

helm install -n cert-manager cert-manager jetstack/cert-manager --version v1.18.0 \
  --values "${base_dir}/helm/values/cert-manager.values.yml" \
  --create-namespace --wait --debug

kubectl apply -f "${base_dir}/k8s/certs"

helm install -n monitoring prometheus \
  prometheus-community/kube-prometheus-stack --version "74.0.0" \
  --values "${base_dir}/helm/values/kube-prometheus-stack.values.yml" \
  --set "grafana.adminUser=${grafana_username}" \
  --set "grafana.adminPassword=${grafana_password}" \
  --create-namespace --wait --debug

helm install -n services keycloak \
  bitnami/keycloak --version "24.7.4" \
  --set auth.adminUser="${keycloak_username}" \
  --set auth.adminPassword="${keycloak_password}" \
  --set postgresql.enabled=false \
  --set externalDatabase.host="${database_public_ip_address}" \
  --set externalDatabase.port=5432 \
  --set externalDatabase.database="postgres" \
  --set externalDatabase.password="${database_password}" \
  --set externalDatabase.user="${database_user}" \
  --values "${base_dir}/helm/values/keycloak.values.yml" \
  --create-namespace --wait --debug

helm install -n services ingress \
  ingress-nginx/ingress-nginx --version "4.12.3" \
  --values "${base_dir}/helm/values/ingress-nginx.values.yml" --wait --debug

helm install -n monitoring internal-ingress \
  ingress-nginx/ingress-nginx --version "4.12.3" \
  --values "${base_dir}/helm/values/internal-ingress-nginx.values.yml" --wait --debug

kubectl apply -f "${base_dir}/k8s/ingress"

if [[ -n "$KEYCLOAK_RESTRICTED_RANGE" ]]; then
  kubectl patch ingress keycloak -n services --type='merge' \
    -p='{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/whitelist-source-range":"'"${KEYCLOAK_RESTRICTED_RANGE}"'"}}}'
fi

if [[ -n "$GRAFANA_RESTRICTED_RANGE" ]]; then
  kubectl patch ingress grafana -n services --type='merge' \
    -p='{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/whitelist-source-range":"'"${GRAFANA_RESTRICTED_RANGE}"'"}}}'
fi

# Display passwords for the integrator
echo "==================================="
echo "LOGIN CREDENTIALS"
echo "==================================="
echo "Grafana:"
echo "  Username: ${grafana_username}"
echo "  Password: ${grafana_password}"
echo ""
echo "Keycloak:"
echo "  Username: ${keycloak_username}"
echo "  Password: ${keycloak_password}"
echo "==================================="
