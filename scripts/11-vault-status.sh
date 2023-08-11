set -o pipefail

export VAULT_ADDR=$(terraform output -raw vault_url)
export VAULT_TOKEN=$(cat vault-init.json | jq -r '.root_token')
export VAULT_SKIP_VERIFY=true

vault status
vault operator raft list-peers

echo
echo "VAULT_TOKEN:  $VAULT_TOKEN"