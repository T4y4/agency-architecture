# Configuración MCP de Coolify en OpenClaw

**Fecha:** 2026-03-23  
**MCP Server:** `@masonator/coolify-mcp`  
**Repositorio:** https://github.com/StuMason/coolify-mcp  
**Herramientas:** 38 herramientas optimizadas

---

## Resumen

Este documento explica cómo configurar el MCP server de Coolify en OpenClaw para poder gestionar tu instancia de Coolify directamente desde el agente.

---

## Prerrequisitos

### 1. API Token de Coolify

Necesitas generar un token de API en tu instancia de Coolify:

1. Acceder a tu Coolify: `https://coolify.tudominio.com`
2. Ir a **Settings → API**
3. Click en **Generate Token**
4. Guardar el token (no se volverá a mostrar)

### 2. URL de Coolify

Tu instancia de Coolify, por ejemplo:
- `https://coolify.tudominio.com`
- `http://192.168.1.100:3000` (si es local)

---

## Configuración en OpenClaw

### Método 1: Edición Manual de openclaw.json

Añadir la sección `mcpServers` a tu `/data/.openclaw/openclaw.json`:

```json
{
  "mcpServers": {
    "coolify": {
      "command": "npx",
      "args": ["-y", "@masonator/coolify-mcp@latest"],
      "env": {
        "COOLIFY_ACCESS_TOKEN": "tu-api-token-de-coolify",
        "COOLIFY_BASE_URL": "https://coolify.tudominio.com"
      }
    }
  }
}
```

### Método 2: CLI de OpenClaw (Recomendado)

```bash
# Instalar MCP de Coolify
openclaw mcp install coolify \
  -e COOLIFY_BASE_URL="https://coolify.tudominio.com" \
  -e COOLIFY_ACCESS_TOKEN="tu-api-token-de-coolify" \
  -- npx @masonator/coolify-mcp@latest
```

### Método 3: Config File Separado

Crear archivo `/data/.openclaw/mcp.json`:

```json
{
  "mcpServers": {
    "coolify": {
      "command": "npx",
      "args": ["-y", "@masonator/coolify-mcp@latest"],
      "env": {
        "COOLIFY_ACCESS_TOKEN": "tu-api-token",
        "COOLIFY_BASE_URL": "https://coolify.tudominio.com"
      }
    }
  }
}
```

---

## Variables de Entorno

| Variable | Requerida | Descripción |
|----------|-----------|-------------|
| `COOLIFY_ACCESS_TOKEN` | ✅ Sí | Token de API de Coolify |
| `COOLIFY_BASE_URL` | ✅ Sí | URL de tu instancia Coolify |

---

## Reiniciar OpenClaw

Después de configurar, reiniciar el gateway:

```bash
openclaw gateway restart
```

---

## Verificar Instalación

### 1. Listar Herramientas Disponibles

Preguntar al agente:
```
¿Qué herramientas MCP de Coolify tienes disponibles?
```

### 2. Probar Overview

```
Dame un overview de mi infraestructura en Coolify
```

### 3. Listar Aplicaciones

```
Lista todas las aplicaciones en Coolify
```

---

## 38 Herramientas Disponibles

### Infraestructura

| Herramienta | Descripción |
|-------------|-------------|
| `get_infrastructure_overview` | Vista general de toda la infra |
| `get_mcp_version` | Versión del MCP server |
| `get_version` | Versión de Coolify API |

### Diagnóstico

| Herramienta | Descripción |
|-------------|-------------|
| `diagnose_app` | Diagnóstico completo de una app |
| `diagnose_server` | Diagnóstico de servidor |
| `find_issues` | Escanear infra por problemas |

### Batch Operations

| Herramienta | Descripción |
|-------------|-------------|
| `restart_project_apps` | Reiniciar todas las apps de un proyecto |
| `bulk_env_update` | Actualizar env vars en batch |
| `stop_all_apps` | Parar todas las apps |
| `redeploy_project` | Redeploy todo un proyecto |

### Servers

| Herramienta | Descripción |
|-------------|-------------|
| `list_servers` | Listar servidores |
| `get_server` | Detalles de servidor |
| `validate_server` | Validar conexión |
| `server_resources` | Recursos en servidor |
| `server_domains` | Dominios configurados |

