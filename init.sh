#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
REPO_URL="https://github.com/nokia-eda/playground.git"
PLAYGROUND_DIR="${HOME}/playground"
SREXPERTS_DIR="/opt/srexperts"
BIN_DIR="/usr/local/bin"
CLAB_TOPO_DIR="${HOME}/kpn-mini-srx-hackathon/clab"
EDA_SCRIPTS_DIR="${HOME}/kpn-mini-srx-hackathon/eda"
HACKATHON_DIR="${HOME}/kpn-mini-srx-hackathon/"
EDA_NS="eda"

### --- REQUIREMENTS CHECK ---
echo "[INFO] Checking required environment variables..."
for v in INSTANCE_ID EVENT_PASSWORD; do
  if [[ -z "${!v:-}" ]]; then
    echo "[ERROR] Environment variable $v is not set."
    exit 1
  fi
done

### --- CLONE PLAYGROUND ---
if [[ ! -d "$PLAYGROUND_DIR" ]]; then
  echo "[INFO] Cloning playground repo..."
  git clone "$REPO_URL" "$PLAYGROUND_DIR"
else
  echo "[INFO] Playground repo already exists. Skipping clone."
fi

pushd "$PLAYGROUND_DIR"

### --- SYSCTL CONFIG ---
echo "[INFO] Configuring sysctls..."
make configure-sysctl-params

### --- LOAD BONDING MODULE ---
echo "[INFO] Loading bonding kernel module..."
modprobe bonding mmiimon=100 mode=802.3ad lacp_rate=fast || true

### --- DEPLOY CLAB ---
echo "[INFO] Deploying containerlab topology..."
containerlab deploy -c -t ${CLAB_TOPO_DIR}

### --- DEPLOY EDA ---
echo "[INFO] Deploying EDA..."
EXT_DOMAIN_NAME=${EDA_URL} LLM_API_KEY=${OPEN_AI_KEY} SIMULATE=false make try-eda

pushd $PLAYGROUND_DIR
### --- DOWNLOAD TOOLS ---
echo "[INFO] Downloading EDA tools..."
make download-tools

### --- INSTALL kubectl ---
echo "[INFO] Installing kubectl to $BIN_DIR"
sudo cp "$(realpath ./tools/kubectl)" "$BIN_DIR/kubectl"
sudo chmod +x "$BIN_DIR/kubectl"

### --- kubectl completion + alias ---
echo "[INFO] Enabling kubectl bash completion..."
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null

echo "alias k=kubectl" >> ~/.bashrc
echo "complete -o default -F __start_kubectl k" >> ~/.bashrc

