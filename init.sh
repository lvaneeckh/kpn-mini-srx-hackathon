#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
REPO_URL="https://github.com/nokia-eda/playground.git"
PLAYGROUND_DIR="${HOME}/playground"
SREXPERTS_DIR="/opt/srexperts"
BIN_DIR="/usr/local/bin"
CLAB_TOPO_DIR="${HOME}/kpn-mini-srx-hackathon/clab"
EDA_SCRIPTS_DIR="${HOME}/kpn-mini-srx-hackathon/eda"

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
EXT_DOMAIN_NAME=${EDA_URL} SIMULATE=false make try-eda

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
clab-connector integrate --topology-data ${CLAB_TOPO_DIR}/clab-kpn-hackathon/topology-data.json --eda-url https://${EDA_URL}:9443 -n eda

# ### --- RECORD INITIAL TX ---
# echo "[INFO] Recording initial EDA transaction state..."
# bash ${EDA_SCRIPTS_DIR}/record-init-tx.sh

# ### --- FABRIC CLEANUP & DEPLOY ---
# echo "[INFO] Cleaning up default fabric pools..."
# bash ./eda/cleanup-pools.sh

# echo "[INFO] Applying fabric resources..."
# kubectl apply -f "$(pwd)/eda/fabric"

# Update Grafana dashboard with correct node prefix
DASHBOARD_FILE="charts/telemetry-stack/files/grafana/dashboards/st.json"
if [[ -f "$DASHBOARD_FILE" ]]; then
    echo -e "${GREEN}--> Updating Grafana dashboard with node prefix: $NODE_PREFIX${RESET}"
    # First replace clab-eda-st with a temporary marker, then replace eda-st, then replace marker with final prefix
    sed -i.bak "s/clab-eda-st/__TEMP_MARKER__/g" "$DASHBOARD_FILE"
    sed -i "s/eda-st/$NODE_PREFIX/g" "$DASHBOARD_FILE"
    sed -i "s/__TEMP_MARKER__/$NODE_PREFIX/g" "$DASHBOARD_FILE"
fi

### Telemetry stack
# Install helm chart
echo -e "${GREEN}--> Installing telemetry-stack helm chart...${RESET}"

proxy_var="${https_proxy:-$HTTPS_PROXY}"
if [[ -n "$proxy_var" ]]; then
    echo "Using proxy for grafana deployment: $proxy_var"
    noproxy="localhost\,127.0.0.1\,.local\,.internal\,.svc"

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

# Show connection details
echo ""
echo -e "${GREEN}--> Access Grafana: ${EDA_URL}/core/httpproxy/v1/grafana/d/Telemetry_Playground/${RESET}"
echo -e "${GREEN}--> Access Prometheus: ${EDA_URL}/core/httpproxy/v1/prometheus/query${RESET}"

### --- DONE ---
echo "=============================================================="
echo "[SUCCESS] EDA environment complete!"
echo "[INFO] UI available at https://<host>:9443"
echo "[INFO] Restore script: bash /opt/srexperts/restore-eda.sh"
echo "=============================================================="
