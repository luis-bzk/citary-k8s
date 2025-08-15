# Citary K8s Development Environment

This directory contains the Kubernetes configuration for running the Citary application in a local development environment using Docker Desktop's Kubernetes.

## Prerequisites

- Docker Desktop with Kubernetes enabled
- kubectl CLI installed
- make command available

## Project Structure

```
citary-k8s/
├── database/
│   ├── Dockerfile          # Database container definition
│   └── sql/               # SQL initialization scripts
│       ├── core.sql       # Core schema
│       ├── data.sql       # Data schema
│       ├── views.sql      # Database views
│       └── init.sql       # Initial data
├── manifests/
│   ├── namespace.yaml     # Kubernetes namespace
│   ├── configmap.yaml     # Application configuration
│   ├── secret.yaml        # Sensitive configuration
│   ├── database/          # Database manifests
│   ├── backend/           # Backend manifests
│   └── frontend/          # Frontend manifests
├── overlays/
│   ├── database-only/     # Deploy only database
│   ├── backend-db/        # Deploy database + backend
│   └── all/              # Deploy all components
└── Makefile              # Development commands
```

## Quick Start

1. **Deploy all components:**
   ```bash
   make deploy-all
   ```

2. **Access the application:**
   The services are exposed via NodePort:
   - Frontend: http://localhost:30173
   - Backend: http://localhost:30001
   - Database: localhost:30432 (user: root, password: root)

   Alternatively, use port-forwarding:
   ```bash
   make port-forward
   ```
   - Frontend: http://localhost:5173
   - Backend: http://localhost:3001
   - Database: localhost:5432

## Available Commands

### Build Commands
- `make build-images` - Build all Docker images
- `make build-db` - Build database image only
- `make build-backend` - Build backend image only
- `make build-frontend` - Build frontend image only

### Deploy Commands
- `make deploy-db` - Deploy database only (port 30432)
- `make deploy-backend-db` - Deploy database and backend
- `make deploy-all` - Deploy all components

### Management Commands
- `make status` - Show status of all deployments
- `make logs-db` - Show database logs
- `make logs-backend` - Show backend logs
- `make logs-frontend` - Show frontend logs
- `make restart-all` - Restart all components
- `make clean-db` - Clean and rebuild database
- `make clean-all` - Remove all deployments

### Development Commands
- `make dev-db` - Deploy database with port forwarding
- `make dev-backend` - Deploy backend+db with port forwarding
- `make dev-all` - Deploy everything with port forwarding
- `make db-shell` - Connect to database shell

## Common Workflows

### Starting Fresh Development Environment
```bash
# Deploy everything and forward ports
make dev-all
```

### Working on Backend Only
```bash
# Deploy database and backend
make dev-backend
```

### Resetting Database
```bash
# This will delete the database volume and recreate it
make clean-db
```

### Checking Application Status
```bash
make status
make health-check
```

## Configuration

### Environment Variables
Environment variables are managed through:
- `manifests/configmap.yaml` - Non-sensitive configuration
- `manifests/secret.yaml` - Sensitive data (passwords, keys)

### Database Credentials
- User: `root`
- Password: `root`
- Database: `my_database_pg`

## Troubleshooting

### Pods not starting
```bash
# Check pod status
make status

# Check logs
make logs-backend
make logs-db
```

### Database connection issues
```bash
# Ensure database is running
kubectl get pods -n citary

# Check database logs
make logs-db

# Test database connection
make db-shell
```

### Port already in use
If you get port binding errors, ensure no other services are using ports 3001, 5173, or 5432.

## Notes

- Images are built locally and use `imagePullPolicy: Never`
- Database data is persisted using PersistentVolumeClaim
- The namespace `citary` is used for all resources
- Services use NodePort for local development access:
  - Frontend: Port 30173
  - Backend: Port 30001
  - Database: Port 30432

## Port Summary

| Service | Internal Port | NodePort | Access URL |
|---------|--------------|----------|------------|
| Frontend | 5173 | 30173 | http://localhost:30173 |
| Backend | 3001 | 30001 | http://localhost:30001 |
| Database | 5432 | 30432 | localhost:30432 |

## Development Environment

This is a **development-only** environment. The database is intentionally exposed for easy access during development. 

**IMPORTANT**: This configuration should NEVER be used in production.