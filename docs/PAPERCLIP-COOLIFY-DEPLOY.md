# Deploy de Paperclip en Coolify

**Fecha:** 2026-03-23  
**PostgreSQL existente:** paperclip-db (Coolify)

---

## Paso 1: Crear Base de Datos para Paperclip

Tu PostgreSQL está conectado a la DB "postgres" por defecto. Paperclip necesita su propia DB.

### Opción A: Via Coolify UI

1. Ir a recurso `paperclip-db`
2. Ejecutar query SQL (si Coolify lo permite)
3. Crear DB "paperclip"

### Opción B: Via SSH (Recomendado)

```bash
# SSH a tu VPS
ssh root@tu-vps

# Crear base de datos
docker exec -it paperclip-db psql -U lolo -d postgres -c "CREATE DATABASE paperclip;"

# Verificar
docker exec -it paperclip-db psql -U lolo -d postgres -c "\l"
```

Deberías ver:
```
   name    | owner
-----------+-------
 postgres  | lolo
 paperclip | lolo  ← nueva
```

---

## Paso 2: Preparar docker-compose para Coolify

### Archivo: docker-compose.coolify.yml

```yaml
version: '3.8'

services:
  paperclip:
    image: ghcr.io/paperclipai/paperclip:latest
    container_name: paperclip
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://lolo:iCxXchzXYtC7hqEn26S9rfMWZvVeZuw4cR53ORNX8Spv7EGFVJfK52iUs0B07Ag6@b10e104vfb7gy490xknu8743:5432/paperclip
      - SESSION_SECRET=${SESSION_SECRET}
      - PORT=3100
      - HOST=0.0.0.0
    networks:
      - coolify
    labels:
      - "coolify.managed=true"
      - "traefik.enable=true"
      - "traefik.http.routers.paperclip.rule=Host(`paperclip.tudominio.com`)"
      - "traefik.http.routers.paperclip.entrypoints=websecure"
      - "traefik.http.routers.paperclip.tls=true"
      - "traefik.http.routers.paperclip.tls.certresolver=letsencrypt"
      - "traefik.http.services.paperclip.loadbalancer.server.port=3100"
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3100/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  coolify:
    external: true
```

---

## Paso 3: Generar SESSION_SECRET

```bash
# En tu VPS
openssl rand -base64 32
```

Ejemplo: `Kj8mN2pQ7vR3xY5zA9bC4dE6fG0hI1jK==`

---

## Paso 4: Deploy en Coolify

### Opción A: Desde Git (Recomendado para updates)

1. Fork de https://github.com/paperclipai/paperclip
2. En Coolify: New Resource → Application → GitHub
3. Seleccionar tu fork
4. Configurar:
   - Build Pack: Nixpacks
   - Variables de entorno:
     ```
     DATABASE_URL=postgres://lolo:iCxXchzXYtC7hqEn26S9rfMWZvVeZuw4cR53ORNX8Spv7EGFVJfK52iUs0B07Ag6@b10e104vfb7gy490xknu8743:5432/paperclip
     SESSION_SECRET=[tu-secret-generado]
     NODE_ENV=production
     ```
   - Dominio: `paperclip.tudominio.com`

### Opción B: Desde Docker Compose

1. En Coolify: New Resource → Docker Compose
2. Pegar el contenido de `docker-compose.coolify.yml`
3. Añadir variable `SESSION_SECRET`
4. Configurar dominio
5. Deploy

---

## Paso 5: Configurar Dominio

### DNS
```
Tipo:  A
Nombre: paperclip
Valor: [IP de tu VPS]
```

### Coolify
En el recurso Paperclip:
- Domain: `paperclip.tudominio.com`
- SSL: Let's Encrypt (automático)

---

## Paso 6: Verificar Deploy

### 6.1 Logs
```bash
# Ver logs
docker logs -f paperclip

# Esperar mensaje:
# "Server listening on http://0.0.0.0:3100"
```

### 6.2 Health Check
```bash
curl https://paperclip.tudominio.com/health
# Debe devolver: {"status":"ok"}
```

### 6.3 Primera Carga
```
https://paperclip.tudominio.com
```

Deberías ver el onboarding de Paperclip.

---

## Paso 7: Onboarding Inicial

Paperclip te guiará para:

1. **Crear usuario admin**
   - Email
   - Contraseña

2. **Crear primera "company"**
   - Nombre: "Lienzolabs" o "Mi Agencia"
   - Objetivo: "Servicios SEO y desarrollo para clientes locales"

3. **Añadir primer agente**
   - Empezar con CEO/Coordinador

---

## Variables de Entorno Completa

```bash
# Base de datos
DATABASE_URL=postgres://lolo:iCxXchzXYtC7hqEn26S9rfMWZvVeZuw4cR53ORNX8Spv7EGFVJfK52iUs0B07Ag6@b10e104vfb7gy490xknu8743:5432/paperclip

# Seguridad
SESSION_SECRET=[generar-con-openssl]

# Entorno
NODE_ENV=production
PORT=3100
HOST=0.0.0.0

# Opcionales (GitHub OAuth)
# GITHUB_CLIENT_ID=tu-client-id
# GITHUB_CLIENT_SECRET=tu-client-secret
```

---

## Troubleshooting

### Error: "Cannot connect to database"

```bash
# Verificar que la DB existe
docker exec -it paperclip-db psql -U lolo -d postgres -c "\l"

# Si no existe "paperclip", crearla
docker exec -it paperclip-db psql -U lolo -d postgres -c "CREATE DATABASE paperclip;"

# Verificar conexión desde contenedor Paperclip
docker exec -it paperclip sh -c "nc -zv b10e104vfb7gy490xknu8743 5432"
```

### Error: "Session secret not set"

```bash
# Verificar variable
docker exec -it paperclip printenv SESSION_SECRET

# Si está vacía, añadir en Coolify y redeploy
```

### Error: "Port 3100 not accessible"

```bash
# Verificar que Traefik está configurado
docker logs traefik 2>&1 | grep paperclip

# Verificar labels del contenedor
docker inspect paperclip | grep -A20 Labels
```

### Paperclip no inicia

```bash
# Ver logs detallados
docker logs paperclip --tail 100

# Reconstruir
docker-compose down
docker-compose up -d --force-recreate
```

---

## Comandos Útiles

```bash
# Logs en tiempo real
docker logs -f paperclip

# Reiniciar
docker restart paperclip

# Ver estado
docker ps | grep paperclip

# Entrar al contenedor
docker exec -it paperclip sh

# Ver variables de entorno
docker exec paperclip printenv

# Backup de la DB de Paperclip
docker exec paperclip-db pg_dump -U lolo paperclip > paperclip-backup.sql
```

---

## Siguientes Pasos

Una vez Paperclip esté funcionando:

1. ✅ Completar onboarding
2. ⬜ Crear agente CEO/Coordinador
3. ⬜ Crear agente SEO Specialist
4. ⬜ Configurar heartbeats
5. ⬜ Conectar OpenClaw a Paperclip

---

## Checklist Final

| Paso | Estado |
|------|--------|
| Base de datos "paperclip" creada | ⬜ |
| SESSION_SECRET generado | ⬜ |
| Dominio DNS configurado | ⬜ |
| Deploy en Coolify | ⬜ |
| SSL funcionando | ⬜ |
| Health check OK | ⬜ |
| Onboarding completado | ⬜ |

---

*Documento creado por Taya (OpenClaw) - 2026-03-23*
