#!/usr/bin/env bash
export base_url=$(git rev-parse --show-toplevel)
export bucket_name="assign-mt-terraform-state"
export app_name="assign-mt"
export env="dev"
export tenant="gcp"

export chdir="${base_url}/terraform/envs/${env}/${tenant}"
export project_name="${app_name}-${env}-${tenant}"

terraform -chdir="${chdir}" init -backend-config="backend.hcl"
terraform -chdir="${chdir}" destroy
