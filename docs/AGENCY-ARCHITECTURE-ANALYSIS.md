# Análisis del Planteamiento: Agencia IA Self-Hosted

**Fecha:** 2026-03-23  
**Analista:** Taya (OpenClaw)  
**Documento base:** Arquitectura base para una agencia IA self-hosted de una persona

---

## Evaluación General

| Aspecto | Score | Comentario |
|---------|-------|------------|
| **Coherencia conceptual** | 9/10 | Muy sólido, filosofía clara |
| **Viabilidad técnica** | 8/10 | Realista, incremental |
| **Complejidad inicial** | 7/10 | Bien controlada, pero hay riesgo |
| **Alineación con SDD** | 9/10 | Excelente enfoque |
| **Mantenibilidad** | 8/10 | Buena, con advertencias |

**Veredicto:** ✅ **Planteamiento sólido y ejecutable.** 

---

## Fortalezas del Planteamiento

### 1. Filosofía Clara y Coherente

**"Anti-vibe coding, spec-driven, local-first"**

Esto es lo más valioso del documento. Evita el error común de "instalar todo y ver qué pasa". El enfoque SDD/OpenSpec como referencia conceptual es acertado.

### 2. Separación de Responsabilidades Bien Definida

```
Paperclip    → Orquestación (no ejecución)
PostgreSQL   → Datos de negocio (no memoria de agente)
Engram       → Memoria operativa (no datos de negocio)
MEMORY.md    → Estado de sesión (no archivo maestro)
```

Esta separación en capas es arquitectónicamente correcta.

### 3. Despliegue Incremental

La secuencia propuesta:
1. PostgreSQL
2. Paperclip
3. OpenClaw existente
4. Engram
5. OpenSpec/SDD
6. OpenCode
7. Expansión

**Correcto.** Cada paso valida antes de añadir complejidad.

### 4. Criterio de Agentes Independientes vs Subagentes

| Criterio | Agente Separado | Subagente |
|----------|-----------------|-----------|
| Memoria propia | ✅ | ❌ |
| Reutilización transversal | ✅ | ❌ |
| Presupuesto independiente | ✅ | ❌ |
| Tarea puntual y corta | ❌ | ✅ |

**Bien planteado.** Evita el error de usar subagentes para todo.

### 5. Justificación de PostgreSQL vs Supabase Free

Correcto. Supabase free:
- Pausa a 7 días inactivos ❌
- Sin backups ❌
- Dependencia externa crítica ❌

PostgreSQL en VPS:
- Sin pausas ✅
- Backups controlados ✅
- Sin dependencia externa ✅

### 6. Elección de OpenCode para Dev

Acertada. OpenCode está optimizado para coding y es agnóstico al modelo. OpenClaw es mejor para operaciones generales.

### 7. SEO Local como Agente Separado

Correcto. La memoria por cliente es diferente del SEO general. Mezclarlos contamina el contexto.

---

## Debilidades y Riesgos Identificados

### 1. Riesgo: Complejidad Oculta de Paperclip

**Problema:** El documento asume que Paperclip es "solo organización". Pero Paperclip requiere:
- Configurar adapters para cada agente
- Definir heartbeats
- Mantener org charts
- Gestionar budgets

**Impacto:** Paperclip añade superficie de ataque y configuración. No es "set and forget".

**Mitigación:** Empezar con 2-3 agentes máx en Paperclip. No los 6 propuestos de entrada.

### 2. Riesgo: Engram No Está Probado en Tu Stack

**Problema:** El documento asume que Engram funcionará sin problemas. Pero:
- Requiere MCP server
- Integración con OpenClaw no está documentada en detalle
- SQLite puede no escalar si la memoria crece mucho

**Mitigación:** Probar Engram con 1 agente (CEO/Coordinador) antes de expandir.

### 3. Riesgo: Strapi Como Capa de Gestión

