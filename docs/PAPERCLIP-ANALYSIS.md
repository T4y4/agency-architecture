# Análisis de Paperclip - Orquestación de Agentes IA

**Fecha:** 2026-03-23  
**Repositorio:** https://github.com/paperclipai/paperclip  
**Análisis para:** Lolo Peluzo

---

## Resumen Ejecutivo

**Paperclip es una plataforma de orquestación multi-agente para gestionar "empresas autónomas" de IA.** 

| Métrica | Valor |
|---------|-------|
| **Estrellas GitHub** | ~25-31K |
| **Último release** | v2026.318.0 (18 Mar 2026) |
| **Licencia** | MIT |
| **Lenguaje** | TypeScript/Node.js |
| **Estado** | Activo, desarrollo rápido |

**La analogía clave:** "If OpenClaw is an employee, Paperclip is the company."

---

## ¿Qué Problema Resuelve?

### Sin Paperclip
- ❌ 20 terminales de Claude Code abiertos, sin seguimiento
- ❌ Contexto fragmentado entre agentes
- ❌ Gasto descontrolado de tokens (loops infinitos)
- ❌ Tareas recurrentes manuales
- ❌ Pérdida de estado al reiniciar

### Con Paperclip
- ✅ Sistema de tickets centralizado
- ✅ Contexto que fluye desde objetivo → proyecto → tarea
- ✅ Budgets por agente con throttling automático
- ✅ Heartbeats programados (cada X horas)
- ✅ Estado persistente entre sesiones

---

## Arquitectura Técnica

### Stack
```
Frontend:  React + TypeScript
Backend:   Node.js + Express
Database:  PostgreSQL (embedded o externo)
Runtime:   pnpm + Node 20+
```

### Estructura
```
paperclip/
├── apps/
│   ├── web/          # React UI (dashboard)
│   └── server/       # API Node.js
├── packages/
│   ├── core/         # Lógica de orquestación
│   ├── adapters/     # Integraciones con agentes
│   └── plugins/      # Extensiones
└── db/               # Migraciones PostgreSQL
```

### Despliegue

**Desarrollo (local):**
```bash
npx paperclipai onboard --yes
# Crea PostgreSQL embebido automáticamente
# UI en http://localhost:3100
```

**Producción:**
- Docker (docker-compose incluido)
- Vercel (frontend) + Railway/Render (backend)
- Tu propio VPS con Coolify ✅

---

## Características Clave

### 1. Org Charts
- Jerarquías de agentes (CEO → CTO → Engineers)
- Roles y responsabilidades definidas
- Delegación automática por reporting lines

### 2. Goal Alignment
```
Company Mission: "Build #1 AI note-taking app to $1M MRR"
  └─ Project Goal: "Ship collaboration features"
      └─ Agent Goal: "Implement real-time sync"
          └─ Task: "Write WebSocket handler"
```
Cada tarea sabe POR QUÉ existe.

### 3. Heartbeats
Agentes despiertan en horario:
- Content Writer: cada 4h → blog posts, newsletters
- SEO Analyst: cada 8h → keyword research, audits
- Social Manager: cada 12h → posts, engagement

### 4. Cost Control
- Budget mensual por agente ($30, $50, $100...)
- Throttling automático cuando se agota
- Tracking de costos por tarea/proyecto/goal

### 5. Ticket System
- Cada conversación = ticket
- Full trace de tool calls
- Audit log inmutable

### 6. Multi-Company
- Una instalación = múltiples "empresas"
- Aislamiento completo de datos
- Dashboard para gestionar portfolio

### 7. Governance
- Tú eres el "Board of Directors"
- Aprobar contrataciones
- Override de estrategias
- Pause/terminate agentes en cualquier momento

---

## Agentes Soportados (Adapters)

| Agente | Soporte | Notas |
|--------|---------|-------|
| **OpenClaw** | ✅ Nativo | Integración first-class |
| **Claude Code** | ✅ Nativo | Adapter oficial |
| **Cursor** | ✅ v0.3.0+ | Soporte completo |
| **Codex** | ✅ Nativo | OpenAI Codex |
| **OpenCode** | ✅ v0.3.0+ | Adapter nuevo |
| **Pi** | ✅ v0.3.0+ | Inflection AI |
| **Gemini CLI** | ✅ v0.3.1+ | Google Gemini |
| **HTTP** | ✅ Genérico | Cualquier endpoint |
| **Bash** | ✅ Scripts | Comandos shell |

**Cualquier agente que pueda recibir un heartbeat está contratado.**

---

## Integración con OpenClaw

### Flujo de Trabajo

```
1. Paperclip asigna tarea a "OpenClaw Agent"
2. Paperclip envía heartbeat a OpenClaw con contexto:
   - Objetivo de la empresa
   - Objetivo del proyecto
   - Descripción de la tarea
   - Budget disponible
3. OpenClaw ejecuta la tarea usando sus skills
4. OpenClaw reporta resultado a Paperclip
5. Paperclip loguea todo en el ticket
```

### Skills de OpenClaw en Paperclip

Paperclip puede inyectar `SKILLS.md` en runtime para que OpenClaw sepa:
- Cómo reportar progreso
- Cómo solicitar aprobación
- Cómo delegar a otros agentes
- Cómo acceder al contexto de la empresa

