set -e

KUBE_CONTEXT=`terraform output -raw eks_cluster_kube_context`

aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_cluster_name)

kubectl --context $KUBE_CONTEXT cluster-info

ARGOCD_ADMIN_PASSWORD=`terraform output -raw argocd_admin_password`
ARGOCD_FQDN=`terraform output -raw argocd_fqdn`

argocd login $ARGOCD_FQDN --username admin --password $ARGOCD_ADMIN_PASSWORD
