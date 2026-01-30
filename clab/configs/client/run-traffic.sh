#!/usr/bin/env bash
# Copyright 2024 Nokia
# Licensed under the BSD 3-Clause License.
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

# ====== USER INPUT ======
# Usage: ./run_iperf.sh <DURATION_IN_SECONDS>
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <iperf_duration_seconds>"
  exit 1
fi

USER_INPUT="$1"

SERVER_IP="1.1.1.1"
SERVER_PORT="5201"

# ====== GET CONTAINER IDS ======
get_container_id() {
  docker ps -q --filter "name=$1" | head -n 1
}

CLIENT1_ID=$(get_container_id "client1")
CLIENT3_ID=$(get_container_id "client3")
CLIENT4_ID=$(get_container_id "client4")
CLIENT5_ID=$(get_container_id "client5")

for c in CLIENT1_ID CLIENT3_ID CLIENT4_ID CLIENT5_ID; do
  if [[ -z "${!c}" ]]; then
    echo "Error: Could not find container for $c"
    exit 1
  fi
done

echo "client1: $CLIENT1_ID"
echo "client3: $CLIENT3_ID"
echo "client4: $CLIENT4_ID"
echo "client5: $CLIENT5_ID"

# ====== START IPERF2 SERVERS IF NOT RUNNING ======
start_iperf_server() {
  local cid="$1"

  if docker exec "$cid" pgrep -x iperf >/dev/null 2>&1; then
    echo "iperf server already running in container $cid"
  else
    echo "Starting iperf server in container $cid"
    docker exec -d "$cid" \
      iperf -s -B "$SERVER_IP" -p "$SERVER_PORT"
  fi
}

start_iperf_server "$CLIENT1_ID"
start_iperf_server "$CLIENT3_ID"
start_iperf_server "$CLIENT4_ID"

# ====== START IPERF FLOWS FROM CLIENT5 ======
echo "Starting iperf flows from client5..."

docker exec "$CLIENT5_ID" bash -c "
for i in \$(seq 1 50); do
  iperf -c $SERVER_IP -u -b 50k -t $USER_INPUT -p $SERVER_PORT -B 20.40.1.1 &
  iperf -c $SERVER_IP -u -b 50k -t $USER_INPUT -p $SERVER_PORT -B 20.40.2.1 &
done
wait
"

echo "All iperf flows completed."

