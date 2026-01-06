#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
REPO_URL="https://github.com/nokia-eda/playground.git"
PLAYGROUND_DIR="playground"
SREXPERTS_DIR="/opt/srexperts"
BIN_DIR="/usr/local/bin"
CLAB_TOPO_DIR="clab"

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
  git clone "$REPO_URL"
else
  echo "[INFO] Playground repo already exists. Skipping clone."
fi

pushd "$PLAYGROUND_DIR"

### --- SYSCTL CONFIG ---
echo "[INFO] Configuring sysctls..."
make configure-sysctl-params

### --- DOWNLOAD TOOLS ---
echo "[INFO] Downloading EDA tools..."
make download-tools
make download-k9s

### --- INSTALL kubectl + k9s ---
echo "[INFO] Installing kubectl and k9s to $BIN_DIR"
cp "$(realpath ./tools/kubectl)" "$BIN_DIR/kubectl"
cp "$(realpath ./tools/k9s)" "$BIN_DIR/k9s"
chmod +x "$BIN_DIR/kubectl" "$BIN_DIR/k9s"

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

### --- LOAD BONDING MODULE ---
echo "[INFO] Loading bonding kernel module..."
modprobe bonding mmiimon=100 mode=802.3ad lacp_rate=fast || true

### --- DEPLOY CLAB ---
echo "[INFO] Deploying containerlab topology..."
containerlab deploy -c -t "./${CLAB_TOPO_DIR}"

### --- DEPLOY EDA ---
echo "[INFO] Deploying EDA..."
EXT_DOMAIN_NAME=${EDA_URL} SIMULATE=false make try-eda

### --- RECORD INITIAL TX ---
echo "[INFO] Recording initial EDA transaction state..."
bash eda/record-init-tx.sh

### --- ONBOARD CLAB TOPOLOGY ---
clab-connector integrate --topology-data ${CLAB_TOPO_DIR}/clab-kpn-hackathon/topology-data.json --eda-url ${EDA_URL} --eda-password ${EVENT_PASSWORD}

# ### --- FABRIC CLEANUP & DEPLOY ---
# echo "[INFO] Cleaning up default fabric pools..."
# bash ./eda/cleanup-pools.sh

# echo "[INFO] Applying fabric resources..."
# kubectl apply -f "$(pwd)/eda/fabric"

### --- OPTIONAL: EXTRACT KUBECONFIG ---
echo "[INFO] Extracting kubeconfig for EDA kind cluster..."
mkdir -p ~/.kube
./tools/kind-v0.24.0 get kubeconfig --name eda-demo > ~/.kube/eda.kubeconfig

### --- DONE ---
echo "=============================================================="
echo "[SUCCESS] EDA environment complete!"
echo "[INFO] UI available at https://<host>:9443"
echo "[INFO] Restore script: bash /opt/srexperts/restore-eda.sh"
echo "=============================================================="
