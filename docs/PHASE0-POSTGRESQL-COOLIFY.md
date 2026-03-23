# Fase 0: Fundamentos - PostgreSQL en Coolify

**Fecha:** 2026-03-23  
**Objetivo:** Configurar PostgreSQL como base de datos centralizada para la agencia IA

---

## Checklist Fase 0

| Tarea | Estado | Notas |
|-------|--------|-------|
| PostgreSQL creado en Coolify | ⬜ | |
| Base de datos "agency" creada | ⬜ | |
| Usuario "agency" con permisos | ⬜ | |
| Backups configurados | ⬜ | |
| Conexión validada desde OpenClaw | ⬜ | |
| Tablas iniciales creadas | ⬜ | |

---

## Paso 1: Crear PostgreSQL en Coolify (vía Web UI)

### 1.1 Acceder a Coolify

```
URL: https://coolify.tudominio.com
```

### 1.2 Crear Base de Datos

1. **Menu:** Resources → New Resource → Database
2. **Seleccionar:** PostgreSQL
3. **Configurar:**

```
Name:         agency-postgres
Database:     agency
Username:     agency
Password:     [generar contraseña segura - ver abajo]
Version:      16 (o la más reciente)
```

**Generar contraseña segura:**
```bash
openssl rand -base64 24
# Ejemplo: kJ8mN2pQ7vR3xY5zA9bC4dE6fG0hI1jK==
```

4. **Click:** Deploy

### 1.3 Anotar Connection Details

Después de crear, Coolify mostrará:

```
Host: agency-postgres (o IP interna)
Port: 5432
Database: agency
Username: agency
Password: [tu-contraseña]
Connection String: postgresql://agency:PASSWORD@agency-postgres:5432/agency
```

**Guardar estos datos** en un gestor de contraseñas.

---

## Paso 2: Configurar Backups Automáticos

### 2.1 En Coolify

1. **Resource:** agency-postgres → Backups
2. **Configurar:**
   ```
   Schedule: 0 3 * * *  (3 AM diario)
   Retention: 7 days
   Destination: Local storage (o S3 si tienes)
   ```

### 2.2 Verificar Backup Manual

```bash
# SSH a tu VPS
ssh root@tu-vps

# Ejecutar backup manual
docker exec agency-postgres pg_dump -U agency agency > /tmp/test-backup.sql

# Verificar contenido
head -50 /tmp/test-backup.sql
```

---

## Paso 3: Verificar Conectividad

### 3.1 Desde el VPS

```bash
# Verificar que el contenedor está corriendo
docker ps | grep postgres

# Verificar que el puerto está accesible
docker exec agency-postgres pg_isready

# Probar conexión
docker exec -it agency-postgres psql -U agency -d agency -c "SELECT version();"
```

### 3.2 Desde OpenClaw (en este contenedor)

```bash
# Instalar cliente PostgreSQL si no existe
which psql || apt-get update && apt-get install -y postgresql-client

# Probar conexión (ajustar host según tu configuración)
# Si PostgreSQL está en la red Docker de Coolify:
psql postgresql://agency:PASSWORD@agency-postgres:5432/agency -c "SELECT version();"

# Si necesitas conectar vía IP pública del VPS:
psql postgresql://agency:PASSWORD@TU_VPS_IP:5432/agency -c "SELECT version();"
```

---

## Paso 4: Crear Tablas Iniciales

### 4.1 Esquema Base

