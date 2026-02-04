#!/usr/bin/env bash

islnames=("borderleaf1-ethernet-1-1" "borderleaf1-ethernet-1-31" "borderleaf1-ethernet-1-32" "borderleaf2-ethernet-1-1" "borderleaf2-ethernet-1-31" "borderleaf2-ethernet-1-32" "leaf1-ethernet-1-31" "leaf1-ethernet-1-32" "leaf2-ethernet-1-31" "leaf2-ethernet-1-32" "leaf3-ethernet-1-31" "leaf3-ethernet-1-32" "spine1-ethernet-1-1" "spine1-ethernet-1-2" "spine1-ethernet-1-3" "spine1-ethernet-1-4" "spine1-ethernet-1-5" "spine2-ethernet-1-1" "spine2-ethernet-1-2" "spine2-ethernet-1-3" "spine2-ethernet-1-4" "spine2-ethernet-1-5")

# Loop over the array and output the filled template
for ISL_RESOURCE in "${islnames[@]}"; do
  cat <<EOF
apiVersion: interfaces.eda.nokia.com/v1alpha1
kind: Interface
metadata:
  labels:
    eda.nokia.com/role: interSwitch
  name: ${ISL_RESOURCE}
  namespace: eda
spec:
  mtu: 9198
---
EOF
done