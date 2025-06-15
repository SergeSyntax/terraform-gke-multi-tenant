#!/usr/bin/env bash
export base_url=$(git rev-parse --show-toplevel)
# echo $base_url

# gsutil mb gs://assign-management-terraform-state
export bucket_name="assign-management-terraform-state"
export app_name="assign-management"
export env="dev"
export tenant="gcp"
export billing_account="01EA26-70AB24-410CC4"

export chdir="${base_url}/terraform/envs/${env}/${tenant}"
export project_name="${app_name}-${env}-${tenant}"

terraform -chdir="${chdir}" init \
  -backend-config="bucket=${bucket_name}" \
  -backend-config="prefix=${env}/${tenant}"

terraform -chdir="${chdir}" destroy \
  --var="project_name=${project_name}" \
  --var="billing_account=${billing_account}"