```sql
-- Conectar a la base de datos
psql postgresql://agency:PASSWORD@HOST:5432/agency

-- Tabla de clientes
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    sector VARCHAR(100),
    website VARCHAR(500),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de proyectos
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50), -- 'seo', 'web', 'automation', etc.
    status VARCHAR(50) DEFAULT 'active',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de tareas
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(20) DEFAULT 'medium',
    assigned_agent VARCHAR(100), -- 'ceo', 'seo', 'dev', etc.
    paperclip_ticket_id VARCHAR(100), -- referencia a Paperclip
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Tabla de acciones SEO
CREATE TABLE seo_actions (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    project_id INTEGER REFERENCES projects(id),
    action_type VARCHAR(100), -- 'audit', 'keyword_research', 'on_page', etc.
    target_url VARCHAR(1000),
    details JSONB,
    result JSONB,
    performed_by VARCHAR(100), -- agente que ejecutó
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de keywords
CREATE TABLE keywords (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    project_id INTEGER REFERENCES projects(id),
    keyword VARCHAR(500) NOT NULL,
    search_volume INTEGER,
    difficulty DECIMAL(3,1),
    current_position INTEGER,
    target_position INTEGER,
    intent VARCHAR(50), -- 'informational', 'transactional', 'commercial'
    status VARCHAR(50) DEFAULT 'tracking',
    first_tracked DATE DEFAULT CURRENT_DATE,
    last_checked DATE
);

-- Tabla de posicionamiento histórico
CREATE TABLE rankings (
    id SERIAL PRIMARY KEY,
    keyword_id INTEGER REFERENCES keywords(id),
    position INTEGER,
    url VARCHAR(1000),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de reseñas (SEO Local)
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    platform VARCHAR(50), -- 'google', 'trustpilot', etc.
    rating INTEGER,
    content TEXT,
    author VARCHAR(255),
    platform_review_id VARCHAR(255),
    response TEXT,
    responded_by VARCHAR(100), -- agente
    responded_at TIMESTAMP,
    posted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de métricas
CREATE TABLE metrics (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    metric_type VARCHAR(100), -- 'organic_traffic', 'conversions', etc.
    value DECIMAL(15,2),
    period_start DATE,
    period_end DATE,
    source VARCHAR(100), -- 'ga4', 'gsc', 'manual'
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para rendimiento
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_seo_actions_client ON seo_actions(client_id);
CREATE INDEX idx_keywords_client ON keywords(client_id);
CREATE INDEX idx_rankings_keyword ON rankings(keyword_id);
CREATE INDEX idx_reviews_client ON reviews(client_id);

-- Vista de tareas activas
CREATE VIEW active_tasks AS
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    t.assigned_agent,
    c.name as client_name,
    p.name as project_name,
    t.created_at
FROM tasks t
JOIN projects p ON t.project_id = p.id
JOIN clients c ON p.client_id = c.id
WHERE t.status IN ('pending', 'in_progress')
ORDER BY 
    CASE t.priority 
        WHEN 'urgent' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        ELSE 4 
    END,
    t.created_at;
```

### 4.2 Ejecutar Esquema

```bash
# Guardar esquema en archivo
cat > /tmp/schema.sql << 'EOF'
[Pegar el SQL de arriba]
EOF

# Ejecutar
psql postgresql://agency:PASSWORD@HOST:5432/agency < /tmp/schema.sql

# Verificar tablas creadas
psql postgresql://agency:PASSWORD@HOST:5432/agency -c "\dt"
```

---

## Paso 5: Insertar Datos Iniciales

### 5.1 Clientes Actuales

```sql
-- Insertar clientes existentes
INSERT INTO clients (name, slug, sector, website) VALUES
('Elecon', 'elecon', 'electrónica', 'https://www.elecon.es'),
('ACEC', 'acec', 'asociación', 'https://www.acec.es'),
('3CH', '3ch', 'control-horario', 'https://3ch.es');

-- Verificar
SELECT * FROM clients;
```

### 5.2 Proyectos

```sql
-- Insertar proyectos
INSERT INTO projects (client_id, name, type, status) VALUES
(1, 'SEO Elecon', 'seo', 'active'),
(1, 'Google Ads Elecon', 'ppc', 'active'),
(2, 'Web ACEC', 'web', 'active'),
(3, '3CH Platform', 'web', 'active');

-- Verificar
SELECT p.name as project, c.name as client, p.type, p.status
FROM projects p
JOIN clients c ON p.client_id = c.id;
```

---

## Paso 6: Configurar Variables de Entorno

### 6.1 En OpenClaw

Añadir a `~/.openclaw/.env`:

```bash
# PostgreSQL Agency Database
AGENCY_DB_URL=postgresql://agency:PASSWORD@HOST:5432/agency
AGENCY_DB_HOST=agency-postgres
AGENCY_DB_PORT=5432
AGENCY_DB_NAME=agency
AGENCY_DB_USER=agency
AGENCY_DB_PASS=[tu-contraseña]
```

### 6.2 Recargar entorno

```bash
# Reiniciar OpenClaw gateway
openclaw gateway restart
```

---

## Paso 7: Crear Skill de PostgreSQL para OpenClaw