**Problema:** El documento sugiere Strapi como API sobre PostgreSQL para datos de negocio. Pero:
- Strapi v5 aún en desarrollo
- Añade complejidad de mantenimiento
- ¿Es necesario si ya tienes PostgreSQL directo?

**Pregunta crítica:** ¿Quién va a gestionar Strapi manualmente? ¿Lolo? ¿Agentes?

**Alternativa más simple:** PostgreSQL + OpenClaw con skill `supabase` (ya la tienes) para acceder directamente. Strapi puede añadirse más tarde si se necesita UI de gestión.

### 4. Riesgo: Agente "Ops/Reportes" sin LLM

**Problema:** El documento sugiere Bash scripts sin LLM para reporting. Pero:
- ¿Cómo se generan insights de los datos?
- ¿Cómo se priorizan alertas?
- Bash no adapta el reporte al contexto

**Mitigación:** El agente Ops puede usar un modelo barato (GLM-5, Haiku) para análisis ligero. No todo necesita ser Bash puro.

### 5. Riesgo: Agente de Automatizaciones vía N8N/HTTP

**Problema:** N8N como "agente" vía webhook es viable, pero:
- N8N workflows son deterministas
- No hay razonamiento adaptativo
- Si falla, ¿quién diagnostica?

**Mitigación:** OpenClaw puede tener skill de N8N para disparar workflows, pero el agente que decide cuándo/dispara debería ser OpenClaw, no N8N actuando como agente.

### 6. Riesgo: 6 Agentes de Entrada

**Propuesta:** CEO, Dev, SEO, SEO Local, Automatizaciones, Ops

**Problema:** Para 1 persona, 6 agentes es demasiado para gestionar inicialmente.

**Mitigación:**
- Fase 1: CEO + SEO (2 agentes)
- Fase 2: Añadir Dev cuando haya trabajo de código
- Fase 3: Añadir SEO Local cuando haya clientes locales
- Fase 4: Ops y Automatizaciones según necesidad

---

## Contradicciones Detectadas

### 1. "Minimalista" vs "6 Agentes"

El documento dice "evitar complejidad gratuita" pero propone 6 agentes desde el inicio.

**Resolución:** Empezar con 2-3. Añadir según necesidad real.

### 2. Strapi vs Simplicidad

El documento enfatiza simplicidad pero añade Strapi como capa extra.

**Resolución:** Empezar con PostgreSQL + skill supabase. Añadir Strapi solo si se necesita UI de gestión manual.

### 3. "Un Operador" vs "Sistema Empresarial Complejo"

El documento es para 1 persona pero modela una empresa completa con CEO, Dev, SEO, etc.

**Resolución:** El modelo es correcto conceptualmente, pero la implementación debe ser gradual. Un operador puede empezar actuando como CEO y delegando a 1-2 especialistas.

---

## Análisis de la Secuencia de Despliegue

### Secuencia Propuesta (Correcta en Concepto)

1. PostgreSQL en Coolify ✅
2. Paperclip ✅
3. OpenClaw existente ✅
4. Engram ⚠️ (probar primero)
5. OpenSpec/SDD ⚠️ (definir proceso)
6. OpenCode ✅
7. Expansión ✅

### Secuencia Recomendada (Más Pragmática)

**Fase 0: Fundamentos (Semana 1-2)**
1. PostgreSQL en Coolify
2. Validar backups y acceso desde OpenClaw

**Fase 1: Orquestación Básica (Semana 3-4)**
3. Paperclip con 2 agentes:
   - CEO/Coordinador (OpenClaw)
   - SEO Specialist (OpenClaw)
4. Validar heartbeats y tickets

**Fase 2: Memoria Persistente (Semana 5-6)**
5. Probar Engram con CEO
6. Si funciona, extender a SEO

**Fase 3: Especialización (Semana 7-8)**
7. Añadir OpenCode para Dev
8. Añadir SEO Local si hay clientes

**Fase 4: Automatización (Según necesidad)**
9. N8N workflows como herramientas, no agentes
10. Ops/Reportes con modelo barato

