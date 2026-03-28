#!/bin/bash
set -euo pipefail

APPS_DIR=../../../starter/apps

ENVIRONMENT=${1:-devopstht}
AWS_REGION=${AWS_DEFAULT_REGION:-eu-west-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

ORDER_API_REPO=$(terraform -chdir=../terraform output -raw order_api_repository_url)
ORDER_PROCESSOR_REPO=$(terraform -chdir=../terraform output -raw order_processor_repository_url)
ORDER_HISTORY_REPO=$(terraform -chdir=../terraform output -raw order_history_repository_url)

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

build_and_push() {
  local repo="$1"
  local context_dir="$2"
  local label="$3"
  local tag="${repo}:$(date +%Y%m%d_%H%M%S)"

  echo "Building ${label} image..."
  echo "- Repository: ${repo}"

  docker buildx build \
    --no-cache \
    --platform linux/amd64,linux/arm64 \
    --progress plain \
    --push \
    -t "${repo}:latest" \
    -t "${tag}" \
    "${context_dir}"

  echo "Pushed ${label} image (latest + ${tag})"
  echo "${tag}"
}

ORDER_API_TAG=$(build_and_push "${ORDER_API_REPO}" "${APPS_DIR}/order-api" "Order API" | tail -n 1)
ORDER_PROCESSOR_TAG=$(build_and_push "${ORDER_PROCESSOR_REPO}" "${APPS_DIR}/order-processor" "Order Processor" | tail -n 1)
ORDER_HISTORY_TAG=$(build_and_push "${ORDER_HISTORY_REPO}" "${APPS_DIR}/order-history-service" "Order History Service" | tail -n 1)

echo "Pushed Order API Tag: ${ORDER_API_TAG}"
echo "Pushed Order Processor Tag: ${ORDER_PROCESSOR_TAG}"
echo "Pushed Order History Tag: ${ORDER_HISTORY_TAG}"
echo "Successfully built and pushed all images!"
