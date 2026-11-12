CREATE DATABASE IF NOT EXISTS bow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE bow;

SET default_storage_engine = InnoDB;

CREATE TABLE rol (
    id INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(20) NOT NULL,
    CONSTRAINT pk_rol PRIMARY KEY (id),
    CONSTRAINT uk_rol_nombre UNIQUE (nombre)
);

CREATE TABLE usuario (
    id INT NOT NULL AUTO_INCREMENT,
    nombre_usuario VARCHAR(50) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    hash_contrasena VARCHAR(255) NOT NULL,
    registrado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuario PRIMARY KEY (id),
    CONSTRAINT uk_usuario_nombre_usuario UNIQUE (nombre_usuario),
    CONSTRAINT uk_usuario_correo UNIQUE (correo)
);

CREATE TABLE usuario_rol (
    usuario_id INT NOT NULL,
    rol_id INT NOT NULL,
    CONSTRAINT pk_usuario_rol PRIMARY KEY (usuario_id, rol_id),
    CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id),
    CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (rol_id) REFERENCES rol (id)
);

CREATE TABLE parche (
    id INT NOT NULL AUTO_INCREMENT,
    version VARCHAR(20) NOT NULL,
    lanzado_en DATE NOT NULL,
    CONSTRAINT pk_parche PRIMARY KEY (id),
    CONSTRAINT uk_parche_version UNIQUE (version)
);

CREATE TABLE raza (
    id INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    CONSTRAINT pk_raza PRIMARY KEY (id),
    CONSTRAINT uk_raza_nombre UNIQUE (nombre)
);

CREATE TABLE edificio (
    id INT NOT NULL AUTO_INCREMENT,
    raza_id INT NOT NULL,
    codigo_objeto CHAR(4) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    costo_oro SMALLINT NOT NULL DEFAULT 0,
    costo_madera SMALLINT NOT NULL DEFAULT 0,
    tiempo_segundos SMALLINT NOT NULL,
    comida_proporcionada SMALLINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_edificio PRIMARY KEY (id),
    CONSTRAINT uk_edificio_codigo_objeto UNIQUE (codigo_objeto),
    CONSTRAINT uk_edificio_raza_nombre UNIQUE (raza_id, nombre),
    CONSTRAINT fk_edificio_raza FOREIGN KEY (raza_id) REFERENCES raza (id)
);

CREATE TABLE unidad (
    id INT NOT NULL AUTO_INCREMENT,
    edificio_origen_id INT NOT NULL,
    codigo_objeto CHAR(4) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    costo_oro SMALLINT NOT NULL DEFAULT 0,
    costo_madera SMALLINT NOT NULL DEFAULT 0,
    tiempo_segundos SMALLINT NOT NULL,
    comida_consumida SMALLINT NOT NULL DEFAULT 0,
    es_trabajador BOOLEAN NOT NULL DEFAULT FALSE,
    es_heroe BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_unidad PRIMARY KEY (id),
    CONSTRAINT uk_unidad_codigo_objeto UNIQUE (codigo_objeto),
    CONSTRAINT uk_unidad_nombre UNIQUE (nombre),
    CONSTRAINT fk_unidad_edificio_origen FOREIGN KEY (edificio_origen_id) REFERENCES edificio (id)
);

CREATE TABLE mejora (
    id INT NOT NULL AUTO_INCREMENT,
    edificio_origen_id INT NOT NULL,
    codigo_objeto CHAR(4) NOT NULL,
    nivel SMALLINT NOT NULL DEFAULT 1,
    nombre VARCHAR(100) NOT NULL,
    costo_oro SMALLINT NOT NULL DEFAULT 0,
    costo_madera SMALLINT NOT NULL DEFAULT 0,
    tiempo_segundos SMALLINT NOT NULL,
    CONSTRAINT pk_mejora PRIMARY KEY (id),
    CONSTRAINT uk_mejora_codigo_objeto_nivel UNIQUE (codigo_objeto, nivel),
    CONSTRAINT fk_mejora_edificio_origen FOREIGN KEY (edificio_origen_id) REFERENCES edificio (id)
);

CREATE TABLE requisito_edificio (
    edificio_id INT NOT NULL,
    edificio_requerido_id INT NOT NULL,
    CONSTRAINT pk_requisito_edificio PRIMARY KEY (edificio_id, edificio_requerido_id),
    CONSTRAINT fk_requisito_edificio_edificio FOREIGN KEY (edificio_id) REFERENCES edificio (id),
    CONSTRAINT fk_requisito_edificio_requerido FOREIGN KEY (edificio_requerido_id) REFERENCES edificio (id)
);

