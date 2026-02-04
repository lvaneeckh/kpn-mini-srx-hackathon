#!/bin/bash

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
export FILE=./Ingress-Traffic.json

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
echo $AUTH_RESP
echo $AUTH_TOKEN

curl -sk  https://${EDA_URL}:9443/core/user-storage/v2/shared/file?path=%2Fdesigns%2FIngress-Traffic-1.json \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    --data @"$FILE"