---

## Análisis por Componente

### Paperclip

| Aspecto | Evaluación |
|---------|------------|
| Rol correcto | ✅ Orquestación, no ejecución |
| Complejidad | ⚠️ Media-alta |
| Prioridad | ✅ Fase 1-2 |
| Riesgo | Configuración de adapters |

**Recomendación:** Empezar con 2 agentes, no 6.

### Engram

| Aspecto | Evaluación |
|---------|------------|
| Propuesta | ✅ Simple (1 binario, 1 SQLite) |
| Integración | ⚠️ Requiere probar |
| Prioridad | ✅ Fase 2 |
| Riesgo | No probado en tu stack |

**Recomendación:** Probar con 1 agente antes de expandir.

### PostgreSQL

| Aspecto | Evaluación |
|---------|------------|
| Decisión | ✅ Correcta vs Supabase free |
| Ubicación | ✅ Coolify VPS |
| Prioridad | ✅ Fase 0 |
| Riesgo | Bajo |

**Recomendación:** Implementar primero que todo.

### Strapi

| Aspecto | Evaluación |
|---------|------------|
| Necesidad | ⚠️ Cuestionable inicialmente |
| Complejidad | ❌ Añade mantenimiento |
| Prioridad | ⚠️ Fase 3+ |
| Riesgo | Medio |

**Recomendación:** Posponer. Usar PostgreSQL directo con skill supabase.

### OpenCode

| Aspecto | Evaluación |
|---------|------------|
| Elección | ✅ Correcta para Dev |
| Prioridad | ✅ Fase 3 |
| Riesgo | Bajo |

**Recomendación:** Añadir cuando haya trabajo de código estructurado.

### N8N como "Agente"

| Aspecto | Evaluación |
|---------|------------|
| Concepto | ⚠️ Debilidad del planteamiento |
| Alternativa | OpenClaw dispara N8N workflows |
| Prioridad | ⚠️ Fase 4+ |
| Riesgo | Confusión de roles |

**Recomendación:** N8N es herramienta, no agente. El agente es OpenClaw.

---

## Análisis de Skills

### Skills Propuestas por Agente

| Agente | Skills Sugeridas | Evaluación |
|--------|------------------|------------|
| CEO | Mínimas | ✅ Correcto |
| Dev | Técnicas específicas | ✅ Correcto |
| SEO | Tavily, Agent Browser | ✅ Correcto |
| SEO Local | GOG, Agent Browser | ✅ Correcto |
| Automatizaciones | N8N/HTTP | ⚠️ Mejor como skill de OpenClaw |
| Ops | Bash | ⚠️ Mejor con modelo barato |

**Recomendación:** Cargar skills incrementalmente, no todas desde día 1.

---

## Análisis de Memoria

### Capas de Memoria Propuestas

```
┌─────────────────────────────────────┐
│  Negocio (PostgreSQL/Strapi)        │ ← Datos duraderos
├─────────────────────────────────────┤
│  Operativa (Engram)                 │ ← Memoria persistente
├─────────────────────────────────────┤
│  Sesión (MEMORY.md)                 │ ← Estado efímero
└─────────────────────────────────────┘
```

**Evaluación:** ✅ Correcto conceptualmente.

### Problema: MEMORY.md Grande

El documento identifica correctamente que MEMORY.md se degrada con muchos clientes.

**Solución alternativa a Engram:**
- Memory por proyecto en OpenClaw: `memory/cliente-elecon/`, `memory/cliente-acec/`
- Cargar solo el contexto relevante por sesión
- Engram como capa de búsqueda semántica

**Recomendación:** Probar ambas aproximaciones. Empezar con memory por proyecto, añadir Engram si se necesita búsqueda semántica.

---

## Análisis del Enfoque SDD/OpenSpec

### Concepto

Spec-Driven Development:
1. Especificación antes de implementación
2. Propuesta → Diseño → Tareas → Deltas
3. No improvisar cambios grandes