### 7.1 Estructura

```bash
mkdir -p ~/.agents/skills/agency-db
```

### 7.2 SKILL.md

```markdown
---
name: agency-db
description: Acceso a la base de datos de la agencia (PostgreSQL). Clientes, proyectos, tareas, SEO, reseñas.
metadata:
  openclaw:
    requires:
      env:
        - AGENCY_DB_URL
---

# Agency Database Skill

Acceso a la base de datos centralizada de la agencia.

## Tablas Principales

| Tabla | Propósito |
|-------|-----------|
| clients | Clientes de la agencia |
| projects | Proyectos por cliente |
| tasks | Tareas con referencia a Paperclip |
| seo_actions | Historial de acciones SEO |
| keywords | Keywords trackeadas |
| rankings | Posicionamiento histórico |
| reviews | Reseñas (SEO Local) |
| metrics | Métricas por cliente |

## Uso

### Consultar clientes activos
```bash
psql $AGENCY_DB_URL -c "SELECT * FROM clients WHERE status = 'active';"
```

### Consultar tareas pendientes
```bash
psql $AGENCY_DB_URL -c "SELECT * FROM active_tasks;"
```

### Insertar nueva tarea
```bash
psql $AGENCY_DB_URL -c "INSERT INTO tasks (project_id, title, assigned_agent) VALUES (1, 'Auditoría SEO inicial', 'seo');"
```

### Actualizar estado de tarea
```bash
psql $AGENCY_DB_URL -c "UPDATE tasks SET status = 'completed', completed_at = NOW() WHERE id = 1;"
```
```

---

## Paso 8: Verificación Final

### 8.1 Checklist

```bash
# 1. PostgreSQL correindo
docker ps | grep postgres

# 2. Conexión funciona
psql $AGENCY_DB_URL -c "SELECT 1;"

# 3. Tablas creadas
psql $AGENCY_DB_URL -c "\dt"

# 4. Datos iniciales
psql $AGENCY_DB_URL -c "SELECT COUNT(*) FROM clients;"

# 5. Backup funciona
docker exec agency-postgres pg_dump -U agency agency > /tmp/verify-backup.sql && echo "OK" || echo "FAIL"
```

### 8.2 Si todo está OK

```
✅ PostgreSQL corriendo
✅ Conexión desde OpenClaw funciona
✅ Tablas creadas
✅ Datos iniciales insertados
✅ Backup funciona
✅ Variables de entorno configuradas
```

---

## Troubleshooting

### Error: Connection refused

```bash
# Verificar que PostgreSQL está corriendo
docker ps | grep postgres

# Verificar puertos
docker port agency-postgres

# Verificar logs
docker logs agency-postgres
```

### Error: Authentication failed

```bash
# Verificar contraseña
docker exec -it agency-postgres psql -U agency -d agency

# Si falla, resetear contraseña
docker exec -it agency-postgres psql -U postgres -c "ALTER USER agency WITH PASSWORD 'nueva-contraseña';"
```

### Error: Database "agency" does not exist

```bash
# Crear base de datos
docker exec -it agency-postgres psql -U postgres -c "CREATE DATABASE agency OWNER agency;"
```

### Error desde OpenClaw: psql not found

```bash
# Instalar cliente PostgreSQL
apt-get update && apt-get install -y postgresql-client
```

---

## Siguientes Pasos

Una vez completada la Fase 0:

1. **Fase 1:** Instalar Paperclip con 2 agentes (CEO + SEO)
2. **Fase 2:** Configurar Engram para memoria persistente
3. **Fase 3:** Añadir OpenCode para desarrollo

---

## Comandos de Referencia Rápida

```bash
# Conectar a la base de datos
psql $AGENCY_DB_URL

# Ver clientes
psql $AGENCY_DB_URL -c "SELECT * FROM clients;"

# Ver tareas activas
psql $AGENCY_DB_URL -c "SELECT * FROM active_tasks;"

# Backup manual
docker exec agency-postgres pg_dump -U agency agency > backup.sql

# Restaurar backup
cat backup.sql | docker exec -i agency-postgres psql -U agency agency

# Ver tamaño de base de datos
psql $AGENCY_DB_URL -c "SELECT pg_size_pretty(pg_database_size('agency'));"
```

---

*Documento creado por Taya (OpenClaw) - 2026-03-23*
