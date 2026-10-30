# Builds Orders Warcraft III REFORGED

> Plataforma web de build orders con validación en base de datos

Proyecto integrador de **Base de Datos II (BDD-642)** — Ingeniería de Sistemas, Unandes (La Paz, Bolivia), VI semestre.
Docente: Ing. Nagib Luis Vallejos Mamani · Motor: **MySQL 8.4** · Herramientas: MySQL Workbench, GitHub.

> **Leyenda:** *(Propenso a cambios)* = decisión provisoria que puede ajustarse durante el desarrollo.
> *(Pendiente)* = falta verificar o completar.

---

## 1. Descripción del problema

Los jugadores de Warcraft III comparten *build orders* (el orden y el momento exacto para construir y entrenar) en foros, videos y notas sueltas. Estos presentan problemas:

- No están centralizados ni se pueden buscar, copiar o bifurcar fácilmente.
- **No se validan**: muchos builds publicados son imposibles (piden un edificio sin recursos, sin comida libre o sin el requisito construido).
- Cuando cambia un parche, nadie sabe qué builds quedaron obsoletos.

**Solución:** una plataforma web en la nube donde cada usuario arma, publica, copia y comparte build orders, y donde **la base de datos valida que el build sea realizable** en los tiempos declarados antes de hacerlo público.

## 2. Enfoque y relación con la rúbrica

El sílabo propone "ventas e inventario" **como ejemplo**; este proyecto cubre los mismos requisitos técnicos con otro dominio:

| Rúbrica | En este proyecto |
|---|---|
| Inventario | Recursos (oro, madera, comida) simulados en el tiempo |
| Venta / operación | Pasos del build que "consumen" recursos |
| Auditoría | Historial de cambios de builds y pasos |
| Procedimiento transaccional | `sp_publicar_build` (valida y publica, o ROLLBACK) |
| Concurrencia | Likes atómicos y edición simultánea con control de versión |

(Pendiente) Confirmar con el docente que el cambio de dominio es aceptable.

## 3. Objetivos

**General:** diseñar e implementar una base de datos relacional en MySQL que gestione y valide build orders de Warcraft III Reforged, desplegada en la nube.

**Específicos:**
1. Modelar el dominio (razas, entidades, costos, requisitos, builds) con ERD conceptual, lógico y físico.
2. Implementar la validación de builds dentro de la BD mediante un procedimiento transaccional.
3. Garantizar trazabilidad (trigger de auditoría) y consistencia bajo concurrencia.
4. Optimizar consultas con índices justificados con `EXPLAIN`.
5. Aplicar permisos por rol y un procedimiento de respaldo/restauración.
6. Desplegar la solución fuera del entorno local.

## 4. Alcance por fases

### Fase 1 — Alcance para la presentación (evaluable)
- Plataforma web en la nube con **cuentas de usuario**.
- Razas: **Humanos y Orcos** (primeros 5 a 6 minutos de partida). (Propenso a cambios)
- Crear y editar builds en estado **borrador**.
- **Publicación validada**: solo se publica si pasa `sp_publicar_build`.
- Enlace público, copiar, **bifurcar (fork)** y likes.
- Vista del build en pantalla: lista de pasos con tiempo, oro, madera y comida (**sin semáforo**).
- Reportes y ranking, auditoría, concurrencia, permisos, respaldo, despliegue.

### Fase 2 — Ampliación (trabajo futuro)
- Razas **Elfos de la Noche y No-muertos**. (Propenso a cambios)
- **App de escritorio (.exe)** que lee la pantalla del jugador (barra de oro, madera y comida) y se sincroniza con la partida.
- **Semáforo** verde / amarillo / rojo según el atraso respecto al plan. (Propenso a cambios)

> La Fase 2 **no forma parte de la evaluación**; se documenta para mostrar la proyección del sistema.
> El modelo ya contempla la tabla `juego`, por lo que otros juegos (p. ej. StarCraft) podrían incorporarse sin rediseñar. (Propenso a cambios)

## 5. Reglas de negocio

1. Un usuario puede tener muchos builds; cada build pertenece a una sola raza.
2. Un build nace como **borrador**; solo pasa a **publicado** si el validador lo aprueba.
3. Un build publicado es **inmutable**: para modificarlo se crea una nueva versión.
4. Los pasos se ordenan por tiempo objetivo (segundos desde el inicio).
5. Un edificio entrena **una unidad a la vez**.
6. Una entidad requiere que sus **requisitos estén terminados** (inicio + tiempo de construcción).
7. La comida usada no puede superar el tope dado por edificios terminados.
8. Los trabajadores nuevos aportan a la economía solo cuando **terminan de entrenarse**.
9. El ingreso de oro depende del **upkeep** (tramos de comida usada). (Propenso a cambios)
10. Un usuario puede dar un solo *like* por build.
11. Todo cambio en builds y pasos queda registrado en la auditoría.

