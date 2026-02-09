### --- LOAD BONDING MODULE ---
echo "[INFO] Loading bonding kernel module..."
modprobe bonding mmiimon=100 mode=802.3ad lacp_rate=fast || true

CLAB_TOPO_DIR="${HOME}/kpn-mini-srx-hackathon/clab"
### --- DEPLOY CLAB ---
echo "[INFO] Deploying containerlab topology..."
containerlab deploy -c -t ${CLAB_TOPO_DIR}