**Evaluación:** ✅ Correcto para trabajo profesional.

### Implementación Práctica

El documento menciona OpenSpec pero no detalla cómo implementarlo.

**Recomendación:**
1. Para cambios de software: SDD estricto
2. Para operaciones SEO: SDD flexible (spec ligera)
3. Para tareas rutinarias: Sin SDD

---

## Análisis de Costes

### Modelos Propuestos

| Tipo de Tarea | Modelo | Coste |
|---------------|--------|-------|
| Dev complejo | Modelo potente | Alto |
| SEO/Análisis | Modelo flexible | Medio |
| Repetitivo | Modelo barato/local | Bajo |

**Evaluación:** ✅ Correcto.

### GLM-5

El documento menciona GLM-5 de Z.AI como opción viable.

**Verificación:** GLM-5 es compatible con API OpenAI, lo que facilita integración.

**Recomendación:** Probar GLM-5 para tareas de coordinación y SEO. Usar modelos más potentes solo para Dev complejo.

---

## Análisis de Riesgos Globales

### Riesgo 1: Sobrecarga de Configuración

**Problema:** Paperclip + Engram + PostgreSQL + Strapi + N8N + múltiples agentes = mucha configuración.

**Mitigación:**
- Fase 0: PostgreSQL + OpenClaw existente
- Fase 1: Paperclip + 2 agentes
- Fase 2: Engram con 1 agente
- Fase 3+: Expandir según necesidad

### Riesgo 2: Debugging Complejo

**Problema:** Si algo falla, ¿dónde está el problema? ¿Paperclip? ¿Engram? ¿OpenClaw? ¿PostgreSQL?

**Mitigación:**
- Logging centralizado
- Health checks en cada componente
- Documentar flujos de datos

### Riesgo 3: Dependencia de Paperclip

**Problema:** Si Paperclip falla, ¿los agentes siguen funcionando?

**Mitigación:**
- OpenClaw puede trabajar independientemente
- Paperclip es capa de organización, no de ejecución
- Tener modo "fallback" sin Paperclip

---

## Recomendaciones Específicas

### 1. Simplificar Stack Inicial

**Propuesta documento:** PostgreSQL + Paperclip + Engram + Strapi + 6 agentes

**Recomendación:** PostgreSQL + Paperclip + 2 agentes + memory por proyecto

**Razón:** Validar cada capa antes de expandir.

### 2. Posponer Strapi

**Propuesta documento:** Strapi como capa de gestión

**Recomendación:** Posponer a Fase 3+

**Razón:** Añade complejidad sin beneficio claro inicialmente.

### 3. Replantear N8N como "Agente"

**Propuesta documento:** Agente de Automatizaciones vía N8N/HTTP

**Recomendación:** OpenClaw dispara N8N workflows como skill

**Razón:** N8N no razona. OpenClaw sí.

### 4. Empezar con 2-3 Agentes

**Propuesta documento:** 6 agentes

**Recomendación:** CEO + SEO + (Dev si hay trabajo)

**Razón:** Gestionable para 1 operador.

### 5. Probar Engram Antes de Expandir

**Propuesta documento:** Engram como memoria persistente

**Recomendación:** Probar con CEO primero

**Razón:** Validar integración antes de depender de ello.

---

## Plan de Acción Revisado

### Fase 0: Fundamentos (Semana 1-2)

```bash
# 1. PostgreSQL en Coolify
- Crear base de datos "agency"
- Configurar backups diarios
- Validar acceso desde OpenClaw

# 2. Validar OpenClaw actual
- Verificar que skills funcionan
- Documentar estado actual
- Limpiar MEMORY.md si es necesario
```

### Fase 1: Orquestación Básica (Semana 3-4)

```bash
# 1. Instalar Paperclip
- Seguir plan de instalación en Coolify
- Crear 2 agentes:
  - CEO/Coordinador
  - SEO Specialist

# 2. Configurar heartbeats
- CEO: cada 8h (check de objetivos)
- SEO: cada 4h (tareas SEO)

# 3. Validar flujos
- Crear ticket en Paperclip
- Verificar que OpenClaw lo recibe
- Verificar que resultado se loguea
```