## 6. Validación de builds (núcleo del proyecto)

El procedimiento `sp_publicar_build` **simula la partida segundo a segundo** y calcula, para cada paso, el **tiempo mínimo posible** (`t_min`).

**Criterio:** el paso es válido si `t_declarado >= t_min - tolerancia`. Ir más tarde que `t_min` siempre es válido (solo sería ineficiente); el error se mide hacia un solo lado.

**Por paso se verifica:**
1. Oro y madera acumulados (trabajadores × tasa, con upkeep).
2. Comida usada vs. tope de comida.
3. Requisitos terminados.
4. Productor libre.
5. Trabajadores entrenados.

**Flujo transaccional:**
```
START TRANSACTION
  recorrer pasos ordenados por tiempo
  si algún paso es imposible → ROLLBACK + devolver paso, segundo y motivo
  si todos son válidos      → estado='publicado', guardar versión, generar slug → COMMIT
```
Ejemplo de error: *"Paso 7 (0:52): declaraste 0:52, lo más pronto posible es 0:58 (faltan 40 de oro para el Cuartel)"*.

### Tolerancias (Propenso a cambios)
| Regla | Tolerancia inicial | Rango | Motivo |
|---|---|---|---|
| Recursos (oro/madera) | **3 s** | 2 a 5 s | La economía es una aproximación |
| Requisitos, comida y productor libre | **0 a 1 s** | — | Son deterministas |

Los valores viven en la tabla `config_validacion` (`tol_recursos_s`, `tol_estructura_s`, tasa por trabajador), **no en el código**.

**Calibración:** se compararán los tiempos simulados contra un build conocido (replay o guía) y se ajustarán tasa y tolerancia. (Pendiente) Los valores numéricos se tomarán de Liquipedia / Hive Workshop porque cambian con los parches.

> Esta tolerancia es para **publicar**. La del semáforo (Fase 2) mide el atraso **jugando** y será otra tabla.

## 7. Modelo de datos

ERD conceptual, lógico y físico en la carpeta [`docs/`](docs/). (Pendiente) de elaborar.

**Tablas previstas (~16)** (Propenso a cambios)

| Grupo | Tablas |
|---|---|
| Catálogo | `juego`, `raza`, `recurso`, `entidad`, `costo_entidad`, `requisito` |
| Usuarios y builds | `usuario`, `build_order`, `build_paso`, `build_version`, `like_build` |
| Configuración | `tramo_upkeep`, `config_validacion`, `config_tolerancia` |
| Trazabilidad | `auditoria` |
| Fase 2 | `ejecucion`, `ejecucion_paso` |

`entidad` agrupa unidades, edificios, mejoras y héroes. `requisito` es una relación recursiva (permite la cadena Castillo → Cuartel → Granja).

## 8. Componentes de BD implementados

| Componente | Detalle |
|---|---|
| Procedimiento transaccional | `sp_publicar_build` (COMMIT / ROLLBACK) |
| Funciones | Cálculo de economía acumulada, `t_min` de un paso (Propenso a cambios) |
| Trigger de auditoría | Cambios en `build_order` y `build_paso` → `auditoria` |
| Vistas | Builds públicos, ranking, estadísticas por raza (Propenso a cambios) |
| Consultas avanzadas | JOIN, GROUP BY/HAVING, subconsultas, CASE, **CTE recursiva** (requisitos), **funciones de ventana** (`RANK`, `LAG`) |
| Índices | Por raza, popularidad y slug, con evidencia `EXPLAIN` antes/después |
| Concurrencia | Likes atómicos, edición con columna `version` (bloqueo optimista), `SELECT ... FOR UPDATE` |
| Seguridad | `CREATE USER / GRANT / REVOKE` |
| Respaldo | `mysqldump` + procedimiento de restauración |

### Roles de MySQL (Propenso a cambios)
| Usuario | Permisos |
|---|---|
| `app_rw` | Solo `EXECUTE` de procedimientos y lectura de vistas |
| `reportes_ro` | Solo `SELECT` en vistas de reporte |
| `admin` | Administración del esquema |

> No confundir con los **usuarios de la app** (tabla `usuario`: registro, login, builds, likes).

## 9. Pruebas y evidencias

Cada prueba se documenta con captura o salida en [`docs/evidencias/`](docs/evidencias/):

