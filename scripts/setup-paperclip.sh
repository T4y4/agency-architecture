#!/bin/bash
# setup-paperclip.sh - Instalar Paperclip en Coolify
# Ejecutar en el VPS

set -e

echo "========================================="
echo "PAPERCLIP DEPLOY EN COOLIFY"
echo "========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuración
DB_HOST="b10e104vfb7gy490xknu8743"
DB_USER="lolo"
DB_PASS="iCxXchzXYtC7hqEn26S9rfMWZvVeZuw4cR53ORNX8Spv7EGFVJfK52iUs0B07Ag6"
DB_NAME="paperclip"
CONTAINER_NAME="paperclip-db"

# 1. Verificar que PostgreSQL está accesible
echo "1. Verificando PostgreSQL..."
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${GREEN}✅ PostgreSQL está corriendo${NC}"
else
    echo -e "${RED}❌ PostgreSQL no está corriendo${NC}"
    echo "Verifica que el contenedor '$CONTAINER_NAME' existe en Coolify"
    exit 1
fi

# 2. Crear base de datos
echo ""
echo "2. Creando base de datos '$DB_NAME'..."

# Verificar si ya existe
DB_EXISTS=$(docker exec -i $CONTAINER_NAME psql -U $DB_USER -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" 2>/dev/null | tr -d ' ')

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${YELLOW}⚠️  La base de datos '$DB_NAME' ya existe${NC}"
    read -p "¿Deseas recrearla? (y/N): " recreate
    if [ "$recreate" = "y" ] || [ "$recreate" = "Y" ]; then
        docker exec -i $CONTAINER_NAME psql -U $DB_USER -d postgres -c "DROP DATABASE $DB_NAME;" 2>/dev/null || true
        docker exec -i $CONTAINER_NAME psql -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"
        echo -e "${GREEN}✅ Base de datos recreada${NC}"
    fi
else
    docker exec -i $CONTAINER_NAME psql -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"
    echo -e "${GREEN}✅ Base de datos creada${NC}"
fi

# 3. Generar SESSION_SECRET
echo ""
echo "3. Generando SESSION_SECRET..."
SESSION_SECRET=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
echo -e "${GREEN}✅ SESSION_SECRET: $SESSION_SECRET${NC}"

# 4. Guardar configuración
echo ""
echo "4. Guardando configuración..."

CONFIG_FILE="/root/.paperclip-config"
cat > $CONFIG_FILE << EOF
# Paperclip Configuration
# Generado: $(date)

DATABASE_URL=postgres://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME
SESSION_SECRET=$SESSION_SECRET
NODE_ENV=production
EOF

chmod 600 $CONFIG_FILE
echo -e "${GREEN}✅ Configuración guardada en $CONFIG_FILE${NC}"

# 5. Preguntar dominio
echo ""
echo "5. Configurando dominio..."
read -p "Dominio para Paperclip (ej: paperclip.lienzolabs.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️  Sin dominio, Paperclip solo será accesible internamente${NC}"
    DOMAIN="paperclip.local"
fi

# 6. Crear docker-compose
echo ""
echo "6. Creando docker-compose..."

COMPOSE_FILE="/root/paperclip-compose.yml"
cat > $COMPOSE_FILE << EOF
version: '3.8'

services:
  paperclip:
    image: ghcr.io/paperclipai/paperclip:latest
    container_name: paperclip
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME
      - SESSION_SECRET=$SESSION_SECRET
      - PORT=3100
      - HOST=0.0.0.0
    networks:
      - coolify
    labels:
      - "coolify.managed=true"
      - "traefik.enable=true"
      - "traefik.http.routers.paperclip.rule=Host(\`$DOMAIN\`)"
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
EOF

echo -e "${GREEN}✅ Docker compose creado: $COMPOSE_FILE${NC}"

# 7. Deploy
echo ""
echo "7. Desplegando Paperclip..."
read -p "¿Desplegar ahora? (Y/n): " deploy_now

if [ "$deploy_now" != "n" ] && [ "$deploy_now" != "N" ]; then
    # Detener contenedor existente si existe
    docker stop paperclip 2>/dev/null || true
    docker rm paperclip 2>/dev/null || true
    
    # Deploy
    docker-compose -f $COMPOSE_FILE up -d
    
    echo ""
    echo "Esperando a que Paperclip inicie..."
    sleep 10
    
    # Verificar
    if docker ps | grep -q paperclip; then
        echo -e "${GREEN}✅ Paperclip está corriendo${NC}"
        
        # Esperar health check
        echo "Verificando health check..."
        for i in {1..30}; do
            if docker exec paperclip wget -q --spider http://localhost:3100/health 2>/dev/null; then
                echo -e "${GREEN}✅ Health check OK${NC}"
                break
            fi
            sleep 2
        done
        
        # Mostrar logs
        echo ""
        echo "Últimos logs:"
        docker logs paperclip --tail 20
    else
        echo -e "${RED}❌ Paperclip no está corriendo${NC}"
        echo "Revisa los logs:"
        docker logs paperclip
    fi
else
    echo -e "${YELLOW}Deploy pospuesto. Ejecuta manualmente:${NC}"
    echo "  docker-compose -f $COMPOSE_FILE up -d"
fi

# 8. Instrucciones finales
echo ""
echo "========================================="
echo "SIGUIENTES PASOS"
echo "========================================="
echo ""
echo "1. Configurar DNS:"
echo "   Tipo: A"
echo "   Nombre: paperclip"
echo "   Valor: [IP de tu VPS]"
echo ""
echo "2. Acceder a Paperclip:"
echo "   https://$DOMAIN"
echo ""
echo "3. Completar onboarding:"
echo "   - Crear usuario admin"
echo "   - Crear primera 'company'"
echo "   - Añadir primer agente (CEO)"
echo ""
echo "4. Ver logs:"
echo "   docker logs -f paperclip"
echo ""
echo "5. Reiniciar:"
echo "   docker restart paperclip"
echo ""
echo "Configuración guardada en: $CONFIG_FILE"
echo "Docker compose en: $COMPOSE_FILE"
echo ""
