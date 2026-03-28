THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR      := $(dir $(realpath $(THIS_MAKEFILE)))

.PHONY: tf-cluster-init
tf-cluster-init:
	@@cd $(THIS_DIR) && terraform init 

.PHONY: tf-cluster-destroy
tf-cluster-destroy:
	@@cd $(THIS_DIR) && terraform destroy

.PHONY: tf-cluster-apply
tf-cluster-apply: tf-cluster-plan
	@@cd $(THIS_DIR) && terraform apply tfplan.json

.PHONY: tf-cluster-plan
tf-cluster-plan:
	@@cd $(THIS_DIR) && terraform plan -out tfplan.json

.PHONY: tf-cluster-graph
tf-cluster-graph:
	@@cd $(THIS_DIR) && terraform graph -type=plan

	