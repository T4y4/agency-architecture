#!/bin/bash
# setup-phase0.sh - Configuración inicial PostgreSQL para Agencia IA
# Ejecutar en el VPS con Coolify

set -e

echo "========================================="
echo "FASE 0: Fundamentos - PostgreSQL Setup"
echo "========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

check_warning() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${YELLOW}⚠️  $1${NC}"
    fi
}

# 1. Verificar Docker
echo "1. Verificando Docker..."
which docker > /dev/null 2>&1
check_success "Docker instalado"

docker ps > /dev/null 2>&1
check_success "Docker funcionando"

# 2. Verificar si PostgreSQL ya existe
echo ""
echo "2. Verificando PostgreSQL existente..."
if docker ps | grep -q agency-postgres; then
    echo -e "${YELLOW}PostgreSQL 'agency-postgres' ya está corriendo${NC}"
    read -p "¿Deseas recrearlo? (y/N): " recreate
    if [ "$recreate" = "y" ] || [ "$recreate" = "Y" ]; then
        echo "Deteniendo contenedor existente..."
        docker stop agency-postgres 2>/dev/null || true
        docker rm agency-postgres 2>/dev/null || true
    else
        echo "Usando contenedor existente..."
        SKIP_CREATE=true
    fi
fi

# 3. Crear PostgreSQL si no existe
if [ "$SKIP_CREATE" != "true" ]; then
    echo ""
    echo "3. Creando PostgreSQL..."
    
    # Generar contraseña segura
    DB_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)
    echo -e "${YELLOW}Contraseña generada: $DB_PASSWORD${NC}"
    echo -e "${YELLOW}GUARDA ESTA CONTRASEÑA${NC}"
    echo ""
    
    read -p "¿Usar esta contraseña? (Y/n): " use_pass
    if [ "$use_pass" = "n" ] || [ "$use_pass" = "N" ]; then
        read -p "Introduce contraseña manualmente: " DB_PASSWORD
    fi
    
    # Crear contenedor PostgreSQL
    docker run -d \
        --name agency-postgres \
        --restart unless-stopped \
        -e POSTGRES_USER=agency \
        -e POSTGRES_PASSWORD=$DB_PASSWORD \
        -e POSTGRES_DB=agency \
        -v agency-postgres-data:/var/lib/postgresql/data \
        -p 5432:5432 \
        postgres:16-alpine
    
    check_success "PostgreSQL creado"
    
    # Esperar a que PostgreSQL esté listo
    echo "Esperando a que PostgreSQL esté listo..."
    sleep 5
    for i in {1..30}; do
        if docker exec agency-postgres pg_isready > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    check_success "PostgreSQL listo"
fi

# 4. Obtener contraseña si contenedor ya existe
if [ "$SKIP_CREATE" = "true" ]; then
    echo ""
    echo "Para conectar, necesitas la contraseña que configuraste en Coolify."
    read -p "Introduce la contraseña de PostgreSQL: " DB_PASSWORD
fi

# 5. Crear tablas
echo ""
echo "4. Creando tablas..."

