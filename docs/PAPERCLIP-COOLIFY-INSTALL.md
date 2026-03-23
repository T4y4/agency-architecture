# Plan de Instalación de Paperclip en Coolify

**Fecha:** 2026-03-23  
**Para:** Lolo Peluzo  
**Objetivo:** Desplegar Paperclip en tu infraestructura Coolify existente

---

## Prerrequisitos

### En tu VPS (ya debería estar)
- ✅ Coolify instalado y funcionando
- ✅ Docker + Docker Compose
- ✅ Proxy reverso (Traefik/Caddy)
- ✅ Acceso SSH

### Nuevos requisitos
- ⬜ PostgreSQL 15+ (base de datos dedicada)
- ⬜ Dominio/subdominio para Paperclip
- ⬜ Node.js 20+ (solo para build inicial, opcional)

---

## Arquitectura del Deploy

```
┌─────────────────────────────────────────────────────────┐
│                    TU VPS (Coolify)                     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Traefik    │  │  PostgreSQL │  │  Paperclip  │     │
│  │  (proxy)    │──│  (database) │──│  (app)      │     │
│  │             │  │             │  │             │     │
│  │ :443        │  │ :5432       │  │ :3100       │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│        │                                    │           │
│        └────────────────────────────────────┘           │
│                                                         │
│  paperclip.tudominio.com ────────────► Paperclip       │
└─────────────────────────────────────────────────────────┘
```

---

## Paso 1: Preparar Dominio y DNS

### 1.1 Crear subdominio
```
Tipo:  A
Nombre: paperclip
Valor: IP_DE_TU_VPS
TTL:   300
```

**Ejemplo:** `paperclip.lienzolabs.com` → `123.45.67.89`

### 1.2 Verificar propagación
```bash
dig paperclip.tudominio.com
# Debe resolver a tu IP
```

---

## Paso 2: Crear Base de Datos PostgreSQL

### Opción A: Usar PostgreSQL de Coolify (Recomendado)

1. En Coolify dashboard → **New Resource** → **Database**
2. Seleccionar **PostgreSQL**
3. Configurar:
   ```
   Name:         paperclip-db
   Database:     paperclip
   Username:     paperclip
   Password:     [generar contraseña segura]
   ```
4. Click **Deploy**

5. Anotar la connection string:
   ```
   postgresql://paperclip:PASSWORD@paperclip-db:5432/paperclip
   ```

### Opción B: PostgreSQL externo (Railway, Supabase, Neon)

Si prefieres DB gestionada:
```bash
# En Supabase/Railway, crear proyecto PostgreSQL
# Obtener connection string:
postgresql://user:pass@host.supabase.co:5432/postgres
```

---

## Paso 3: Preparar Repositorio

### 3.1 Clonar y personalizar (local o en VPS)

```bash
# En tu máquina local o en el VPS
cd /tmp
git clone https://github.com/paperclipai/paperclip.git
cd paperclip
```

### 3.2 Crear docker-compose para Coolify

Crear archivo `docker-compose.coolify.yml`:

```yaml
version: '3.8'

services:
  paperclip:
    image: node:20-alpine
    container_name: paperclip-app
    working_dir: /app
    command: sh -c "corepack enable && pnpm install && pnpm db:migrate && pnpm start"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - SESSION_SECRET=${SESSION_SECRET}
      - PORT=3100
      - HOST=0.0.0.0
    volumes:
      - ./:/app
      - paperclip-data:/app/data
    networks:
      - coolify
    labels:
      - "coolify.managed=true"
      - "traefik.enable=true"
      - "traefik.http.routers.paperclip.rule=Host(`paperclip.tudominio.com`)"
      - "traefik.http.routers.paperclip.entrypoints=websecure"
      - "traefik.http.routers.paperclip.tls=true"
      - "traefik.http.services.paperclip.loadbalancer.server.port=3100"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3100/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  paperclip-data:

networks:
  coolify:
    external: true
```

### 3.3 Crear archivo .env

```bash
# .env (NO commitear a git)
DATABASE_URL=postgresql://paperclip:PASSWORD@paperclip-db:5432/paperclip
SESSION_SECRET=tu-secreto-muy-seguro-de-32-caracteres-minimo
NODE_ENV=production
```

**Generar SESSION_SECRET:**
```bash
openssl rand -base64 32
```

---

## Paso 4: Preparar Build de Producción

### 4.1 Build local (recomendado para primera vez)

```bash
# En tu máquina local con Node 20+
cd /tmp/paperclip

# Instalar dependencias
corepack enable
pnpm install

# Build de producción
pnpm build

# El resultado estará en:
# - apps/web/dist/  (frontend)
# - apps/server/dist/  (backend)
```

