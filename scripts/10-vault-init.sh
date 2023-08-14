set -o pipefail

kubectl wait --for=condition=PodScheduled pod --all --namespace vault --timeout=60s

sleep 30

kubectl exec -n vault -ti vault-0 -- vault status
kubectl exec -n vault -ti vault-0 -- vault operator init -format=json | tee vault-init.json
kubectl exec -n vault -ti vault-0 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -n vault -ti vault-0 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[1]')
kubectl exec -n vault -ti vault-0 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[2]')
kubectl exec -n vault -ti vault-0 -- vault status

sleep 30

kubectl exec -n vault -ti vault-1 -- vault status
kubectl exec -n vault -ti vault-1 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -n vault -ti vault-1 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[1]')
kubectl exec -n vault -ti vault-1 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[2]')
kubectl exec -n vault -ti vault-1 -- vault status

kubectl exec -n vault -ti vault-2 -- vault status
kubectl exec -n vault -ti vault-2 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -n vault -ti vault-2 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[1]')
kubectl exec -n vault -ti vault-2 -- vault operator unseal $(cat vault-init.json | jq -r '.unseal_keys_b64[2]')
kubectl exec -n vault -ti vault-2 -- vault status

export VAULT_ADDR=$(terraform output -raw vault_url)
export VAULT_TOKEN=$(cat vault-init.json | jq -r '.root_token')
export VAULT_SKIP_VERIFY=true

vault operator raft list-peers