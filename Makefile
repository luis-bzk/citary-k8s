.PHONY: help build-images deploy-db deploy-backend-db deploy-all clean-db clean-all status logs restart-db restart-backend restart-frontend restart-all port-forward

# Default target
help:
	@echo "Citary K8s Development Environment"
	@echo "================================="
	@echo ""
	@echo "Build Commands:"
	@echo "  make build-images        - Build all Docker images"
	@echo "  make build-db           - Build database image only"
	@echo "  make build-backend      - Build backend image only"
	@echo "  make build-frontend     - Build frontend image only"
	@echo ""
	@echo "Deploy Commands:"
	@echo "  make deploy-db          - Deploy database only (port 30432)"
	@echo "  make deploy-backend-db  - Deploy database and backend"
	@echo "  make deploy-all         - Deploy all components"
	@echo ""
	@echo "Clean Commands:"
	@echo "  make clean-db           - Clean database (remove volumes and rebuild)"
	@echo "  make clean-all          - Remove all deployments"
	@echo ""
	@echo "Management Commands:"
	@echo "  make status             - Show status of all deployments"
	@echo "  make logs-db            - Show database logs"
	@echo "  make logs-backend       - Show backend logs"
	@echo "  make logs-frontend      - Show frontend logs"
	@echo "  make restart-db         - Restart database"
	@echo "  make restart-backend    - Restart backend"
	@echo "  make restart-frontend   - Restart frontend"
	@echo "  make restart-all        - Restart all components"
	@echo ""
	@echo "Access Commands:"
	@echo "  make port-forward       - Forward ports for local access"
	@echo "  make port-forward-db    - Forward database port (5432)"

# Build all images
build-images: build-db build-backend build-frontend
	@echo "All images built successfully"

# Build individual images
build-db:
	@echo "Building database image..."
	@cd database && docker build -t citary-database:latest .

build-backend:
	@echo "Building backend image..."
	@cd ../citary-backend && docker build -t citary-backend:latest .

build-frontend:
	@echo "Building frontend image..."
	@cd ../citary-frontend && docker build -t citary-frontend:latest .

# Deploy database only
deploy-db: build-db
	@echo "Deploying database..."
	@kubectl apply -f manifests/namespace.yaml
	@kubectl apply -f manifests/secret.yaml
	@kubectl apply -f manifests/database/pvc.yaml
	@kubectl apply -f manifests/database/deployment.yaml
	@kubectl apply -f manifests/database/service.yaml
	@echo ""
	@echo "✓ Database deployed!"
	@echo "Database URL: localhost:30432"
	@echo "Credentials: root/root"

# Deploy database and backend
deploy-backend-db: build-db build-backend
	@echo "Deploying database and backend..."
	@kubectl apply -f manifests/namespace.yaml
	@kubectl apply -f manifests/configmap.yaml
	@kubectl apply -f manifests/secret.yaml
	@kubectl apply -f manifests/database/pvc.yaml
	@kubectl apply -f manifests/database/deployment.yaml
	@kubectl apply -f manifests/database/service.yaml
	@kubectl apply -f manifests/backend/deployment.yaml
	@kubectl apply -f manifests/backend/service.yaml
	@echo ""
	@echo "✓ Database and Backend deployed!"
	@echo "Backend URL:  http://localhost:30001"
	@echo "Database URL: localhost:30432"

# Deploy all components
deploy-all: build-images
	@echo "Deploying all components..."
	@kubectl apply -f manifests/namespace.yaml
	@kubectl apply -f manifests/configmap.yaml
	@kubectl apply -f manifests/secret.yaml
	@kubectl apply -f manifests/database/pvc.yaml
	@kubectl apply -f manifests/database/deployment.yaml
	@kubectl apply -f manifests/database/service.yaml
	@kubectl apply -f manifests/backend/deployment.yaml
	@kubectl apply -f manifests/backend/service.yaml
	@kubectl apply -f manifests/frontend/deployment.yaml
	@kubectl apply -f manifests/frontend/service.yaml
	@echo ""
	@echo "✓ All components deployed!"
	@echo "Frontend URL:  http://localhost:30173"
	@echo "Backend URL:   http://localhost:30001"
	@echo "Database URL:  localhost:30432"
	@echo ""
	@echo "Database credentials: root/root"

