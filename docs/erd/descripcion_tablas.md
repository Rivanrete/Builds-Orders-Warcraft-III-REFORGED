# Descripción de las tablas

## Login

**`usuario`**: cuentas de la plataforma. Guarda nombre de usuario, correo (ambos únicos), la contraseña como hash y la fecha de registro. Cada usuario es autor de sus builds.

**`rol`**: lista de roles del sistema. Solo existen `admin` y `usuario`, y no hay permisos aparte.

**`usuario_rol`**: tabla puente entre usuario y rol. La relación lógica usuario-rol es **N:N** (un usuario puede tener varios roles y un rol puede estar en varios usuarios) y se resuelve con esta tabla. En el diagrama se dibuja como dos relaciones 1:N: "1:N tiene" (usuario → usuario_rol) y "1:N se asigna a" (rol → usuario_rol). Su clave primaria es la pareja (`usuario_id`, `rol_id`), así que un usuario no repite un mismo rol.

## Catálogo

**`parche`**: versión del juego (por ejemplo 1.36.1) y su fecha de lanzamiento. Solo la usa `build_version`, que guarda con qué parche se validó cada versión publicada. El catálogo (raza, edificio, unidad, mejora) representa siempre el parche vigente. Un build queda obsoleto cuando el parche de su `build_version` no es el vigente (el de `lanzado_en` más reciente).

**`raza`**: Humanos, Orcos, etc. Un build pertenece a una sola raza.

**`edificio`**: edificios de una raza. Tiene costo en oro y madera, tiempo de construcción y la comida que aporta (granjas y salas principales). Lleva el `codigo_objeto` del juego (4 letras), único dentro de la tabla.

**`unidad`**: unidades, trabajadores y héroes. Se entrena en un edificio (`edificio_origen_id`), de donde se deduce su raza. Tiene costo, tiempo de entrenamiento, comida consumida, `es_trabajador` y `es_heroe`. Los héroes se entrenan en el Altar; la regla de límite por Altar se valida en `sp_publicar_build`. También tiene `codigo_objeto`, único dentro de la tabla.

**`mejora`**: investigaciones y mejoras. Se investiga en un edificio (`edificio_origen_id`). Tiene costo y tiempo de investigación.

**`requisito_edificio`**: dice qué edificio hace falta para construir otro edificio. Es una tabla puente: la relación lógica edificio-edificio es N:N (un edificio exige varios y es exigido por varios) y se dibuja como dos relaciones 1:N. Permite armar la cadena Castillo → Cuartel → Granja con una consulta recursiva.

**`requisito_unidad`**: dice qué edificio debe estar terminado para entrenar una unidad. Es una tabla puente: la relación lógica unidad-edificio es N:N y se dibuja como dos relaciones 1:N.

**`requisito_mejora`**: dice qué edificio, qué mejora anterior o ambos hacen falta para investigar una mejora. Al menos uno de los dos debe venir lleno. Es una tabla puente: la relación lógica mejora-edificio y mejora-mejora es N:N y se dibuja como relaciones 1:N.

## Builds

**`build_order`**: un build de un usuario para una raza. Tiene `estado` (borrador o publicado) y `origen` (armado manual o importado de una repetición). `version_bloqueo` sirve para detectar ediciones simultáneas. `cantidad_descargas` (entero, empieza en 0) se incrementa de forma atómica en cada descarga: sirve para el ranking y para la prueba de concurrencia. Un build publicado no se modifica.

**`build_paso`**: cada paso del build en orden de tiempo. Apunta a un edificio, una unidad o una mejora (solo uno) y guarda el segundo objetivo y una nota opcional.

**`build_version`**: copia congelada de los pasos en el momento de publicar (en JSON), con el parche vigente y el número de versión. Así el build publicado no cambia aunque el catálogo se actualice.

## Configuración y auditoría

**`tramo_upkeep`**: tramos de comida usada con el porcentaje de ingreso de oro que corresponde (upkeep). Se usan en la simulación de la economía.

**`config_validacion`**: parámetros de `sp_publicar_build` como filas nombre-valor: tolerancias, tasa de recolección por trabajador y umbrales del semáforo. Se pueden ajustar sin tocar el código.

**`auditoria`**: registro de cambios en builds y pasos (valores anteriores y nuevos en JSON) y de los intentos fallidos de publicación. El usuario es opcional por si el cambio lo hace el sistema.

## Vista

**`v_catalogo_codigo`** (vista, no es una tabla, por eso no está en el diagrama): une `edificio`, `unidad` y `mejora` en una sola lista con las columnas `tipo_objeto` (`edificio`, `unidad` o `mejora`), `objeto_id`, `codigo_objeto` y `nombre`. El importador de repeticiones `.w3g` busca cada código en este único lugar para saber qué objeto es. En el juego los códigos de 4 letras no se repiten entre edificios, unidades y mejoras, pero la base de datos solo garantiza la unicidad dentro de cada tabla; si el catálogo trajera un código repetido entre tablas, la vista lo mostraría dos veces.

## Cómo se llegó a este diseño

- Se eliminó `juego`: el proyecto es solo de Warcraft III.
- Se eliminaron `like_build`, el fork y `slug_publico`: la web solo sirve para descargar builds.
- Se eliminaron `recurso` y `costo_entidad`: solo se gastan oro y madera, que ahora son columnas.
- Se eliminaron `ejecucion_partida` y `ejecucion_paso`: la Fase 2 queda fuera del alcance por ahora.
- Se separó `entidad` en `edificio`, `unidad` y `mejora` (y los requisitos en tres tablas): así desaparece la autorreferencia.
- Se agregaron `rol` y `usuario_rol` para el login; los tokens JWT no se guardan en la base de datos.
- Se agregó `parche` (solo en `build_version`): así se sabe qué builds quedaron obsoletos.
- Se agregaron `codigo_objeto`, `origen`, `v_catalogo_codigo`, `es_heroe` y `cantidad_descargas`: importar repeticiones, límite de héroes por Altar y ranking por descargas.
