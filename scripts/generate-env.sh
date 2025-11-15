#!/bin/bash

# Script to generate Kubernetes ConfigMap and Secret from .env file
# Usage: ./scripts/generate-env.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

echo -e "${YELLOW}Loading environment variables from .env...${NC}"

# Source the .env file
set -a
source "$ENV_FILE"
set +a

# Generate Secret (for DATABASE_URL and sensitive data)
echo -e "${GREEN}Generating Secret...${NC}"
kubectl create secret generic citary-secret \
    --from-literal=DATABASE_URL="$DATABASE_URL" \
    --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD" \
    --from-literal=SMTP_USERNAME="$SMTP_USERNAME" \
    --from-literal=SMTP_PASSWORD="$SMTP_PASSWORD" \
    --namespace=citary \
    --dry-run=client -o yaml > "$PROJECT_DIR/manifests/secret.yaml"

# Generate ConfigMap (for non-sensitive configuration)
echo -e "${GREEN}Generating ConfigMap...${NC}"
kubectl create configmap citary-config \
    --from-literal=PORT="$PORT" \
    --from-literal=SMTP_HOST="$SMTP_HOST" \
    --from-literal=SMTP_PORT="$SMTP_PORT" \
    --from-literal=SMTP_FROM_EMAIL="$SMTP_FROM_EMAIL" \
    --from-literal=SMTP_FROM_NAME="$SMTP_FROM_NAME" \
    --from-literal=FRONTEND_URL="$FRONTEND_URL" \
    --namespace=citary \
    --dry-run=client -o yaml > "$PROJECT_DIR/manifests/configmap.yaml"

echo -e "${GREEN}✓ ConfigMap and Secret generated successfully!${NC}"
echo -e "Files created:"
echo -e "  - manifests/configmap.yaml"
echo -e "  - manifests/secret.yaml"
