# Builds Orders Warcraft III REFORGED

> Plataforma web de build orders de Warcraft III con validación en base de datos

Proyecto integrador de **Base de Datos II (BDD-642)** — Ingeniería de Sistemas, Unandes (La Paz, Bolivia), VI semestre. Motor: **MySQL 8.0**.

## Problema

Los build orders de Warcraft III se comparten en foros y videos sin validar: muchos son imposibles (piden un edificio sin tener el oro ni los requisitos) y nadie sabe cuáles quedan obsoletos tras un parche. Esta plataforma permite armar builds a mano o importando una repetición (.w3g), y la base de datos valida que sean realizables antes de publicarlos.

## Reglas esenciales

1. Un build pertenece a un usuario y a una sola raza. En la primera fase: **Humanos y Orcos**.
2. Nace como borrador y solo se publica si `sp_publicar_build` lo aprueba.
3. Un build publicado no se modifica: se guarda una versión con el parche con el que se validó. Si el parche vigente cambia, el build queda obsoleto.
4. Cada paso es un edificio, una unidad o una mejora, con su tiempo objetivo.
5. Un paso es válido si el tiempo declarado no es menor al mínimo posible (con tolerancia configurable en `config_validacion`).
6. Los pasos respetan oro, madera, comida, requisitos y productor libre.
7. Los cambios en builds y los intentos fallidos de publicación quedan en `auditoria`.
8. Cada descarga suma uno al contador del build, que se usa para el ranking.

## Modelo de datos

17 tablas. [Descripción de las tablas](docs/erd/descripcion_tablas.md) · [Código del diagrama](docs/erd/erd.mmd)

![Diagrama entidad-relación](docs/erd/erd.png)

## Base de datos

Los scripts están en `db/` y se ejecutan en este orden:

```bash
mysql -u USUARIO -p --default-character-set=utf8mb4 < db/01_schema.sql
mysql -u USUARIO -p --default-character-set=utf8mb4 < db/02_datos.sql
```

- `01_schema.sql`: crea la base `bow` y las 17 tablas.
- `02_datos.sql`: catálogo de Humanos y Orcos del parche 3.0.1 (19 de octubre de 2026), tomado de los archivos del juego en español latino, y datos de ejemplo para el resto de las tablas: usuarios ficticios, dos builds, una versión publicada y tres registros de auditoría.

## Pendiente de la siguiente etapa

- El procedimiento `sp_publicar_build`, que valida y publica los builds.
- La vista `v_catalogo_codigo`, que usará el importador de repeticiones.
- Los parámetros de `config_validacion` que faltan: tolerancia de tiempo, tasa de recolección por trabajador y umbrales del semáforo.

## Tecnologías propuestas

Esta es una propuesta tecnológica inicial. La única parte ya implementada en el entorno local es la base de datos (esquema y datos en `db/`); el resto describe el stack previsto y no se presenta como implementado.

### Frontend

| Tecnología | Función | Justificación |
|---|---|---|
| React | Construir la interfaz web para armar, consultar y descargar builds. | Permite armar las pantallas con componentes reutilizables y usa JavaScript, igual que el backend. |
| Vite | Servir el frontend en desarrollo y generar su versión final. | Arranca rápido y necesita poca configuración en un proyecto React. |

### Backend

| Tecnología | Función | Justificación |
|---|---|---|
| Node.js | Ejecutar el servidor del proyecto con JavaScript. | Permite usar un solo lenguaje en backend y frontend. |
| Express | Exponer la API que recibe las peticiones y llama a la base de datos. | Es un framework mínimo y la validación de los builds queda en la base de datos. |
| JWT | Identificar al usuario y su rol (admin o usuario) en cada petición. | Los tokens no se guardan en la base de datos, como indica el diseño. |
| w3gjs | Leer repeticiones `.w3g` para importar builds. | Permite traducir los códigos de la repetición al catálogo mediante `codigo_objeto`. |

### Base de datos

| Tecnología | Función | Justificación |
|---|---|---|
| MySQL 8.0 | Guardar el catálogo, los builds, las versiones publicadas y la auditoría. | Ofrece claves foráneas, restricciones CHECK, columnas JSON y procedimientos almacenados, que el diseño usa para validar los builds. |

## Autor y licencia

Mauricio Iván Salces Sánchez (Rivanrete). Proyecto académico sin afiliación con Blizzard Entertainment; Warcraft III es marca de sus dueños.
