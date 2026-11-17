# Azure Enterprise Web Platform

A portfolio project for Azure infrastructure, Terraform, GitHub Actions CI/CD, Linux administration, networking, monitoring, and OPA/Rego policy as code.

This is a learning/reference environment, not a production-ready landing zone. The application tier is one VM, the Application Gateway uses Standard_v2 without WAF, and the sample does not configure DNS, private endpoints, Key Vault certificate delivery, or zone-redundant recovery.

## Architecture

~~~text
Internet
  |
  | HTTPS :443
  v
Azure Application Gateway (Standard_v2, public IP, TLS termination)
  |
  | HTTP :80, custom /health probe
  v
Web VM Scale Set (NGINX reverse proxy)
  |
  | HTTP :80
  v
Application VM (NGINX sample page and /health endpoint)

Web and app subnets -- NAT Gateway --> Internet egress
Application Gateway, VM/VMSS logs, and metrics --> Azure Monitor / Log Analytics
Terraform state --> private Azure Blob Storage container with Azure AD/OIDC auth
~~~

There is no separate Azure Load Balancer. The Application Gateway sends requests directly to the VM Scale Set backend pool. NGINX on each web instance then proxies requests to the private application VM.

### Network rules

- Internet clients reach the Application Gateway over HTTPS on port 443.
- The GatewayManager service tag is allowed to the Application Gateway subnet on TCP 65200-65535, and the AzureLoadBalancer service tag is allowed for platform health traffic.
- Application Gateway has an explicit outbound Internet rule required by its subnet configuration.
- Only Application Gateway subnet addresses can reach the web subnet on HTTP port 80.
- Only web subnet addresses can reach the application subnet on HTTP port 80.
- The subnet NSGs deny unmatched inbound traffic.
- The web and app subnets disable default outbound access and use a Standard NAT Gateway for explicit outbound connectivity. The dedicated Application Gateway subnet is excluded from that workload-subnet policy and retains its required platform connectivity.

## What is implemented

- Terraform modules for resource groups, VNet/subnets/NSGs, compute, Application Gateway, and monitoring.
- Separate example variable files for dev and prod.
- Linux VM and VM Scale Set provisioning with cloud-init and SSH public-key authentication.
- CPU autoscaling for the web VMSS (scale out above 70%, scale in below 30%).
- A custom Application Gateway probe for /health, using host 127.0.0.1 for the single-site NGINX backend.
- Azure Monitor Agent and a Data Collection Rule for Linux syslog.
- Application Gateway diagnostic logs and metrics sent to Log Analytics.
- Terraform remote state bootstrap using Azure Blob Storage.
- GitHub Actions CI for formatting, Terraform validation, and OPA tests.
- GitHub Actions CD that creates a plan on pushes to main and blocks it when OPA finds a policy violation. It does not run terraform apply.

## OPA/Rego policies

The policies in infrastructure/policies.rego evaluate Terraform plan JSON and currently enforce:

- Standard SKU for public IP addresses.
- No inbound SSH from the Internet.
- No inbound NSG allow rule from any source (*, 0.0.0.0/0, or ::/0).
- SSH rules are detected across TCP or wildcard protocol, single ports and port ranges, and single or list source fields.
- SSH-key-only authentication on Linux VMs and VM Scale Sets.
- Disabled public internet query access and more than 30 days of Log Analytics retention.
- HTTPS for Application Gateway listeners.
- Disabled default outbound access for workload subnets. The managed Application Gateway subnet is exempt because it has service-managed connectivity requirements.

Run the unit tests and format check from the repository root:

~~~powershell
opa fmt --fail infrastructure/policies.rego infrastructure/policy_test.rego
opa test infrastructure/policies.rego infrastructure/policy_test.rego -v
~~~

To evaluate a plan locally, create a saved plan and convert it to JSON. Terraform plan files and plan JSON can contain sensitive data, so keep them local and do not upload or commit them:

~~~powershell
Set-Location infrastructure
terraform plan -out=dev.tfplan -var-file="environments/dev.tfvars"
$planJson = terraform show -json dev.tfplan
[IO.File]::WriteAllText("plan.json", $planJson, [Text.UTF8Encoding]::new($false))
opa eval --fail-defined --format pretty --data policies.rego --input plan.json 'data.terraform.security.deny[_]'
~~~

A policy violation makes OPA exit with a non-zero status. Delete the local plan JSON after review.

## Prerequisites

- Terraform 1.15.5 (the CI version) or a compatible newer version.
- Azure CLI and an Azure subscription with permissions to create the resources in the examples.
- OPA 1.22.2 (the CI version).
- OpenSSL or another tool that can create a PFX certificate.
- An SSH key pair. Only the public key is provided to Terraform.

Azure Application Gateway v2 and NAT Gateway incur hourly and data-processing charges. VM/VMSS, public IP, and Log Analytics ingestion/retention also incur charges. Review the Azure pricing for your region before deploying. A terraform plan does not create billable Azure resources; terraform apply does.

## Bootstrap the shared state resources

The bootstrap stack creates the shared services resource group, a storage account with a unique suffix, and a private container for Terraform state. Run it once per subscription. The bootstrap stack itself uses local state; keep that state file secure and backed up.