### 4.2 Crear Dockerfile optimizado

Crear `Dockerfile.production`:

```dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Instalar pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copiar archivos de dependencias
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/server/package.json ./apps/server/
COPY apps/web/package.json ./apps/web/
COPY packages ./packages

# Instalar dependencias
RUN pnpm install --frozen-lockfile

# Copiar código fuente
COPY . .

# Build
RUN pnpm build

# Imagen de producción
FROM node:20-alpine

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

# Copiar solo lo necesario
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/pnpm-workspace.yaml ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/server ./apps/server
COPY --from=builder /app/apps/web ./apps/web
COPY --from=builder /app/packages ./packages

# Crear directorio de datos
RUN mkdir -p /app/data

EXPOSE 3100

CMD ["pnpm", "start"]
```

---

## Paso 5: Desplegar en Coolify

### 5.1 Método 1: Deploy desde Git (Recomendado)

1. **Fork del repositorio** a tu cuenta de GitHub:
   ```bash
   # En GitHub, fork de:
   https://github.com/paperclipai/paperclip
   # A:
   https://github.com/LoloPeluzo/paperclip
   ```

2. **En Coolify Dashboard:**
   - New Resource → Application
   - Source: GitHub
   - Repository: `LoloPeluzo/paperclip`
   - Branch: `main`

3. **Configurar Build:**
   ```
   Build Pack:    Nixpacks (detecta Node.js automáticamente)
   Dockerfile:    Dockerfile.production
   ```

4. **Variables de entorno:**
   ```
   DATABASE_URL=postgresql://paperclip:PASSWORD@paperclip-db:5432/paperclip
   SESSION_SECRET=tu-secreto-seguro
   NODE_ENV=production
   ```

5. **Dominio:**
   ```
   paperclip.tudominio.com
   ```

6. **Deploy**

### 5.2 Método 2: Deploy desde Docker Compose

1. **Subir archivos a Coolify:**
   - En Coolify → New Resource → Docker Compose
   - Pegar contenido de `docker-compose.coolify.yml`

2. **Configurar variables:**
   ```
   DATABASE_URL=postgresql://...
   SESSION_SECRET=...
   ```

3. **Deploy**

---

## Paso 6: Ejecutar Migraciones de BD

### 6.1 Primera vez (inicializar esquema)

Si usas el Dockerfile de arriba, las migraciones se ejecutan automáticamente.

Si necesitas ejecutar manualmente:

```bash
# Entrar al contenedor
docker exec -it paperclip-app sh

# Ejecutar migraciones
pnpm db:migrate

# Salir
exit
```

### 6.2 Verificar tablas creadas

```bash
# Conectar a PostgreSQL
docker exec -it paperclip-db psql -U paperclip -d paperclip

# Listar tablas
\dt

# Deberías ver tablas como:
# - companies
# - agents
# - tasks
# - tickets
# - etc.

\q
```

---

## Paso 7: Configurar Proxy y SSL

### 7.1 Coolify hace esto automáticamente

Si configuraste el dominio en Coolify:
- ✅ Traefik configura el virtual host
- ✅ Let's Encrypt genera certificado SSL
- ✅ HTTPS redirige automáticamente

### 7.2 Verificar

```bash
curl -I https://paperclip.tudominio.com
# Debe devolver 200 OK
```

---

## Paso 8: Primer Acceso y Onboarding

### 8.1 Abrir Paperclip

```
https://paperclip.tudominio.com
```

### 8.2 Onboarding inicial

Paperclip te guiará para:
1. Crear usuario admin
2. Configurar primer "company"
3. Añadir primer agente
4. Configurar heartbeat

### 8.3 Configurar autenticación (opcional)

Paperclip soporta:
- Email/password (por defecto)
- GitHub OAuth
- Google OAuth

Para GitHub OAuth:
```bash
# En GitHub Settings → OAuth Apps → New OAuth App
Application name: Paperclip
Homepage URL: https://paperclip.tudominio.com
Authorization callback URL: https://paperclip.tudominio.com/auth/github/callback

# Añadir a .env:
GITHUB_CLIENT_ID=tu-client-id
GITHUB_CLIENT_SECRET=tu-client-secret
```

---

## Paso 9: Configurar Backup

### 9.1 Backup de PostgreSQL

```bash
# Crear script de backup
cat > /root/backups/paperclip-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups/paperclip"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup de la base de datos
docker exec paperclip-db pg_dump -U paperclip paperclip > $BACKUP_DIR/paperclip_$DATE.sql

# Comprimir
gzip $BACKUP_DIR/paperclip_$DATE.sql

# Mantener solo últimos 7 días
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completado: paperclip_$DATE.sql.gz"
EOF

chmod +x /root/backups/paperclip-backup.sh
```

