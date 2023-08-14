.PHONY: all init apply plan destroy fmt clean destroy-all destroy-k8s uninstall-vault

all: apply

init: fmt
	@aws sts get-caller-identity
	@terraform init

apply: init
	@terraform apply -auto-approve
	@sleep 30
	@scripts/00-prereqs.sh

plan: init
	@terraform validate
	@terraform plan

destroy-tf: init
	@terraform destroy -auto-approve

fmt:
	@terraform fmt -recursive

destroy-k8s: uninstall-vault
	-@terraform destroy -auto-approve \
		-target module.argocd \
		-target module.echoserver \
		-target module.vault
	-@kubectl delete namespace argocd

destroy-all: destroy-k8s destroy-tf

clean:
	-rm -rf .terraform/
	-rm .terraform.lock.hcl
	-rm terraform.tfstate*


install-consul:
	@kubectl apply -f argocd/consul/consul-project.yaml
	@kubectl apply -f argocd/consul/consul-application.yaml
	@argocd app sync consul-cluster

uninstall-consul:
#	-@helm uninstall vault -n vault
	-@kubectl delete -f argocd/consul/consul-application.yaml
	-@kubectl delete -f argocd/consul/consul-project.yaml
	-@kubectl delete pvc -n consul --all

install-tfe:
	@kubectl create namespace terraform-enterprise
	@kubectl apply -f files/tfe-quay-secret.yaml
	@helm install terraform-enterprise hashicorp/terraform -n terraform-enterprise --values=files/tfe-values.yaml

uninstall-tfe:
	-@helm uninstall terraform-enterprise -n terraform-enterprise
	-@kubectl delete namespace terraform-enterprise

install-vault:
#	@helm install vault hashicorp/vault -n vault --create-namespace --values=files/vault-values.yaml
	@kubectl apply -f argocd/vault/vault-project.yaml
	@kubectl apply -f argocd/vault/vault-application.yaml
	@argocd app sync vault-cluster
	@sleep 60
	@scripts/10-vault-init.sh

uninstall-vault:
#	-@helm uninstall vault -n vault
	-@kubectl delete -f argocd/vault/vault-application.yaml
	-@kubectl delete -f argocd/vault/vault-project.yaml
	-@kubectl delete pvc -n vault --all

logs-vault:
	@kubectl logs -n vault vault-0 -c vault -f
