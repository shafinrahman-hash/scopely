# CloudOps Technical Assessment

This assessment evaluates your ability to operate and reason about a cloud-based microservices system under realistic conditions.

## Assessment Goal

The starter project is deployable, but parts of the code may be intentionally broken.
Your job is to diagnose issues, fix what is needed, and deliver a working deployment.

In short, the challenge is:
1. Fix code and deploy
2. Document the implemented architecture in a diagram
3. Document an improved architecture in a second diagram

## Scope

Deploy and validate the following AWS architecture using Terraform and ECS:
- ECS services and task definitions
- DynamoDB
- SQS
- RDS

## What You Must Deliver

### 1) Working Deployment
- Fix issues in the provided code/infrastructure as needed.
- Deploy a working solution.
- Provide reproducible deployment and validation instructions.

### 2) Implemented Architecture Diagram
- Submit `architecture-current.drawio`.
- The diagram must represent what you actually deployed.
- Show service interactions and data flow across ECS, DynamoDB, SQS, and RDS.
- Be as thorough as you need to be.

### 3) Improved Architecture Diagram
- Submit `architecture-improved.drawio`.
- Show how you would improve the architecture for scale, reliability, operability, security, observability, and/or cost.
- Be ready to explain tradeoffs and migration considerations.

## Discussion Format

During review, we will:
- Ask you to explain your implemented diagram.
- Ask follow-up questions on design choices and tradeoffs.
- Discuss your improved architecture diagram and proposed changes.

## Resources Provided

- Starter application code in `starter/apps`
- ECR support in `infra/ecr/terraform`
- Application stack Terraform baseline in `infra/stack/terraform`
- Documentation templates in `deliverables/`

## Submission

1. Commit your code and Terraform changes.
2. Include both required `.drawio` files:
   - `deliverables/architecture-current.drawio`
   - `deliverables/architecture-improved.drawio`
3. Include deployment/testing instructions and decision notes in `deliverables/decisions.md`.
4. Share the repository URL.

## Important Notes

- Prioritize a working deployment over perfect polish.
- Document assumptions and known limitations.
- Use secure defaults where possible.