### Projects & Environments

| Herramienta | Descripción |
|-------------|-------------|
| `projects` | CRUD de proyectos |
| `environments` | CRUD de entornos |

### Applications

| Herramienta | Descripción |
|-------------|-------------|
| `list_applications` | Listar apps |
| `get_application` | Detalles de app |
| `application` | CRUD de apps |
| `application_logs` | Ver logs |
| `control` | Start/stop/restart |
| `env_vars` | Gestionar variables |
| `deploy` | Desplegar app |

### Databases

| Herramienta | Descripción |
|-------------|-------------|
| `list_databases` | Listar DBs |
| `get_database` | Detalles de DB |
| `database` | Crear/eliminar DB |
| `database_backups` | Gestionar backups |

### Services

| Herramienta | Descripción |
|-------------|-------------|
| `list_services` | Listar servicios |
| `get_service` | Detalles de servicio |
| `service` | CRUD de servicios |

### Deployments

| Herramienta | Descripción |
|-------------|-------------|
| `list_deployments` | Listar deploys |
| `deploy` | Ejecutar deploy |
| `deployment` | Detalles de deploy |

### Otros

| Herramienta | Descripción |
|-------------|-------------|
| `private_keys` | Gestionar claves SSH |
| `github_apps` | Gestionar GitHub Apps |
| `teams` | Gestionar equipos |
| `cloud_tokens` | Tokens de cloud providers |
| `search_docs` | Buscar en docs de Coolify |

---

## Ejemplos de Uso

### Ver Overview Completo

```
Dame un overview de toda mi infraestructura en Coolify
```

### Diagnosticar App

```
Diagnostica la aplicación "paperclip" en Coolify
```

### Ver Logs de App

```
Muéstrame los logs de la aplicación paperclip
```

### Reiniciar App

```
Reinicia la aplicación paperclip
```

### Listar DBs

```
Lista todas las bases de datos en Coolify
```

### Deploy con Force Rebuild

```
Despliega la aplicación paperclip con force rebuild
```

### Crear Nueva App

```
Crea una nueva aplicación llamada "test-app" en el proyecto "default"
```

### Actualizar Variable de Entorno

```
Actualiza la variable DATABASE_URL en la aplicación paperclip
```

---

## Troubleshooting

### Error: "MCP server not found"

```bash
# Verificar configuración
cat /data/.openclaw/openclaw.json | grep -A10 mcpServers

# Reiniciar gateway
openclaw gateway restart
```

### Error: "Authentication failed"

Verificar que:
- El token de Coolify es correcto
- El token no ha expirado
- La URL de Coolify es correcta

### Error: "Connection refused"

Verificar que:
- Coolify está accesible
- La URL es correcta
- No hay firewall bloqueando

### Error: "npx not found"

```bash
# Instalar npx si no existe
npm install -g npx
```

---

## Ventajas del MCP de Coolify

1. **Optimizado para tokens:** 85% menos tokens que implementación naive
2. **Respuestas sumarizadas:** List operations devuelven resúmenes
3. **Acciones contextuales:** Sugiere próximos pasos
4. **Paginación:** Soporta grandes deployments
5. **Búsqueda en docs:** `search_docs` busca en documentación de Coolify

---

## Seguridad

**⚠️ IMPORTANTE:**

- El token de Coolify tiene acceso completo a tu instancia
- NO commitear el token a repositorios
- Usar variables de entorno
- Considerar usar tokens con permisos limitados si es posible

---

## Siguientes Pasos

Una vez configurado:

1. **Verificar conexión:**
   ```
   ¿Qué aplicaciones tengo en Coolify?
   ```

2. **Diagnosticar infra:**
   ```
   Busca problemas en mi infraestructura de Coolify
   ```

3. **Gestionar deployments:**
   ```
   Despliega la última versión de paperclip
   ```

4. **Ver logs:**
   ```
   Muéstrame los logs de paperclip de los últimos 10 minutos
   ```

---

*Documento creado por Taya (OpenClaw) - 2026-03-23*
