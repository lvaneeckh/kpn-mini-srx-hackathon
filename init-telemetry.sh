indent_out() { sed 's/^/    /'; }
# Term colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"
### Telemetry stack
# Install helm chart
ST_STACK_NS="eda"

EDA_CORE_NS=eda-system
# get toolbox pod name and error if not found
TOOLBOX_POD=$(kubectl -n ${EDA_CORE_NS} get pods -l eda.nokia.com/app=eda-toolbox -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$TOOLBOX_POD" ]]; then
    echo -e "${RED}Error: Toolbox pod not found.${RESET}"
    exit 1
fi

edactl() {
    kubectl -n ${EDA_CORE_NS} exec ${TOOLBOX_POD} \
        -- edactl "$@"
}
TB_LAB_DIR="/tmp/eda-telemetry-lab"
# copy manifests to the toolbox under /tmp/eda-telemetry-lab/manifests
# first exec rm -rf /tmp/eda-telemetry-lab/manifests to avoid conflicts
kubectl -n ${EDA_CORE_NS} exec ${TOOLBOX_POD} -- bash -c "rm -rf ${TB_LAB_DIR} && mkdir -p ${TB_LAB_DIR}"
kubectl -n ${EDA_CORE_NS} cp ./manifests ${TOOLBOX_POD}:${TB_LAB_DIR}/manifests

echo -e "${GREEN}--> Installing telemetry-stack helm chart...${RESET}"
# Install apps and EDA resources
echo -e "${GREEN}--> Installing Prometheus and Kafka exporter EDA apps...${RESET}"
# dir where manifests will be copied from the host to the toolbox pod
TB_LAB_DIR="/tmp/eda-telemetry-lab"
# copy manifests to the toolbox under /tmp/eda-telemetry-lab/manifests
# first exec rm -rf /tmp/eda-telemetry-lab/manifests to avoid conflicts
kubectl -n ${EDA_CORE_NS} exec ${TOOLBOX_POD} -- bash -c "rm -rf ${TB_LAB_DIR} && mkdir -p ${TB_LAB_DIR}"
kubectl -n ${EDA_CORE_NS} cp ./manifests ${TOOLBOX_POD}:${TB_LAB_DIR}/manifests

APP_INSTALL_WF=$(kubectl create -f ./manifests/0000_apps.yaml)
APP_INSTALL_WF_NAME=$(echo "$APP_INSTALL_WF" | awk '{print $1}')
echo "Workflow $APP_INSTALL_WF_NAME created" | indent_out

echo -e "${GREEN}--> Waiting for EDA apps installation to complete...${RESET}"
kubectl -n ${EDA_CORE_NS} wait --for=jsonpath='{.status.result}'=Completed $APP_INSTALL_WF_NAME --timeout=300s | indent_out

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
edactl apply --commit-message "installing eda-telemetry-lab common resources" -f ${TB_LAB_DIR}/manifests/0050_http_proxy.yaml | indent_out

edactl apply --commit-message "installing eda-telemetry-lab common resources" -f ${TB_LAB_DIR}/manifests/0020_prom_exporters.yaml | indent_out

echo -e "${GREEN}--> Waiting for Grafana deployment to be available...${RESET}"
kubectl -n ${ST_STACK_NS} wait --for=condition=available deployment/grafana --timeout=300s | indent_out
