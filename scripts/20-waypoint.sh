set -o pipefail

kubectl wait --for=condition=ready pod -l component=server --namespace waypoint --timeout=60s
sleep 20
WAYPOINT_TOKEN=$(kubectl get secret -n waypoint waypoint-server-token -o jsonpath="{.data.token}" | base64 --decode)
echo "WAYPOINT_TOKEN: $WAYPOINT_TOKEN"
