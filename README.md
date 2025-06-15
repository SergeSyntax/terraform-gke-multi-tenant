# Multi-Tenant DevOps Infrastructure Project

This project implements a multi-tenant, multi-environment Terraform structure for provisioning GKE clusters, deploying monitoring stacks, and managing secure 3-tier applications following DevOps best practices.

## 📋 Prerequisites

### System Requirements

- **Operating System**: Ubuntu 24.04 (tested on desktop/bastion host)
- **Hardware**: Minimum 4GB RAM, 20GB free disk space
- **Network**: Internet connectivity for downloading dependencies and accessing GCP

### Required Tools

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Google Cloud Cli](https://cloud.google.com/sdk/docs/install-sdk)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux)
- [helm](https://helm.sh/docs/intro/install/)
- Apt packages:

```sh
sudo apt install -y git jq
```

## 🚀 Quick Start Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/SergeSyntax/terraform-gke-multi-tenant
cd terraform-gke-multi-tenant
```

### Step 2: Google Cloud Authentication

```bash
gcloud init
```

### Step 3: Create a bucket to use

```bash
export BUCKET_NAME="${BUCKET_NAME:-"assign-management-terraform-state"}"
gsutil mb "gs://${BUCKET_NAME}"
```

### Step 4: Enable plugins

```bash
gcloud components install gke-gcloud-auth-plugin
```

### Step 5: Configure Environment Variables

#### For Development Environment (Currently Implemented):

```bash
# Copy and edit the development environment configuration
cp terraform/envs/dev/gcp/terraform.tfvars.example terraform/envs/dev/gcp/terraform.tfvars

# Edit the variables file with your specific values
vim terraform/envs/dev/gcp/terraform.tfvars
vim terraform/envs/dev/gcp/backend.hcl
```

#### For Other Environments (Structure Available):

The project structure supports multiple environments and tenants, but currently only the **development environment** is fully implemented:

**Available Structure:**

- `terraform/envs/dev/gcp/` - **✅ Implemented** (Ready to use)
- `terraform/envs/dev/aws/` - **📁 Structure only** (Not implemented)
- `terraform/envs/staging/gcp/` - **📁 Structure only** (Not implemented)
- `terraform/envs/staging/aws/` - **📁 Structure only** (Not implemented)
- `terraform/envs/prod/tenant-name/` - **📁 Structure only** (Not implemented)
- `terraform/envs/prod/tenant-another-name/` - **📁 Structure only** (Not implemented)

**To implement other environments:** Copy the dev/gcp configuration and modify according to your needs:

```bash
# Example: Setting up staging environment
mkdir -p terraform/envs/staging/gcp
cp -r terraform/envs/dev/gcp/* terraform/envs/staging/gcp/
# Then modify terraform/envs/staging/gcp/terraform.tfvars for staging-specific values

# Example: Setting up production tenant
mkdir -p terraform/envs/prod/tenant-name
cp -r terraform/envs/dev/gcp/* terraform/envs/prod/tenant-name/
# Then modify terraform/envs/prod/tenant-name/terraform.tfvars for production values
```

### Step 6: Deploy Infrastructure Using Scripts

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Export the bucket name
export BUCKET_NAME="${BUCKET_NAME:-"assign-management-terraform-state"}"

# Create GKE cluster (this will run terraform automatically)
./scripts/cluster.create.sh
```

**⚠️ CRITICAL:** After the cluster is created, you MUST run the gcloud command that the script displays to configure kubectl.

**If you missed the output or exited the terminal**, you can get and run the command again:

```bash
# Navigate to the terraform directory
cd terraform/envs/dev/gcp

# Get the cluster information from terraform outputs
project_id=$(terraform output -raw project_id)
cluster_name=$(terraform output -raw cluster_details | jq -r '.name')
cluster_location=$(terraform output -raw cluster_details | jq -r '.location')

# RUN THIS COMMAND to configure kubectl
gcloud container clusters get-credentials "${cluster_name}" --location="${cluster_location}" --project="${project_id}"
```

### Step 7: Deploy Application and Software Provisioning

**Prerequisites:** Make sure kubectl is configured (Step 6) before running this step.

```bash
# Verify kubectl context is correctly set
kubectl config current-context
kubectl get nodes

# Make k8s script executable
chmod +x scripts/k8s.apply.sh

# Deploy all Helm charts and Kubernetes manifests
./scripts/k8s.apply.sh
```

**Note:** If IP whitelisting is required for Grafana and Keycloak access, set these variables before running the script:

```bash
# Set IP ranges for service access restrictions
export KEYCLOAK_RESTRICTED_RANGE="192.115.85.127/32"
export GRAFANA_RESTRICTED_RANGE="192.115.85.127/32"

# Or use your current IP automatically
export MY_IP=$(curl -s ifconfig.me)
export KEYCLOAK_RESTRICTED_RANGE="${MY_IP}/32"
export GRAFANA_RESTRICTED_RANGE="${MY_IP}/32"

# Then run the script
./scripts/k8s.apply.sh
```

This script will deploy:

- **cert-manager** with custom values
- **ingress-nginx** (both external and internal) with custom configurations
- **kube-prometheus-stack** (Prometheus + Grafana) with monitoring values
- **keycloak** for authentication

### Step 8: Verification

```bash
# Verify GKE cluster and get service IPs
kubectl get nodes
kubectl get svc -A
```

## 🧹 Cleanup

### Destroy Infrastructure Using Scripts

```bash
# Use the automated destruction script
./scripts/cluster.destroy.sh
```

### Manual Terraform Destruction (Development Environment)

```bash
# Navigate to the development environment directory
cd terraform/envs/dev/gcp

# Destroy all resources
terraform destroy
```

**⚠️ Warning**: This will permanently delete all resources. Make sure you have backups if needed.

## 📁 Project Structure

```
.
├── ansible/                              # Ansible playbooks (future automation)
├── helm/
│   ├── charts/                          # Custom Helm charts
│   └── values/                          # Helm values files
│       ├── cert-manager.values.yml      # TLS certificate management
│       ├── ingress-nginx.values.yml     # External ingress controller
│       ├── internal-ingress-nginx.values.yml  # Internal ingress controller
│       ├── keycloak.values.yml          # Authentication service
│       └── kube-prometheus-stack.values.yml   # Monitoring stack
├── k8s/
│   ├── certs/
│   │   └── selfsgined.cluster-issuer.yml    # Self-signed certificate issuer
│   ├── ingress/
│   │   ├── grafana.ingress.yml          # Grafana ingress configuration
│   │   └── keycloak.ingress.yml         # Keycloak ingress configuration
│   └── monitoring.namespace.yml         # Monitoring namespace definition
├── scripts/
│   ├── k8s.apply.sh                     # Deploy all Helm charts and Kubernetes manifests
│   ├── cluster.create.sh                # Create GKE cluster with Terraform
│   └── cluster.destroy.sh               # Destroy infrastructure
├── terraform/
│   ├── envs/                            # Environment-specific configurations
│   │   ├── dev/                         # Development environment
│   │   │   ├── aws/                     # AWS development setup
│   │   │   └── gcp/                     # GCP development setup
│   │   │       ├── backend.hcl          # Terraform backend configuration
│   │   │       ├── main.tf              # Main Terraform configuration
│   │   │       ├── outputs.tf           # Output definitions
│   │   │       ├── providers.tf         # Provider configurations
│   │   │       ├── terraform.tfvars     # Environment variables
│   │   │       ├── terraform.tfvars.example  # Example configuration
│   │   │       └── variables.tf         # Variable definitions
│   │   ├── prod/                        # Production environment (multi-tenant)
│   │   │   ├── tenant-another-name/     # Second production tenant
│   │   │   └── tenant-name/             # First production tenant
│   │   └── staging/                     # Staging environment
│   │       ├── aws/                     # AWS staging setup
│   │       └── gcp/                     # GCP staging setup
│   ├── modules/                         # Reusable Terraform modules
│   │   ├── aws/                         # AWS-specific modules
│   │   │   ├── cluster/                 # EKS cluster module
│   │   │   └── network/                 # AWS networking module
│   │   └── gcp/                         # GCP-specific modules
│   │       ├── cluster/                 # GKE cluster module
│   │       ├── foundation/              # Basic GCP setup (projects, APIs)
│   │       ├── network/                 # VPC and networking
│   │       └── postgresql/              # Cloud SQL PostgreSQL
└── README.md                            # This documentation
```

## 🏗️ Architecture Overview

### Multi-Tenant Structure

The project is designed to support multiple environments and tenants:

- **Development**: ✅ **Fully Implemented** - Single tenant for testing and development (`terraform/envs/dev/gcp/`)
- **Staging**: 📁 **Structure Available** - Environment for pre-production testing (`terraform/envs/staging/`)
- **Production**: 📁 **Structure Available** - Multi-tenant setup supporting multiple organizations
  - `terraform/envs/prod/tenant-name/` - Primary production tenant structure
  - `terraform/envs/prod/tenant-another-name/` - Secondary production tenant structure

### Implementation Status

| Environment              | Cloud Provider | Status       | Description                                      |
| ------------------------ | -------------- | ------------ | ------------------------------------------------ |
| **dev/gcp**              | Google Cloud   | ✅ **Ready** | Fully implemented with modules and configuration |
| dev/aws                  | AWS            | 📁 Structure | Folder structure only, needs implementation      |
| staging/gcp              | Google Cloud   | 📁 Structure | Copy from dev/gcp and modify                     |
| staging/aws              | AWS            | 📁 Structure | Copy from dev/aws and modify                     |
| prod/tenant-name         | Multi-Cloud    | 📁 Structure | Copy from dev and customize for production       |
| prod/tenant-another-name | Multi-Cloud    | 📁 Structure | Copy from dev and customize for production       |

### Available Terraform Modules

Currently implemented for GCP:

- **cluster/** - ✅ GKE cluster module
- **foundation/** - ✅ Basic GCP setup (projects, APIs)
- **network/** - ✅ VPC and networking
- **postgresql/** - ✅ Cloud SQL PostgreSQL

AWS modules (structure only):

- **cluster/** - 📁 EKS cluster module (not implemented)
- **network/** - 📁 AWS networking module (not implemented)

### Infrastructure Components

- **GKE Clusters**: Managed Kubernetes clusters per environment/tenant
- **Networking**: Custom VPC with proper security groups and firewall rules
- **Database**: Cloud SQL PostgreSQL for persistent data
- **Monitoring**: Prometheus + Grafana stack with custom dashboards
- **Security**: TLS certificates, IP restrictions, and authentication via Keycloak
- **Ingress**: NGINX ingress controllers (external and internal routing)

## 📝 Notes

- This setup is designed for demonstration purposes
- For production use, consider implementing proper secret management
- Review security configurations before deploying to production environments
- Monitor costs in GCP console during testing

---
