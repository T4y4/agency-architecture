# Análisis: Plan de Despliegue Paperclip-Coolify

**Fecha:** 2026-03-23  
**Documento analizado:** implementation_plan (proporcionado por Lolo)  
**Comparado con:** docs/PAPERCLIP-COOLIFY-DEPLOY.md (nuestro plan anterior)

---

## Evaluación General

| Aspecto | Plan Nuevo | Nuestro Plan Anterior |
|---------|------------|----------------------|
| **Completitud** | ✅ 9/10 | ⚠️ 6/10 |
| **Variables de entorno** | ✅ Completas | ❌ Incompletas |
| **Modos de deployment** | ✅ Documentados | ❌ No mencionados |
| **Bootstrap auth** | ✅ Explicado | ❌ Faltaba |
| **Volumen persistente** | ✅ Especificado | ⚠️ Parcial |

**Veredicto:** ✅ **El plan nuevo es superior. Usar ese.**

---

## Diferencias Críticas

### 1. Variable de Autenticación Incorrecta

| Plan | Variable |
|------|----------|
| **Nuevo** | `BETTER_AUTH_SECRET` ✅ |
| **Nuestro** | `SESSION_SECRET` ❌ |

**Error crítico corregido:** Paperclip usa Better Auth, no sessions genéricas.

### 2. Variables Faltantes en Nuestro Plan

```env
# Faltaban en nuestro plan:
PAPERCLIP_PUBLIC_URL=https://paperclip.tudominio.com
PAPERCLIP_DEPLOYMENT_MODE=authenticated
PAPERCLIP_DEPLOYMENT_EXPOSURE=private
```

### 3. Bootstrap del Primer Usuario

| Plan | Método |
|------|--------|
| **Nuevo** | Buscar "Bootstrap invite" en logs ✅ |
| **Nuestro** | No mencionado ❌ |

**Importante:** En modo `authenticated`, Paperclip genera un URL de invitación en los logs para crear el primer usuario. Sin esto, no puedes acceder.

### 4. Volumen Persistente

| Plan | Path | Propósito |
|------|------|-----------|
| **Nuevo** | `/paperclip` | Secrets, workspaces, config |
| **Nuestro** | No especificado | - |

---

## Estado Actual de Lolo

### ✅ Ya Tiene (FASE 0 parcial)

- [x] Coolify instalado y funcionando
- [x] PostgreSQL creado (paperclip-db)
- [ ] Dominio configurado para Paperclip
- [ ] Recursos verificados (2 vCPU, 4GB RAM?)

### ⚠️ Pendiente

- [ ] Crear DB "paperclip" dentro del PostgreSQL existente
- [ ] Configurar dominio DNS
- [ ] Generar BETTER_AUTH_SECRET
- [ ] Decidir modo: `private` (Tailscale) o `public` (internet)

---

## Recomendación

### Usar el Plan Nuevo

**FASE 0 (Preparación)**
1. Verificar recursos del VPS
2. Configurar DNS: `paperclip.tudominio.com`
3. Decidir modo de exposición: `private` vs `public`

**FASE 1 (PostgreSQL)**
- ✅ Ya tienes PostgreSQL (paperclip-db)
- ⬜ Crear DB "paperclip" dentro:

```bash
docker exec -it paperclip-db psql -U lolo -d postgres -c "CREATE DATABASE paperclip;"
```

**FASE 2 (Deploy)**
- Usar variables del plan nuevo:

```env
DATABASE_URL=postgres://lolo:iCxX...@b10e104...:5432/paperclip
BETTER_AUTH_SECRET=[generar con: openssl rand -base64 32]
PAPERCLIP_PUBLIC_URL=https://paperclip.tudominio.com
PAPERCLIP_DEPLOYMENT_MODE=authenticated
PAPERCLIP_DEPLOYMENT_EXPOSURE=private
PORT=3100
HOST=0.0.0.0
SERVE_UI=true
NODE_ENV=production
PAPERCLIP_HOME=/paperclip
```

**FASE 3 (Bootstrap)**
1. Hacer deploy
2. Buscar en logs: `Bootstrap invite: https://...`
3. Usar ese URL para crear primer usuario

---

## Preguntas para Lolo

1. **¿Dominio para Paperclip?**
   - Ejemplo: `paperclip.lienzolabs.com`

2. **¿Modo de exposición?**
   - `private` → Acceso via Tailscale/VPN
   - `public` → Acceso desde internet (requiere más hardening)

3. **¿Recursos del VPS?**
   - ¿Cuántos vCPU?
   - ¿Cuánta RAM?
   - ¿Espacio en disco?

4. **¿Tienes Tailscale configurado?**
   - Si sí, modo `private` es más seguro
   - Si no, modo `public` con Cloudflare adelante

---

## Actualización a Nuestro Plan

### Eliminar

- ❌ `docs/PAPERCLIP-COOLIFY-DEPLOY.md` (obsoleto)
- ❌ `scripts/setup-paperclip.sh` (usa variables incorrectas)
- ❌ `docker/paperclip-docker-compose.yml` (incompleto)

### Reemplazar Con

- ✅ Usar el plan proporcionado (más completo y correcto)
- ✅ Crear script actualizado con variables correctas

---

## Conclusión

**El plan proporcionado es superior y corrige errores en nuestra documentación.**

**Acciones inmediatas:**
1. Responder las 4 preguntas arriba
2. Crear DB "paperclip" en PostgreSQL existente
3. Seguir FASE 2-3 del plan nuevo
4. Eliminar nuestra documentación obsoleta

---

*Análisis realizado por Taya (OpenClaw) - 2026-03-23*
