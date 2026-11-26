#!/data/data/com.termux/files/usr/bin/bash
# Valkyrie Jarvis - Tesla Fleet API partner registration, run on Wolfgang's phone.
# Talks only to Tesla's own addresses. Saves nothing. The client secret is typed
# at a hidden prompt, used once to get a partner token, and never printed.
# The partner token is never printed either.

AUTH_URL="https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"
API="https://fleet-api.prd.na.vn.cloud.tesla.com"
DOMAIN="adamwoodworth82-spec.github.io"
DEFAULT_ID="0382250d-d12d-4e5f-a1af-bc3b8078b8cb"

echo "=== Valkyrie Jarvis - register with Tesla ==="
echo

if ! command -v curl >/dev/null 2>&1; then
  echo "Installing curl first (one-time)..."
  pkg install -y curl || { echo "curl install failed - tell Jarvis."; exit 1; }
fi

printf "Client ID [%s]: " "$DEFAULT_ID"
read -r CLIENT_ID
if [ -z "$CLIENT_ID" ]; then CLIENT_ID="$DEFAULT_ID"; fi

printf "Client Secret (typing is hidden - paste it, then press Enter): "
read -rs CLIENT_SECRET
echo
if [ -z "$CLIENT_SECRET" ]; then
  echo "No secret entered. Nothing was sent. Run it again when ready."
  exit 1
fi

echo
echo "Step 1 of 3: asking Tesla for a partner token..."
RESP=$(curl -s -w $'\n%{http_code}' -X POST "$AUTH_URL" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "client_secret=$CLIENT_SECRET" \
  --data-urlencode "audience=$API" \
  --data-urlencode "scope=openid vehicle_device_data vehicle_cmds vehicle_charging_cmds")
CODE=$(printf '%s' "$RESP" | tail -n 1)
BODY=$(printf '%s' "$RESP" | sed -e '$d')
CLIENT_SECRET=""
TOKEN=$(printf '%s' "$BODY" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
if [ -z "$TOKEN" ]; then
  echo "It did not work at step 1. Tesla answered HTTP $CODE:"
  printf '%s' "$BODY" | sed -n 's/.*"error_description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/Error: \1/p'
  printf '%s' "$BODY" | sed -n 's/.*"error"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/Error code: \1/p'
  echo "Tell Jarvis that wording."
  exit 1
fi
echo "Partner token received."

echo
echo "Step 2 of 3: registering your app with Tesla..."
RESP=$(curl -s -w $'\n%{http_code}' -X POST "$API/api/1/partner_accounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"domain\": \"$DOMAIN\"}")
CODE=$(printf '%s' "$RESP" | tail -n 1)
BODY=$(printf '%s' "$RESP" | sed -e '$d')
echo "Tesla answered HTTP $CODE:"
echo "$BODY"
if [ "$CODE" != "200" ] && [ "$CODE" != "201" ]; then
  echo
  echo "Registration did not go through - tell Jarvis the HTTP number and wording above."
  TOKEN=""
  exit 1
fi

echo
echo "Step 3 of 3: checking Tesla can see your public key..."
RESP=$(curl -s -w $'\n%{http_code}' "$API/api/1/partner_accounts/public_key?domain=$DOMAIN" \
  -H "Authorization: Bearer $TOKEN")
CODE=$(printf '%s' "$RESP" | tail -n 1)
BODY=$(printf '%s' "$RESP" | sed -e '$d')
TOKEN=""
echo "Tesla answered HTTP $CODE:"
echo "$BODY"

echo
echo "=== Done. Tell Jarvis the HTTP numbers from steps 2 and 3. ==="
echo "Nothing on this screen is secret - it is safe to screenshot for Jarvis."
