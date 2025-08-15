# Troubleshooting Guide

## Kubernetes is not running

Si recibes el error:
```
dial tcp 127.0.0.1:6443: connectex: No connection could be made because the target machine actively refused it.
```

### Solución:

1. **Habilitar Kubernetes en Docker Desktop:**
   - Abre Docker Desktop
   - Ve a Settings (Configuración) → Kubernetes
   - Marca la casilla "Enable Kubernetes"
   - Haz clic en "Apply & Restart"
   - Espera a que el indicador de Kubernetes esté verde (puede tomar varios minutos)

2. **Verificar que Kubernetes esté funcionando:**
   ```bash
   make check-k8s
   ```
   
   O directamente:
   ```bash
   kubectl version
   kubectl get nodes
   ```

3. **Si Kubernetes sigue sin funcionar:**
   - Reinicia Docker Desktop completamente
   - En Windows, puedes necesitar reiniciar el servicio de Docker:
     ```powershell
     # Como administrador
     Restart-Service docker
     ```

## La imagen no se construye

Si recibes advertencias sobre secretos en el Dockerfile:
```
SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
```

Esta es solo una advertencia. Las credenciales de la base de datos están hardcodeadas porque es solo para desarrollo local.

## Los pods no inician

1. **Verificar el estado:**
   ```bash
   make status
   ```

2. **Ver logs:**
   ```bash
   make logs-db
   make logs-backend
   ```

3. **Verificar que las imágenes existan:**
   ```bash
   docker images | grep citary
   ```

## Puerto ya en uso

Si recibes un error de que el puerto está en uso:

1. **Para Windows, encuentra qué está usando el puerto:**
   ```powershell
   netstat -ano | findstr :3001
   netstat -ano | findstr :5173
   netstat -ano | findstr :5432
   ```

2. **Detén el proceso o cambia el puerto en el ConfigMap**

## Base de datos no conecta

1. **Verifica que el pod esté corriendo:**
   ```bash
   kubectl get pods -n citary
   ```

2. **Prueba la conexión directamente:**
   ```bash
   make db-shell
   ```

3. **Verifica los logs:**
   ```bash
   make logs-db
   ```

## Limpiar todo y empezar de nuevo

Si necesitas empezar desde cero:
```bash
make clean-all
make deploy-all
```