- [ ] Publicación válida (COMMIT)
- [ ] Publicación inválida (ROLLBACK forzado, con mensaje del paso)
- [ ] Disparo del trigger de auditoría
- [ ] Prueba de la función de economía
- [ ] `EXPLAIN` antes y después de cada índice
- [ ] **Concurrencia:** dos sesiones sobre el mismo build (likes simultáneos y edición con `version`)
- [ ] Permisos: acciones permitidas y denegadas por rol
- [ ] Respaldo y restauración en una BD limpia

## 10. Arquitectura y despliegue

```
[Navegador] → [Frontend] → [API delgada] → [MySQL en la nube]
                                 └─ cada endpoint llama a un procedimiento almacenado
```

Principio: **la lógica vive en la BD**; el backend solo expone los procedimientos.

| Capa | Opción | Estado |
|---|---|---|
| Base de datos MySQL | Aiven / TiDB Cloud / Railway u otra | (Pendiente) verificar plan gratuito vigente (Propenso a cambios) |
| Backend (API) | Render / Railway | (Pendiente) verificar plan gratuito vigente (Propenso a cambios) |
| Frontend | Servido por el backend o hosting estático | (Propenso a cambios) |

(Pendiente) Los planes gratuitos cambian (límites, suspensión por inactividad); se confirmarán antes de fijar la elección.
(Pendiente) Compatibilidad: verificar que el proveedor soporte MySQL 8.4 (o la versión más cercana) y triggers/procedimientos.

**Stack de aplicación** (backend / frontend): (Pendiente) por definir. (Propenso a cambios)

## 11. Datos del catálogo

- Fuente: Liquipedia / Hive Workshop (datos del parche vigente). (Pendiente)
- Se cargan desde CSV versionados en `database/seeds/`.
- Cada carga indica la versión del parche usada. (Propenso a cambios)
- Alcance inicial: trabajadores, edificios básicos, héroes, unidades iniciales y mejoras clave de **Humanos y Orcos**.

## 12. Estructura del repositorio (Propenso a cambios)

```
/
├── README.md
├── docs/
│   ├── erd/                # conceptual, lógico, físico
│   └── evidencias/         # capturas EXPLAIN, concurrencia, permisos
├── database/
│   ├── 01_ddl.sql
│   ├── 02_seeds/           # CSV + carga
│   ├── 03_funciones.sql
│   ├── 04_procedimientos.sql
│   ├── 05_triggers.sql
│   ├── 06_vistas.sql
│   ├── 07_consultas.sql
│   ├── 08_indices_explain.sql
│   ├── 09_concurrencia.sql
│   ├── 10_seguridad.sql
│   └── 11_respaldo.md
├── backend/
└── frontend/
```

**Flujo Git:** una rama por estudiante, commits frecuentes, mensajes descriptivos.

## 13. Cómo reproducirlo

(Pendiente) *Se completará al terminar el despliegue.* Orden previsto:

1. Crear la base en el proveedor elegido y obtener las credenciales.
2. Ejecutar los scripts de `database/` en orden numérico.
3. Cargar los CSV del catálogo.
4. Crear los usuarios de MySQL (`10_seguridad.sql`).
5. Configurar variables de entorno del backend (`.env.example`, sin credenciales reales).
6. Desplegar backend y frontend.
7. Ejecutar las pruebas de `docs/evidencias/`.

## 14. Riesgos

| Riesgo | Mitigación |
|---|---|
| Datos de WC3 desde cero (trabajo pesado) | Solo 2 razas y 5 a 6 minutos de partida |
| Economía simplificada no coincide con el juego | Parámetros en BD, tolerancia configurable, calibración |
| Planes gratuitos con límites o suspensión | Verificarlos y documentar alternativas |
| Docente no acepta el cambio de dominio | Justificación técnica según la tabla de la sección 2 |
| Cambios de parche alteran costos y tiempos | Catálogo con versión de parche |
| App con lectura de pantalla (Fase 2) puede incumplir términos del juego | Revisar los términos antes de publicarla; queda fuera de la evaluación |

## 15. Cronograma (Propenso a cambios)

| Etapa | Fecha límite |
|---|---|
| Etapa 1 | 03/11/2026 |
| Etapa 2 | 10/11/2026 |
| Etapa 3 (proyecto integrador y examen final) | 20/11/2026 |

## 16. Autor

- **Nombre:** Mauricio Iván Salces Sánchez - Rivanrete
- **Materia:** Base de Datos II (BDD-642) — Unandes

## 17. Licencia y créditos

Warcraft III y Blizzard Entertainment son marcas de sus respectivos dueños. Este proyecto es académico y no tiene afiliación con Blizzard. Los datos del juego se usan con fines educativos.
