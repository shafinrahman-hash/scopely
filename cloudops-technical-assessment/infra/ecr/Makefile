THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR      := $(dir $(realpath $(THIS_MAKEFILE)))

ENVIRONMENT ?= cloudops

.PHONY: tf-init tf-plan tf-apply tf-destroy tf-output upload cleanup deploy

tf-init:
	@cd $(THIS_DIR)/terraform && terraform init

tf-plan: tf-init
	@cd $(THIS_DIR)/terraform && terraform plan -out=tfplan -var="environment=$(ENVIRONMENT)"

tf-apply: tf-plan
	@cd $(THIS_DIR)/terraform && terraform apply tfplan

tf-destroy: tf-init
	@cd $(THIS_DIR)/terraform && terraform destroy -var="environment=$(ENVIRONMENT)"

tf-output: tf-init
	@cd $(THIS_DIR)/terraform && terraform output

upload:
	@cd $(THIS_DIR)/scripts && ./upload.sh $(ENVIRONMENT)

cleanup:
	@cd $(THIS_DIR)/scripts && ./cleanup.sh $(ENVIRONMENT)

deploy: tf-apply upload
	@echo "ECR repositories applied and images uploaded."
