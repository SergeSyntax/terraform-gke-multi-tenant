#!/usr/bin/env bash
export base_url=$(git rev-parse --show-toplevel)
# echo $base_url

# gsutil mb gs://assign-management-terraform-state
export bucket_name="${bucket_name:-"assign-management-terraform-state"}"
export app_name="assign-management"
export env="dev"
export tenant="gcp"

export chdir="${base_url}/terraform/envs/${env}/${tenant}"
export project_name="${app_name}-${env}-${tenant}"

terraform -chdir="${chdir}" init \
  -backend-config="backend.hcl"

terraform -chdir="${chdir}" apply

export outputs=$(terraform -chdir="${chdir}" output -json)

export project_id=$(echo $outputs | jq -r '.project_id.value')
export cluster_name=$(echo $outputs | jq -r '.cluster_details.value.name')
export cluster_location=$(echo $outputs | jq -r '.cluster_details.value.location')

echo "# Run the following command *after* the cluster is successfully created:"
echo gcloud container clusters get-credentials "${cluster_name}" --location="${cluster_location}" --project="${project_id}"
