indent_out() { sed 's/^/    /'; }
# Term colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"
### Telemetry stack
# Install helm chart
ST_STACK_NS="eda"
EDA_URL="https://100.124.178.192:9443"

echo -e "${GREEN}--> Installing telemetry-stack helm chart...${RESET}"

proxy_var="${https_proxy:-$HTTPS_PROXY}"
if [[ -n "$proxy_var" ]]; then
    echo "Using proxy for grafana deployment: $proxy_var"
    noproxy="localhost\,127.0.0.1\,.local\,.internal\,.svc"
    echo "using noproxy: $noproxy"

    helm upgrade --install telemetry-stack ./charts/telemetry-stack \
    --set https_proxy="$proxy_var" \
    --set no_proxy="$noproxy" \
    --set eda_url="${EDA_URL}" \
    --create-namespace -n ${ST_STACK_NS} | indent_out
else
    helm upgrade --install telemetry-stack ./charts/telemetry-stack \
    --set eda_url="${EDA_URL}" \
    --create-namespace -n ${ST_STACK_NS} | indent_out
fi

echo -e "${GREEN}--> Creating EDA resources...${RESET}"
edactl apply --commit-message "installing eda-telemetry-lab common resources" -f ./manifests | indent_out

echo -e "${GREEN}--> Waiting for Grafana deployment to be available...${RESET}"
kubectl -n ${ST_STACK_NS} wait --for=condition=available deployment/grafana --timeout=300s | indent_out