# Guardar esquema temporalmente
cat > /tmp/agency-schema.sql << 'EOF'
-- Tabla de clientes
CREATE TABLE IF NOT EXISTS clients (
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
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de tareas
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(20) DEFAULT 'medium',
    assigned_agent VARCHAR(100),
    paperclip_ticket_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Tabla de acciones SEO
CREATE TABLE IF NOT EXISTS seo_actions (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    project_id INTEGER REFERENCES projects(id),
    action_type VARCHAR(100),
    target_url VARCHAR(1000),
    details JSONB,
    result JSONB,
    performed_by VARCHAR(100),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de keywords
CREATE TABLE IF NOT EXISTS keywords (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    project_id INTEGER REFERENCES projects(id),
    keyword VARCHAR(500) NOT NULL,
    search_volume INTEGER,
    difficulty DECIMAL(3,1),
    current_position INTEGER,
    target_position INTEGER,
    intent VARCHAR(50),
    status VARCHAR(50) DEFAULT 'tracking',
    first_tracked DATE DEFAULT CURRENT_DATE,
    last_checked DATE
);

-- Tabla de posicionamiento histórico
CREATE TABLE IF NOT EXISTS rankings (
    id SERIAL PRIMARY KEY,
    keyword_id INTEGER REFERENCES keywords(id),
    position INTEGER,
    url VARCHAR(1000),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de reseñas (SEO Local)
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    platform VARCHAR(50),
    rating INTEGER,
    content TEXT,
    author VARCHAR(255),
    platform_review_id VARCHAR(255),
    response TEXT,
    responded_by VARCHAR(100),
    responded_at TIMESTAMP,
    posted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de métricas
CREATE TABLE IF NOT EXISTS metrics (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    metric_type VARCHAR(100),
    value DECIMAL(15,2),
    period_start DATE,
    period_end DATE,
    source VARCHAR(100),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_seo_actions_client ON seo_actions(client_id);
CREATE INDEX IF NOT EXISTS idx_keywords_client ON keywords(client_id);
CREATE INDEX IF NOT EXISTS idx_rankings_keyword ON rankings(keyword_id);
CREATE INDEX IF NOT EXISTS idx_reviews_client ON reviews(client_id);

-- Vista de tareas activas
CREATE OR REPLACE VIEW active_tasks AS
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
EOF

# Ejecutar esquema
docker exec -i agency-postgres psql -U agency -d agency < /tmp/agency-schema.sql > /dev/null 2>&1
check_success "Tablas creadas"

# 6. Insertar datos iniciales
echo ""
echo "5. Insertando datos iniciales..."

docker exec -i agency-postgres psql -U agency -d agency << EOF > /dev/null 2>&1
-- Clientes existentes
INSERT INTO clients (name, slug, sector, website) VALUES
('Elecon', 'elecon', 'electrónica', 'https://www.elecon.es'),
('ACEC', 'acec', 'asociación', 'https://acec.es'),
('3CH', '3ch', 'control-horario', 'https://3ch.es')
ON CONFLICT (slug) DO NOTHING;

-- Proyectos
INSERT INTO projects (client_id, name, type, status) VALUES
(1, 'SEO Elecon', 'seo', 'active'),
(1, 'Google Ads Elecon', 'ppc', 'active'),
(2, 'Web ACEC', 'web', 'active'),
(3, '3CH Platform', 'web', 'active')
ON CONFLICT DO NOTHING;
EOF

check_success "Datos iniciales insertados"

# 7. Configurar backup
echo ""
echo "6. Configurando backup automático..."

mkdir -p /root/backups/postgres

cat > /root/backups/postgres/agency-backup.sh << 'BACKUP_EOF'
#!/bin/bash
BACKUP_DIR="/root/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)

docker exec agency-postgres pg_dump -U agency agency > $BACKUP_DIR/agency_$DATE.sql
gzip $BACKUP_DIR/agency_$DATE.sql

# Mantener solo últimos 7 días
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completado: agency_$DATE.sql.gz"
BACKUP_EOF

chmod +x /root/backups/postgres/agency-backup.sh
check_success "Script de backup creado"

# Añadir a cron si no existe
if ! crontab -l | grep -q "agency-backup.sh"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /root/backups/postgres/agency-backup.sh >> /var/log/agency-backup.log 2>&1") | crontab -
    check_success "Backup diario programado (3 AM)"
else
    echo -e "${YELLOW}Backup ya está en cron${NC}"
fi

# 8. Guardar credenciales
echo ""
echo "7. Guardando credenciales..."

CREDENTIALS_FILE="/root/.agency-db-credentials"
cat > $CREDENTIALS_FILE << EOF
# Credenciales PostgreSQL - Agencia IA
# Creado: $(date)

AGENCY_DB_URL=postgresql://agency:${DB_PASSWORD}@localhost:5432/agency
AGENCY_DB_HOST=localhost
AGENCY_DB_PORT=5432
AGENCY_DB_NAME=agency
AGENCY_DB_USER=agency
AGENCY_DB_PASS=${DB_PASSWORD}

# Para conectar desde Docker interno:
AGENCY_DB_URL_DOCKER=postgresql://agency:${DB_PASSWORD}@agency-postgres:5432/agency

# Para conectar desde Coolify (ajustar según red):
AGENCY_DB_URL_COOLIFY=postgresql://agency:${DB_PASSWORD}@agency-postgres:5432/agency
EOF

chmod 600 $CREDENTIALS_FILE
check_success "Credenciales guardadas en $CREDENTIALS_FILE"

# 9. Verificación final
echo ""
echo "8. Verificación final..."

# Contar tablas
TABLE_COUNT=$(docker exec agency-postgres psql -U agency -d agency -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
echo -e "${GREEN}✅ $TABLE_COUNT tablas creadas${NC}"

# Contar clientes
CLIENT_COUNT=$(docker exec agency-postgres psql -U agency -d agency -t -c "SELECT COUNT(*) FROM clients;")
echo -e "${GREEN}✅ $CLIENT_COUNT clientes insertados${NC}"

# Probar backup
echo "Probando backup..."
/root/backups/postgres/agency-backup.sh > /dev/null 2>&1
check_success "Backup funciona"

# 10. Resumen
echo ""
echo "========================================="
echo "✅ FASE 0 COMPLETADA"
echo "========================================="
echo ""
echo "Credenciales guardadas en: $CREDENTIALS_FILE"
echo ""
echo "Para conectar:"
echo "  psql \$AGENCY_DB_URL"
echo ""
echo "Para ver clientes:"
echo "  psql \$AGENCY_DB_URL -c 'SELECT * FROM clients;'"
echo ""
echo "Para ver tareas activas:"
echo "  psql \$AGENCY_DB_URL -c 'SELECT * FROM active_tasks;'"
echo ""
echo "Siguiente paso: Fase 1 - Instalar Paperclip"
echo ""
