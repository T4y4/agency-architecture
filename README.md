# Arquitectura de Agencia IA Self-Hosted

Documentación para construir una agencia IA unipersonal con orquestación de agentes.

---

## Estructura

```
agency-architecture/
├── docs/           # Documentación
├── scripts/        # Scripts de instalación
└── docker/         # Docker Compose files
```

---

## Documentos

| Archivo | Descripción |
|---------|-------------|
| [AGENCY-ARCHITECTURE-ANALYSIS.md](docs/AGENCY-ARCHITECTURE-ANALYSIS.md) | Análisis del planteamiento base |
| [PAPERCLIP-ANALYSIS.md](docs/PAPERCLIP-ANALYSIS.md) | Análisis de Paperclip como orquestador |
| [PAPERCLIP-COOLIFY-INSTALL.md](docs/PAPERCLIP-COOLIFY-INSTALL.md) | Plan instalación paso a paso |
| [PAPERCLIP-COOLIFY-DEPLOY.md](docs/PAPERCLIP-COOLIFY-DEPLOY.md) | Deploy con PostgreSQL existente |
| [PHASE0-POSTGRESQL-COOLIFY.md](docs/PHASE0-POSTGRESQL-COOLIFY.md) | Setup PostgreSQL en Coolify |

---

## Scripts

| Script | Uso |
|--------|-----|
| `scripts/setup-phase0.sh` | Configura PostgreSQL para la agencia |
| `scripts/setup-paperclip.sh` | Instala Paperclip en Coolify |

---

## Arquitectura Objetivo

```
┌─────────────────────────────────────────────────┐
│                  PAPERCLIP                      │
│         (Orquestación empresarial)              │
│                                                 │
│  CEO → Dev → SEO → SEO Local → Ops → Auto     │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌─────────┐  ┌──────────┐  ┌─────────┐
   │OpenClaw │  │ OpenCode │  │   N8N   │
   │ (Ops)   │  │  (Dev)   │  │ (Auto)  │
   └─────────┘  └──────────┘  └─────────┘
        │             │             │
        └─────────────┼─────────────┘
                      ▼
              ┌──────────────┐
              │  PostgreSQL  │
              │ (Datos neg.) │
              └──────────────┘
                      │
                      ▼
              ┌──────────────┐
              │    Engram    │
              │  (Memoria)   │
              └──────────────┘
```

---

## Stack

| Componente | Función |
|------------|---------|
| **Coolify** | Plataforma de deploy (VPS) |
| **PostgreSQL** | Datos de negocio |
| **Paperclip** | Orquestación de agentes |
| **Engram** | Memoria persistente |
| **OpenClaw** | Operaciones y conocimiento |
| **OpenCode** | Desarrollo |
| **N8N** | Automatizaciones |

---

## Fases de Implementación

| Fase | Qué | Estado |
|------|-----|--------|
| 0 | PostgreSQL en Coolify | ⬜ |
| 1 | Paperclip + 2 agentes | ⬜ |
| 2 | Engram (memoria) | ⬜ |
| 3 | OpenCode (dev) | ⬜ |
| 4 | Expansión (SEO Local, Ops) | ⬜ |

---

## Filosofía

- **Anti-vibe coding**: Spec-driven development
- **Local-first**: Minimizar dependencias externas
- **Incremental**: Añadir complejidad solo cuando sea necesario
- **Especialización**: Un agente = una responsabilidad principal

---

*Creado: 2026-03-23*