EDA_CORE_NS=eda-system
# get toolbox pod name and error if not found
TOOLBOX_POD=$(kubectl -n ${EDA_CORE_NS} get pods -l eda.nokia.com/app=eda-toolbox -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$TOOLBOX_POD" ]]; then
    echo -e "${RED}Error: Toolbox pod not found."
    exit 1
fi

edactl() {
    kubectl -n ${EDA_CORE_NS} exec ${TOOLBOX_POD} \
        -- edactl "$@"
}

### --- edactl alias ---
echo "[INFO] Installing edactl alias..."
cat <<'EOF' >> ~/.bashrc
alias edactl='kubectl -n eda-system exec -it $(kubectl -n eda-system get pods \
  -l eda.nokia.com/app=eda-toolbox -o jsonpath="{.items[0].metadata.name}") -- edactl'
EOF
popd

cat << EOF | kubectl apply -f -
apiVersion: core.eda.nokia.com/v1
kind: License
metadata:
  name: eda-non-prod-license
  namespace: eda-system
spec:
  enabled: true
  data: ${EDA_LICENSE}
EOF


### --- ONBOARD CLAB TOPOLOGY ---
uv tool install git+https://github.com/eda-labs/clab-connector.git@v0.8.5
export PATH="/home/workshop/.local/bin:$PATH"
uv tool update-shell
clab-connector integrate --topology-data ${CLAB_TOPO_DIR}/clab-kpn-hackathon/topology-data.json --eda-url https://${EDA_URL}:9443 -n eda --skip-edge-intfs

# ### --- RECORD INITIAL TX ---
# echo "[INFO] Recording initial EDA transaction state..."
# bash ${EDA_SCRIPTS_DIR}/record-init-tx.sh

# ### --- FABRIC CLEANUP & DEPLOY ---
# echo "[INFO] Cleaning up default fabric pools..."
# bash ./eda/cleanup-pools.sh

echo "[INFO] Applying fabric resources..."
# kubectl apply -f "$(pwd)/eda/fabric"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/19_edge-links.yaml"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/21_isl-mtu.yaml"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/22_edge-interfaces.yaml"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/30_policy-accept-all.yaml"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/40_fabric.yaml"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/90_bridge-domain.yaml"
kubectl apply -f "${EDA_SCRIPTS_DIR}/fabric/91_vlan.yaml"

# # Update Grafana dashboard with correct node prefix
# DASHBOARD_FILE="charts/telemetry-stack/files/grafana/dashboards/st.json"
# if [[ -f "$DASHBOARD_FILE" ]]; then
#     echo -e "[INFO]  Updating Grafana dashboard with node prefix: $NODE_PREFIX"
#     # First replace clab-eda-st with a temporary marker, then replace eda-st, then replace marker with final prefix
#     sed -i.bak "s/clab-eda-st/__TEMP_MARKER__/g" "$DASHBOARD_FILE"
#     sed -i "s/eda-st/$NODE_PREFIX/g" "$DASHBOARD_FILE"
#     sed -i "s/__TEMP_MARKER__/$NODE_PREFIX/g" "$DASHBOARD_FILE"
# fi

### Upload Custom Dashboard
echo "[INFO] Uploading custom dashboard..."


export EDA_API_URL="${EDA_API_URL:-https://${EDA_URL}:9443}"
export KC_KEYCLOAK_URL="${EDA_API_URL}/core/httpproxy/v1/keycloak/"
export KC_REALM="master"
export KC_CLIENT_ID="admin-cli"
export KC_USERNAME="${KC_USERNAME:-admin}"
export KC_PASSWORD="${KC_PASSWORD:-admin}"
export EDA_USERNAME="admin"
export EDA_PASSWORD="admin"
export EDA_REALM="eda"
export API_CLIENT_ID="eda"
export FILE="${EDA_SCRIPTS_DIR}/Ingress-Traffic.json"

# Get access token
KC_ADMIN_ACCESS_TOKEN=$(curl -sk \
  --noproxy \
  -X POST "$KC_KEYCLOAK_URL/realms/$KC_REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=$KC_CLIENT_ID" \
  -d "username=$KC_USERNAME" \
  -d "password=$KC_PASSWORD" \
  | jq -r '.access_token')

if [ -z "$KC_ADMIN_ACCESS_TOKEN" ]; then
  echo "Failed to obtain keycloak admin token"
  exit 1
fi


# Fetch all clients in the 'eda-realm'
KC_CLIENTS=$(curl -sk \
  -X GET "$KC_KEYCLOAK_URL/admin/realms/$EDA_REALM/clients" \
  -H "Authorization: Bearer $KC_ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json")

# Get the `eda` client's ID
EDA_CLIENT_ID=$(echo "$KC_CLIENTS" | jq -r ".[] | select(.clientId==\"${API_CLIENT_ID}\") | .id")

if [ -z "$EDA_CLIENT_ID" ]; then
  echo "Client 'eda' not found in realm 'eda-realm'"
  exit 1
fi

# Fetch the client secret
export EDA_CLIENT_SECRET=$(curl -sk \
  -X GET "$KC_KEYCLOAK_URL/admin/realms/$EDA_REALM/clients/$EDA_CLIENT_ID/client-secret" \
  -H "Authorization: Bearer $KC_ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  | jq -r '.value')

if [ -z "$EDA_CLIENT_SECRET" ]; then
  echo "Failed to fetch client secret"
  exit 1
fi

AUTH_RESP=$(curl -sk https://${EDA_URL}:9443/core/httpproxy/v1/keycloak/realms/eda/protocol/openid-connect/token \
-H 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=eda' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'scope=openid' \
--data-urlencode 'username=admin' \
--data-urlencode 'password=admin' \
--data-urlencode "client_secret=$EDA_CLIENT_SECRET")
AUTH_TOKEN="$(echo ${AUTH_RESP} | jq -r .access_token)"

curl -sk  https://${EDA_URL}:9443/core/user-storage/v2/shared/file?path=%2Fdesigns%2FIngress-Traffic-1.json \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @"$FILE"

### Telemetry stack

indent_out() { sed 's/^/    /'; }

### Set EDA URL in values.yaml for the helm chart
sed -i 's|^eda_url:.*|eda_url: https://${EDA_URL}:9443 |' ${HACKATHON_DIR}/charts/telemetry-stack/values.yaml


TB_LAB_DIR="/tmp/eda-telemetry-lab"
# copy manifests to the toolbox under /tmp/eda-telemetry-lab/manifests
# first exec rm -rf /tmp/eda-telemetry-lab/manifests to avoid conflicts
kubectl -n ${EDA_CORE_NS} exec ${TOOLBOX_POD} -- bash -c "rm -rf ${TB_LAB_DIR} && mkdir -p ${TB_LAB_DIR}"
kubectl -n ${EDA_CORE_NS} cp ${HACKATHON_DIR}/manifests ${TOOLBOX_POD}:${TB_LAB_DIR}/manifests

echo -e "[INFO] Installing telemetry-stack helm chart..."
# Install apps and EDA resources
echo -e "[INFO] Installing Prometheus and Kafka exporter EDA apps..."
# dir where manifests will be copied from the host to the toolbox pod
TB_LAB_DIR="/tmp/eda-telemetry-lab"
# copy manifests to the toolbox under /tmp/eda-telemetry-lab/manifests
# first exec rm -rf /tmp/eda-telemetry-lab/manifests to avoid conflicts
kubectl -n ${EDA_CORE_NS} exec ${TOOLBOX_POD} -- bash -c "rm -rf ${TB_LAB_DIR} && mkdir -p ${TB_LAB_DIR}"
kubectl -n ${EDA_CORE_NS} cp ${HACKATHON_DIR}/manifests ${TOOLBOX_POD}:${TB_LAB_DIR}/manifests

APP_INSTALL_WF=$(kubectl create -f ${HACKATHON_DIR}/manifests/0000_apps.yaml)
APP_INSTALL_WF_NAME=$(echo "$APP_INSTALL_WF" | awk '{print $1}')
echo "Workflow $APP_INSTALL_WF_NAME created" | indent_out

echo -e "[INFO] Waiting for EDA apps installation to complete..."
kubectl -n ${EDA_CORE_NS} wait --for=jsonpath='{.status.result}'=Completed $APP_INSTALL_WF_NAME --timeout=300s | indent_out

proxy_var="${https_proxy:-${HTTPS_PROXY:-}}"
if [[ -n "$proxy_var" ]]; then
    echo "Using proxy for grafana deployment: $proxy_var"
    noproxy="localhost\,127.0.0.1\,.local\,.internal\,.svc"
    echo "using noproxy: $noproxy"

    helm upgrade --install telemetry-stack ${HACKATHON_DIR}/charts/telemetry-stack \
    --set https_proxy="$proxy_var" \
    --set no_proxy="$noproxy" \
    --set eda_url="${EDA_URL}" \
    --create-namespace -n ${EDA_NS} | indent_out
else
    helm upgrade --install telemetry-stack ${HACKATHON_DIR}/charts/telemetry-stack \
    --set eda_url="${EDA_URL}" \
    --create-namespace -n ${EDA_NS} | indent_out
fi

echo -e "[INFO] Creating EDA resources..."
edactl apply --commit-message "installing eda-telemetry-lab common resources" -f ${TB_LAB_DIR}/manifests/0050_http_proxy.yaml | indent_out

edactl apply --commit-message "installing eda-telemetry-lab common resources" -f ${TB_LAB_DIR}/manifests/0020_prom_exporters.yaml | indent_out

echo -e "[INFO] Waiting for Grafana deployment to be available..."
kubectl -n ${EDA_NS} wait --for=condition=available deployment/grafana --timeout=300s | indent_out

# Show connection details
echo ""
echo -e "[INFO]  Access Grafana: ${EDA_URL}/core/httpproxy/v1/grafana/d/Telemetry_Playground/"
echo -e "[INFO]  Access Prometheus: ${EDA_URL}/core/httpproxy/v1/prometheus/query"

# latest transaction ID
TX_ID=$(eval edactl transaction | tail -1 | awk '{print $1}')
TX_HASH=$(eval edactl transaction ${TX_ID} | grep commitHash | awk '{print $2}')

echo "$TX_HASH" > $EDA_SCRIPTS_DIR/eda-init-tx


### --- DONE ---
echo "=============================================================="
echo "[SUCCESS] EDA environment complete!"
echo "[INFO] UI available at https://<host>:9443"
echo "=============================================================="