### 9.2 Cron job

```bash
# Editar crontab
crontab -e

# Añadir backup diario a las 3 AM
0 3 * * * /root/backups/paperclip-backup.sh >> /var/log/paperclip-backup.log 2>&1
```

---

## Paso 10: Configurar Monitoreo

### 10.1 Health check endpoint

Paperclip expone `/health` por defecto.

Verificar:
```bash
curl https://paperclip.tudominio.com/health
# Debe devolver {"status":"ok"}
```

### 10.2 Logs

```bash
# Ver logs en tiempo real
docker logs -f paperclip-app

# Ver últimos 100 logs
docker logs --tail 100 paperclip-app
```

### 10.3 Métricas (opcional)

Si tienes Uptime Kuma o similar:
- Añadir monitor para `https://paperclip.tudominio.com/health`
- Alertas si cae

---

## Checklist Final

| Paso | Estado | Notas |
|------|--------|-------|
| 1. Dominio configurado | ⬜ | `paperclip.tudominio.com` |
| 2. PostgreSQL creado | ⬜ | DB + usuario + password |
| 3. Repositorio preparado | ⬜ | Fork + Dockerfile |
| 4. Variables de entorno | ⬜ | DATABASE_URL + SESSION_SECRET |
| 5. Deploy en Coolify | ⬜ | App corriendo |
| 6. Migraciones ejecutadas | ⬜ | Tablas creadas |
| 7. SSL funcionando | ⬜ | HTTPS OK |
| 8. Primer acceso | ⬜ | Onboarding completado |
| 9. Backup configurado | ⬜ | Cron diario |
| 10. Monitoreo activo | ⬜ | Health check |

---

## Troubleshooting

### Error: "Cannot connect to database"

```bash
# Verificar que PostgreSQL está corriendo
docker ps | grep postgres

# Verificar conexión desde Paperclip
docker exec paperclip-app sh -c "nc -zv paperclip-db 5432"

# Verificar DATABASE_URL
docker exec paperclip-app printenv DATABASE_URL
```

### Error: "Session secret not set"

```bash
# Verificar variable
docker exec paperclip-app printenv SESSION_SECRET

# Si está vacía, añadirla en Coolify y redeploy
```

### Error: "Port 3100 already in use"

```bash
# Verificar qué usa el puerto
docker ps | grep 3100

# Si hay conflicto, cambiar puerto en docker-compose:
PORT=3101
```

### Paperclip no arranca

```bash
# Ver logs detallados
docker logs paperclip-app --tail 100

# Reconstruir desde cero
docker-compose down -v
docker-compose up -d --build
```

---

## Comandos Útiles

```bash
# Reiniciar Paperclip
docker restart paperclip-app

# Ver estado
docker ps | grep paperclip

# Logs en tiempo real
docker logs -f paperclip-app

# Entrar al contenedor
docker exec -it paperclip-app sh

# Backup manual
docker exec paperclip-db pg_dump -U paperclip paperclip > backup.sql

# Restaurar backup
cat backup.sql | docker exec -i paperclip-db psql -U paperclip paperclip

# Actualizar a nueva versión
cd /tmp/paperclip
git pull
docker-compose down
docker-compose up -d --build
```

---

## Siguientes Pasos (Después de Instalar)

1. **Crear primera "company"**
   - Nombre: "Lienzolabs SEO Agency"
   - Objetivo: "Servicios SEO para clientes locales"

2. **Configurar agentes**
   - CEO Agent (OpenClaw)
   - Content Writer (OpenClaw)
   - SEO Analyst (OpenClaw + SEO skill)

3. **Configurar heartbeats**
   - Content Writer: cada 4h
   - SEO Analyst: cada 8h

4. **Conectar OpenClaw**
   - Configurar adapter en Paperclip
   - Apuntar OpenClaw a Paperclip

5. **Probar flujo completo**
   - Crear tarea en Paperclip
   - Verificar que OpenClaw la recibe
   - Verificar que resultado se loguea

---

## Estimación de Tiempo

| Fase | Tiempo |
|------|--------|
| Preparación (DNS, DB) | 15 min |
| Build y configuración | 30 min |
| Deploy en Coolify | 15 min |
| Verificación y onboarding | 15 min |
| **Total** | **1-1.5 horas** |

---

## Recursos

- **Paperclip Docs:** https://paperclip.ing/docs
- **Coolify Docs:** https://coolify.io/docs
- **PostgreSQL Docker:** https://hub.docker.com/_/postgres
- **Traefik Labels:** https://doc.traefik.io/traefik/providers/docker/

---

*Plan creado por Taya (OpenClaw) - 2026-03-23*
