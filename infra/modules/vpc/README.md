# VPC module (Sprint 0 stub)

**Inputs (planned):** `cidr`, `az_count`, `environment`, `enable_nat`, `single_nat_gateway`  
**Outputs (planned):** `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `isolated_subnet_ids`

## Sprint 0

Document-only; wire `module "vpc"` from `infra/envs/staging` after S0-09.

## Standards

- 3 AZ minimum in staging/prod  
- VPC endpoints for S3, ECR, Secrets Manager where cost-effective
