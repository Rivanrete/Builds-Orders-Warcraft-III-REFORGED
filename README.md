# Builds Orders Warcraft III REFORGED

> Plataforma web de build orders de Warcraft III con validación en base de datos

Proyecto integrador de **Base de Datos II (BDD-642)** — Ingeniería de Sistemas, Unandes (La Paz, Bolivia), VI semestre. Motor: **MySQL 8.4**.

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

## Tecnologías previstas

- **Base de datos:** MySQL 8.4
- **Backend:** Node.js con el framework Express
- **Frontend:** React
- **Lenguaje:** JavaScript (backend y frontend)

## Autor y licencia

Mauricio Iván Salces Sánchez (Rivanrete). Proyecto académico sin afiliación con Blizzard Entertainment; Warcraft III es marca de sus dueños.