~~~powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply -var="sharedservices_resource_group_name=sharedservices-rg" -var="sharedservices_resource_group_location=West Europe"
terraform -chdir=bootstrap output -raw storage_account_name
~~~

Use the storage account name from the last command when initializing the infrastructure stack. Log in to Azure and select the intended subscription:

~~~powershell
az login
$subscriptionId = Read-Host "Azure subscription ID"
az account set --subscription $subscriptionId
$stateStorage = "replace-with-bootstrap-output"
terraform -chdir=infrastructure init -reconfigure -backend-config="resource_group_name=sharedservices-rg" -backend-config="storage_account_name=$stateStorage" -backend-config="container_name=terraform-state" -backend-config="key=dev.terraform.tfstate" -backend-config="subscription_id=$(az account show --query id -o tsv)" -backend-config="use_oidc=true" -backend-config="use_azuread_auth=true"
~~~

Azure CLI authentication is available for local Terraform use. GitHub Actions uses OIDC and Azure AD data-plane authentication for the same backend. Grant the deployment identity Storage Blob Data Contributor on the state storage account/container so it can read state and acquire leases, plus the resource-scoped roles needed for the resources Terraform manages. The sample does not create role assignments.

## Prepare and plan a dev deployment

Copy the example file to a local variable file. The repository ignores real tfvars files and certificates. The root Terraform variable defaults to sharedservices-rg for compatibility with older local variable files; set sharedservices_resource_group_name explicitly if your shared services resource group uses another name.

~~~powershell
Set-Location infrastructure
Copy-Item environments/dev.tfvars.example environments/dev.tfvars
New-Item -ItemType Directory -Force certs
~~~

Place a PFX at infrastructure/certs/app-gateway-01.pfx, then update ssl_certificate_path in your local environments/dev.tfvars to ./certs/app-gateway-01.pfx. A self-signed PFX is suitable for a lab but browsers will not trust it. Do not commit the PFX, its password, or a private key.

Set the VM SSH public key and securely prompt for the PFX password in PowerShell:

~~~powershell
$env:TF_VAR_ssh_public_key = Get-Content -Raw "$HOME/.ssh/id_ed25519.pub"
$securePfxPassword = Read-Host -Prompt "PFX password" -AsSecureString
$env:TF_VAR_ssl_certificate_password = [System.Net.NetworkCredential]::new("", $securePfxPassword).Password
terraform plan -var-file="environments/dev.tfvars"
~~~

A certificate password must match the PFX when Terraform reads it. If the old password is unknown, create a replacement PFX with a password you control; it cannot be recovered from the PFX file.

## GitHub Actions setup

The Terraform CI workflow runs on every branch push and on pull requests to main. It performs formatting, initializes both Terraform stacks without a backend, validates them, and runs OPA formatting and unit tests.

The Terraform CD workflow runs on pushes to main. It runs a dev plan and the OPA plan gate, but does not apply changes. Configure these repository Actions secrets before expecting that workflow to pass:

- AZURE_CLIENT_ID, AZURE_TENANT_ID, and AZURE_SUBSCRIPTION_ID for an Azure federated identity.
- TF_BACKEND_RESOURCE_GROUP and TF_BACKEND_STORAGE_ACCOUNT for the bootstrapped remote state resources.
- TF_VAR_ssh_public_key with the VM's SSH public key.
- TF_VAR_ssl_certificate_password with the PFX password.
- SSL_CERTIFICATE_PFX_BASE64 with the base64-encoded PFX file.

Configure a GitHub Actions OIDC federated credential for the repository and grant the identity the minimum Azure roles needed for the Terraform plan and remote state access. The CD workflow writes its temporary PFX and plan JSON to the hosted runner and removes them at the end; it does not upload plan artifacts.

## Environment examples and operational limits

- Change resource names, region, workspace name, SSH key, and certificate path to match your subscription. Log Analytics workspace names must be available in the selected region.
- The prod example keeps a single application VM, so that tier remains a single point of failure even though the web tier scales from two to five instances. Use a separate state key such as prod.terraform.tfstate when initializing the prod environment; the GitHub CD workflow is intentionally dev-only.
- Standard_v2 does not include the Web Application Firewall. Use WAF_v2 and configure its policy before treating the gateway as an internet-facing production security boundary.
- The certificate is loaded from a local file into Terraform. For production, deliver and rotate certificates with Key Vault integration and avoid storing certificate material in Terraform plans.
- The sample uses HTTP between the gateway, reverse proxy, and application VM inside the VNet. Add backend TLS and stronger host, OS, patching, and application controls for production.
- Log Analytics internet query access is disabled by policy. If your operational model requires public workspace queries, change that control deliberately and update the Rego policy rather than silently weakening the gate.
- The sample monitoring DCR collects all Linux syslog facilities and levels. Tune collection and retention for your workload and cost target.

## Repository layout

- bootstrap/: shared state resource bootstrap.
- infrastructure/: reusable Terraform root, modules, environment examples, and policy code.
- infrastructure/policies.rego: OPA policies.
- infrastructure/policy_test.rego: OPA unit tests.
- .github/workflows/terraform.yml: CI checks.
- .github/workflows/terraform-cd.yml: OIDC-authenticated dev plan and policy gate.