CREATE TABLE requisito_unidad (
    unidad_id INT NOT NULL,
    edificio_requerido_id INT NOT NULL,
    CONSTRAINT pk_requisito_unidad PRIMARY KEY (unidad_id, edificio_requerido_id),
    CONSTRAINT fk_requisito_unidad_unidad FOREIGN KEY (unidad_id) REFERENCES unidad (id),
    CONSTRAINT fk_requisito_unidad_requerido FOREIGN KEY (edificio_requerido_id) REFERENCES edificio (id)
);

CREATE TABLE requisito_mejora (
    id INT NOT NULL AUTO_INCREMENT,
    mejora_id INT NOT NULL,
    edificio_requerido_id INT NULL,
    mejora_requerida_id INT NULL,
    CONSTRAINT pk_requisito_mejora PRIMARY KEY (id),
    CONSTRAINT fk_requisito_mejora_mejora FOREIGN KEY (mejora_id) REFERENCES mejora (id),
    CONSTRAINT fk_requisito_mejora_edificio FOREIGN KEY (edificio_requerido_id) REFERENCES edificio (id),
    CONSTRAINT fk_requisito_mejora_requerida FOREIGN KEY (mejora_requerida_id) REFERENCES mejora (id),
    CONSTRAINT ck_requisito_mejora_alguno CHECK (edificio_requerido_id IS NOT NULL OR mejora_requerida_id IS NOT NULL)
);

CREATE TABLE build_order (
    id INT NOT NULL AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    raza_id INT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    estado ENUM('borrador', 'publicado') NOT NULL DEFAULT 'borrador',
    origen ENUM('manual', 'repeticion') NOT NULL DEFAULT 'manual',
    cantidad_descargas INT NOT NULL DEFAULT 0,
    version_bloqueo INT NOT NULL DEFAULT 0,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_build_order PRIMARY KEY (id),
    CONSTRAINT fk_build_order_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id),
    CONSTRAINT fk_build_order_raza FOREIGN KEY (raza_id) REFERENCES raza (id)
);

CREATE TABLE build_paso (
    id INT NOT NULL AUTO_INCREMENT,
    build_order_id INT NOT NULL,
    edificio_id INT NULL,
    unidad_id INT NULL,
    mejora_id INT NULL,
    numero_orden SMALLINT NOT NULL,
    tiempo_objetivo_segundos SMALLINT NOT NULL,
    nota VARCHAR(255) NULL,
    CONSTRAINT pk_build_paso PRIMARY KEY (id),
    CONSTRAINT fk_build_paso_build_order FOREIGN KEY (build_order_id) REFERENCES build_order (id),
    CONSTRAINT fk_build_paso_edificio FOREIGN KEY (edificio_id) REFERENCES edificio (id),
    CONSTRAINT fk_build_paso_unidad FOREIGN KEY (unidad_id) REFERENCES unidad (id),
    CONSTRAINT fk_build_paso_mejora FOREIGN KEY (mejora_id) REFERENCES mejora (id),
    CONSTRAINT ck_build_paso_un_objetivo CHECK ((edificio_id IS NOT NULL) + (unidad_id IS NOT NULL) + (mejora_id IS NOT NULL) = 1)
);

CREATE TABLE build_version (
    id INT NOT NULL AUTO_INCREMENT,
    build_order_id INT NOT NULL,
    parche_id INT NOT NULL,
    numero_version SMALLINT NOT NULL,
    pasos_json JSON NOT NULL,
    publicada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_build_version PRIMARY KEY (id),
    CONSTRAINT fk_build_version_build_order FOREIGN KEY (build_order_id) REFERENCES build_order (id),
    CONSTRAINT fk_build_version_parche FOREIGN KEY (parche_id) REFERENCES parche (id)
);

CREATE TABLE tramo_upkeep (
    id INT NOT NULL AUTO_INCREMENT,
    comida_minima SMALLINT NOT NULL,
    comida_maxima SMALLINT NOT NULL,
    porcentaje_ingreso_oro DECIMAL(5, 2) NOT NULL,
    CONSTRAINT pk_tramo_upkeep PRIMARY KEY (id)
);

CREATE TABLE config_validacion (
    id INT NOT NULL AUTO_INCREMENT,
    nombre_parametro VARCHAR(80) NOT NULL,
    valor_parametro DECIMAL(10, 3) NOT NULL,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT pk_config_validacion PRIMARY KEY (id),
    CONSTRAINT uk_config_validacion_nombre UNIQUE (nombre_parametro)
);

CREATE TABLE auditoria (
    id BIGINT NOT NULL AUTO_INCREMENT,
    usuario_id INT NULL,
    tabla_afectada VARCHAR(64) NOT NULL,
    registro_afectado_id BIGINT NOT NULL,
    accion ENUM('insertar', 'actualizar', 'eliminar', 'publicacion_fallida') NOT NULL,
    valores_anteriores JSON NULL,
    valores_nuevos JSON NULL,
    ocurrido_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_auditoria PRIMARY KEY (id),
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id)
);