# Clean database (remove volumes and rebuild)
clean-db:
	@echo "Cleaning database..."
	@kubectl delete -n citary deployment postgres --ignore-not-found=true
	@kubectl delete -n citary service postgres-service --ignore-not-found=true
	@kubectl delete -n citary pvc postgres-pvc --ignore-not-found=true
	@echo "Waiting for resources to be deleted..."
	@sleep 10
	@echo "Verifying PVC is deleted..."
	@kubectl wait --for=delete pvc/postgres-pvc -n citary --timeout=60s 2>/dev/null || true
	@echo "Rebuilding database image..."
	@cd database && docker build -t citary-database:latest .
	@echo "Redeploying database..."
	@kubectl apply -f manifests/namespace.yaml
	@kubectl apply -f manifests/secret.yaml
	@kubectl apply -f manifests/database/pvc.yaml
	@kubectl apply -f manifests/database/deployment.yaml
	@kubectl apply -f manifests/database/service.yaml
	@echo "Waiting for database to be ready..."
	@kubectl wait --for=condition=ready pod -l app=postgres -n citary --timeout=120s
	@echo "Database cleaned and redeployed successfully!"

# Remove all deployments
clean-all:
	@echo "Removing all deployments..."
	@kubectl delete namespace citary --ignore-not-found=true
	@echo "Namespace and all resources deleted"

# Show status of all deployments
status:
	@echo "=== Namespace Status ==="
	@kubectl get namespace citary --ignore-not-found=true
	@echo ""
	@echo "=== Deployments ==="
	@kubectl get deployments -n citary
	@echo ""
	@echo "=== Pods ==="
	@kubectl get pods -n citary
	@echo ""
	@echo "=== Services ==="
	@kubectl get services -n citary
	@echo ""
	@echo "=== PVCs ==="
	@kubectl get pvc -n citary

# Show logs
logs-db:
	@kubectl logs -n citary -l app=postgres -f

logs-backend:
	@kubectl logs -n citary -l app=backend -f

logs-frontend:
	@kubectl logs -n citary -l app=frontend -f

# Restart deployments
restart-db:
	@echo "Restarting database..."
	@kubectl rollout restart deployment postgres -n citary

restart-backend:
	@echo "Restarting backend..."
	@kubectl rollout restart deployment backend -n citary

restart-frontend:
	@echo "Restarting frontend..."
	@kubectl rollout restart deployment frontend -n citary

restart-all: restart-db restart-backend restart-frontend
	@echo "All components restarted"

# Port forwarding for local access
port-forward:
	@echo "Starting port forwarding..."
	@echo "Backend will be available at: http://localhost:3001"
	@echo "Frontend will be available at: http://localhost:5173"
	@echo "Press Ctrl+C to stop"
	@kubectl port-forward -n citary service/backend-service 3001:3001 & \
	kubectl port-forward -n citary service/frontend-service 5173:5173

port-forward-db:
	@echo "Starting database port forwarding..."
	@echo "Database will be available at: localhost:5432"
	@echo "Press Ctrl+C to stop"
	@kubectl port-forward -n citary service/postgres-service 5432:5432

# Quick development commands
dev-db: deploy-db port-forward-db

dev-backend: deploy-backend-db
	@echo "Starting backend port forwarding..."
	@kubectl port-forward -n citary service/backend-service 3001:3001

dev-all: deploy-all port-forward

# Database management
db-shell:
	@echo "Connecting to database shell..."
	@kubectl exec -it -n citary deployment/postgres -- psql -U root -d my_database_pg

# Health checks
health-check:
	@echo "Checking health of all components..."
	@echo ""
	@echo "=== Database ==="
	@kubectl exec -n citary deployment/postgres -- pg_isready -U root || echo "Database not ready"
	@echo ""
	@echo "=== Pods Status ==="
	@kubectl get pods -n citary