### Fase 2: Memoria Persistente (Semana 5-6)

```bash
# 1. Probar Engram con CEO
- Instalar Engram
- Configurar integración
- Validar que memoria persiste entre sesiones

# 2. Si funciona, extender a SEO
- Misma configuración
- Validar

# 3. Si no funciona, usar memory por proyecto
- Crear estructura memory/cliente-xxx/
- Cargar solo contexto relevante
```

### Fase 3: Especialización (Semana 7-8)

```bash
# 1. Añadir OpenCode si hay trabajo Dev
- Configurar adapter en Paperclip
- Crear agente Dev
- Asignar tareas de código

# 2. Añadir SEO Local si hay clientes
- Crear agente separado
- Configurar memoria dedicada
- Probar con 1 cliente

# 3. Evaluar necesidad de Strapi
- Si se necesita UI de gestión, añadir
- Si no, posponer
```

### Fase 4: Automatización (Según necesidad)

```bash
# 1. N8N workflows como skills
- Crear workflows deterministas
- Exponer como endpoints
- OpenClaw los dispara

# 2. Ops/Reportes con modelo barato
- Usar GLM-5 o similar
- Generar reportes de consumo
- Alertas básicas
```

---

## Versión Corta (Para Pegar)

```
ARQUITECTURA: Agencia IA self-hosted para 1 operador

STACK BASE:
- Coolify (VPS) → ya funcionando
- PostgreSQL → datos de negocio (Fase 0)
- Paperclip → orquestación (Fase 1)
- Engram → memoria persistente (Fase 2)
- OpenClaw → operaciones (ya existe)
- OpenCode → desarrollo (Fase 3)

AGENTES (Empezar con 2):
1. CEO/Coordinador - priorización, derivación
2. SEO Specialist - auditoría, keyword research

EXPANSIÓN GRADUAL:
- Fase 3: Dev (OpenCode) si hay trabajo de código
- Fase 3: SEO Local si hay clientes locales
- Fase 4: Ops/Reportes con modelo barato
- Fase 4: Automatizaciones N8N como skills de OpenClaw

MEMORIA:
- PostgreSQL → datos de negocio (no memoria de agente)
- Engram → memoria operativa persistente (probar con 1 agente)
- MEMORY.md → estado de sesión (no archivo maestro)

FILOSOFÍA:
- Anti-vibe coding, spec-driven
- SDD/OpenSpec para cambios de software
- Añadir complejidad solo cuando necesidad esté clara
- Local-first, minimizar dependencias externas

NO HACER:
- Instalar 6 agentes de entrada
- Añadir Strapi hasta que se necesite
- Tratar N8N como agente (es herramienta)
- Mezclar memoria de negocio con memoria de agente
```

---

## Conclusión

**El planteamiento es sólido conceptualmente, pero la implementación debe ser más gradual de lo propuesto.**

### Fortalezas
- Filosofía clara (anti-vibe, SDD)
- Separación de capas correcta
- Secuencia incremental bien pensada
- Criterios claros para agentes vs subagentes

### Debilidades
- Riesgo de sobrecarga con 6 agentes
- Strapi añade complejidad cuestionable
- N8N como "agente" es conceptualmente débil
- Engram no probado en el stack

### Recomendación Final

**Seguir el planteamiento, pero con estas modificaciones:**

1. Empezar con 2 agentes, no 6
2. Posponer Strapi a Fase 3+
3. Probar Engram con 1 agente antes de expandir
4. N8N como skill de OpenClaw, no como agente
5. Validar cada fase antes de pasar a la siguiente

**Si se sigue este enfoque, la arquitectura es viable y mantenible para 1 operador.**

---

*Análisis generado por Taya (OpenClaw) - 2026-03-23*
