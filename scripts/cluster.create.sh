#!/usr/bin/env bash
export base_url=$(git rev-parse --show-toplevel)
export app_name="assign-mt"
export env="dev"
export tenant="gcp"
export chdir="${base_url}/terraform/envs/${env}/${tenant}"

terraform -chdir="${chdir}" init -backend-config="backend.hcl"
terraform -chdir="${chdir}" apply

export outputs=$(terraform -chdir="${chdir}" output -json)

export project_id=$(echo $outputs | jq -r '.project_id.value')
export cluster_name=$(echo $outputs | jq -r '.cluster_details.value.name')
export cluster_location=$(echo $outputs | jq -r '.cluster_details.value.location')
