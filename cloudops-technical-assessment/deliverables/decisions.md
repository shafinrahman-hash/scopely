# CloudOps Assessment Decisions

## What I fixed

### Application and local runtime
- Fixed local orchestration and startup issues in `starter/apps`.
- Added robust local end-to-end verification via `scripts/test_docker_compose.sh`.
- Updated health endpoint consistency by adding `/health/live` to API/processor services.
- Hardened container runtime:
  - pinned Python base image patch versions
  - run `order-history-service` as non-root user
  - removed hardcoded credentials from app scripts and compose defaults
  - moved hardcoded secrets to `.env` (tracked pattern: commit `starter/apps/.env.example`, copy to `.env` locally) so production can later use AWS Secrets Manager and inject values as environment variables in ECS/EKS

### Terraform and infrastructure
- Added provider settings for local mock planning (without real AWS account) in stack/ECR roots.
- Added explicit input var files to avoid repeated prompts and pin image versions.
- Added missing consistency input `order_history_repo_arn`.
- Improved security posture:
  - tightened ECS task ingress to application port
  - ECS task definitions now keep `containerPort = 8000` and remove explicit `hostPort = 8000` in `awsvpc` mode for cleaner/safer defaults
  - corrected RDS SG port to `5432`
  - removed wildcard IAM `*:*` policy and introduced scoped action sets
  - scoped IAM resources to specific DynamoDB and SQS ARNs
  - enforced IMDSv2 on ECS EC2 launch template
- Added secrets-aware DB credential strategy:
  - local/mock mode via `TF_VAR_rds_db_password`
  - production mode via Secrets Manager ARN + ECS task `secrets`
  - validation checks to enforce correct input combinations
- Hardened RDS defaults in `modules/rds/main.tf`:
  - `multi_az = true`
  - `backup_retention_period = 7`
  - `deletion_protection = true`
  - `skip_final_snapshot = false`
  - `final_snapshot_identifier = "${var.environment}-postgres-final"`
  - `apply_immediately = false` (safer production behavior)
  - pinned engine version to `engine_version = "18.3"` instead of leaving version selection implicit
- Upgraded network architecture:
  - public ALB, private ECS and RDS
  - private subnets with NAT egress
  - multi-AZ defaults with subnet distribution
- Added ALB hardening:
  - optional HTTPS listener + HTTP->HTTPS redirect
  - corrected ALB target group health check path from `/healthz` to `/health` to match service endpoints
  - optional WAF baseline with managed rules, rate-limit, geo/IP block options
  - ALB access logs to encrypted/versioned S3 with lifecycle retention
- Added HTTPS toggle behavior and safety checks:
  - HTTP listener always exists.
  - if `enable_https = false`, HTTP forwards to target group (existing behavior).
  - if `enable_https = true`, HTTP redirects to HTTPS (`301`) and HTTPS listener on `443` forwards to target group.
  - listener rule binds to HTTPS listener when enabled, otherwise HTTP listener.
  - ALB security group allows `443` ingress (along with `80`).
  - `checks.tf` enforces that when `enable_https = true`, `acm_certificate_arn` must be provided.
- Added optional state bootstrap stack in `infra/state/terraform` to create a dedicated S3 backend bucket.

## Validation steps and results

### Local app validation
From `starter/apps`, create local env from the example (`.gitignore` keeps `.env` out of Git):

```bash
cp .env.example .env
```

Then:

```bash
make compose-all
./scripts/test_docker_compose.sh
```

Observed behavior:
- user seeded in order-history service
- order created through order-api
- order retrievable by order id
- order projection visible in order-history list and summary

### Terraform validation (mock/local mode)
Use mock credentials:

```bash
export AWS_ACCESS_KEY_ID="mock"
export AWS_SECRET_ACCESS_KEY="mock"
export AWS_DEFAULT_REGION="eu-west-1"
export AWS_REGION="eu-west-1"
export AWS_EC2_METADATA_DISABLED=true
```

ECR root:

```bash
cd infra/ecr/terraform
terraform init -backend=false -reconfigure
terraform validate
terraform plan -input=false
```

Stack root:

```bash
cd infra/stack/terraform
export TF_VAR_rds_db_password="local-dev-password"
terraform init -backend=false -reconfigure
terraform validate
terraform plan -input=false
```

Result: both roots validate and plan successfully in mock mode.

## Remote backend note
- Backend templates are provided for S3 backend usage.
- For local mock planning, use `-backend=false`.
- For real AWS environments, initialize backend with real AWS credentials and S3 bucket.

## Assumptions
- Local machine validation is the primary execution path for this submission.
- No real AWS account was used for apply/deploy in this run.
- Security features (WAF/HTTPS/Secrets Manager) are toggle-driven to support both local and production-style modes.

## Known limitations and follow-ups
- Full service-to-service mTLS is not implemented; current internal traffic is private-network HTTP with SG constraints.
- WAF managed rules are in count mode first to tune false positives before enforce mode.
- Backend lockfile mode requires newer Terraform versions; local mock mode may keep backend disabled.
