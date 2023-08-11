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
	-@kubectl delete namespace vault

destroy-all: destroy-k8s destroy-tf

uninstall-vault:
	-@helm uninstall vault -n vault
	-@kubectl delete pvc,pv -n vault --all

clean:
	-rm -rf .terraform/
	-rm .terraform.lock.hcl
	-rm terraform.tfstate*


install-vault:
	@helm install vault hashicorp/vault -n vault --create-namespace --values=files/vault-values.yaml

logs-vault:
	@kubectl logs -n vault vault-0 -c vault -f