---

## Roadmap (Lo que viene)

### Próximamente
- ⚪ **ClipMart** — Marketplace de templates de empresas
  - Descargar empresa completa con 1 click
  - Org charts pre-configurados
  - Skills y configs listas

- ⚪ Integración con sistemas de tickets externos (Asana, Linear, Trello)

- ⚪ Mejor soporte para cloud agents (Cursor Cloud, e2b)

### En desarrollo activo
- 🟢 Plugin system (extensibilidad)
- ⚪ Mejor documentación
- ⚪ Onboarding más fácil para OpenClaw

---

## Pros y Contras

### ✅ Pros

1. **Filosofía correcta** — Modela empresas, no workflows
2. **Multi-agente real** — No es para 1 agente, es para 20
3. **Cost control** — Budgets y throttling integrados
4. **Open source** — MIT, self-hosted, sin vendor lock-in
5. **Integración OpenClaw** — First-class citizen
6. **Multi-company** — Gestiona portfolio en 1 instalación
7. **Mobile-ready** — Dashboard responsive
8. **Proyecto activo** — Releases frecuentes, comunidad creciente

### ❌ Contras

1. **Complejidad inicial** — Curva de aprendizaje
2. **Setup producción** — Requiere PostgreSQL externo
3. **Documentación** — Aún mejorando (lo admiten)
4. **Early stage** — Cambios frecuentes, APIs pueden cambiar
5. **Overkill para 1 agente** — Si tienes 1 agente, no lo necesitas

---

## ¿Tiene Sentido para Lolo?

### Tu Situación Actual
- ✅ Tienes OpenClaw funcionando
- ✅ Múltiples clientes/proyectos (Elecon, ACEC, 3CH, SEO local)
- ✅ Infraestructura Coolify (Docker-ready)
- ✅ Skills instaladas (browser, SEO, tavily, github, etc.)
- ⚠️ Gestionas todo desde 1 sesión de OpenClaw

### Paperclip Añadiría
- ✅ Separación de "empresas" (cada cliente = 1 company)
- ✅ Budget tracking por cliente
- ✅ Heartbeats programados (audits SEO automáticos)
- ✅ Dashboard centralizado para ver qué hace cada agente
- ✅ Delegación automática (CEO → Specialist)
- ✅ Persistencia de contexto entre sesiones

### Veredicto: **SÍ, tiene sentido — pero no es urgente**

**Fase actual:** Domina las skills de OpenClaw primero  
**Fase siguiente:** Cuando tengas 3+ agentes corriendo simultáneamente, instala Paperclip

---

## Plan de Instalación (Cuando Estés Listo)

### Opción 1: Local (Prueba rápida)
```bash
# Requisitos: Node 20+, pnpm 9.15+
npx paperclipai onboard --yes
# Abre http://localhost:3100
```

### Opción 2: Coolify (Producción)
```bash
# 1. Clonar repo
git clone https://github.com/paperclipai/paperclip.git
cd paperclip

# 2. Configurar PostgreSQL en Coolify
# Crear base de datos "paperclip"

# 3. Variables de entorno
DATABASE_URL=postgresql://user:pass@host:5432/paperclip
SESSION_SECRET=tu-secreto-seguro

# 4. Deploy con Docker Compose
docker-compose up -d
```

### Opción 3: Tailscale + VPS (Recomendada por Paperclip)
- Paperclip en VPS con Tailscale
- Acceso seguro desde cualquier dispositivo
- Mobile-friendly para gestionar en movimiento

---

## Alternativas a Considerar

| Herramienta | Diferencia |
|-------------|------------|
| **LangGraph** | Framework de grafos, no orquestación de empresa |
| **AutoGen** | Multi-agente pero sin org charts/governance |
| **CrewAI** | Similar pero menos maduro, sin cost control |
| **Asana + OpenClaw** | Falta orquestación de agentes, budgets, heartbeats |

**Paperclip es único en:** Org charts + budgets + governance + multi-company

---

## Recomendación Final

### Ahora
1. ❌ **NO instalar Paperclip todavía**
2. ✅ Seguir dominando skills de OpenClaw
3. ✅ Crear workflows con `sessions_spawn` para sub-agentes
4. ✅ Documentar en MEMORY.md qué hace cada "rol" de agente

### En 2-4 semanas
5. ✅ Instalar Paperclip localmente (`npx paperclipai onboard --yes`)
6. ✅ Crear 1 "empresa" de prueba (ej: SEO Agency)
7. ✅ Configurar 2-3 agentes (CEO + Content Writer + SEO Analyst)
8. ✅ Probar heartbeats y cost tracking

### En 1-2 meses
9. ✅ Si funciona, desplegar en Coolify con PostgreSQL
10. ✅ Migrar clientes actuales como "companies" separadas
11. ✅ Configurar alerts y monitoring

---

## Links Útiles

- **GitHub:** https://github.com/paperclipai/paperclip
- **Docs:** https://paperclip.ing/docs
- **Discord:** https://discord.gg/m4HZY7xNG3
- **Releases:** https://github.com/paperclipai/paperclip/releases
- **Star History:** https://www.star-history.com/?repos=paperclipai%2Fpaperclip

---

*Análisis generado por Taya (OpenClaw) - 2026-03-23*
