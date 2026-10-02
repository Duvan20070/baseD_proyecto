-- =============================================
-- VOLLEYSCAN – Base de datos MySQL (esquema final consolidado)
-- =============================================

CREATE DATABASE IF NOT EXISTS volleyscan
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE volleyscan;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- =============================================
-- 1. USUARIOS  (sin cambios — login ya definido)
-- =============================================
CREATE TABLE IF NOT EXISTS usuarios (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nombre        VARCHAR(100)        NOT NULL,
  apellido      VARCHAR(100)        NOT NULL,
  email         VARCHAR(150)        NOT NULL UNIQUE,
  password_hash VARCHAR(255)        NOT NULL,
  rol           ENUM('atleta', 'entrenador') DEFAULT 'atleta',
  nivel         ENUM('principiante', 'intermedio', 'avanzado', 'profesional') DEFAULT 'principiante',
  posicion      ENUM('opuesto', 'armador', 'central', 'punta', 'libero') DEFAULT 'opuesto',
  peso          DECIMAL(5,2),
  estatura      DECIMAL(4,2),
  fecha_nac     DATE,
  foto_url      VARCHAR(500),
  activo        BOOLEAN             DEFAULT TRUE,
  creado_en     DATETIME            DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME           DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SESIONES DE ANÁLISIS IA  (base, sin tocar columnas existentes)
-- =============================================
CREATE TABLE IF NOT EXISTS sesiones_analisis (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT             NOT NULL,
  tecnica         ENUM('remate', 'saque', 'recepcion', 'bloqueo', 'pase') NOT NULL,
  puntuacion      TINYINT UNSIGNED,
  duracion_seg    SMALLINT UNSIGNED,
  video_url       VARCHAR(500),
  miniatura_url   VARCHAR(500),
  modelo_ia       VARCHAR(50)     DEFAULT 'mediapipe-v1',
  creado_en       DATETIME        DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =============================================
-- 3. ERRORES DETECTADOS POR LA IA
-- =============================================
CREATE TABLE IF NOT EXISTS errores_detectados (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  sesion_id       INT             NOT NULL,
  tipo_error      VARCHAR(100)    NOT NULL,
  severidad       ENUM('leve', 'moderado', 'grave') DEFAULT 'moderado',
  ocurrencias     TINYINT UNSIGNED DEFAULT 1,
  descripcion     TEXT,
  FOREIGN KEY (sesion_id) REFERENCES sesiones_analisis(id) ON DELETE CASCADE
);

-- =============================================
-- 4. PUNTOS CLAVE DE ANÁLISIS
-- =============================================
CREATE TABLE IF NOT EXISTS puntos_clave (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  sesion_id       INT             NOT NULL,
  nombre          VARCHAR(100)    NOT NULL,
  aprobado        BOOLEAN         DEFAULT FALSE,
  angulo_grados   DECIMAL(6,2),
  FOREIGN KEY (sesion_id) REFERENCES sesiones_analisis(id) ON DELETE CASCADE
);

-- =============================================
-- 5. RUTINAS (personales del atleta — sin tocar columnas existentes)
-- =============================================
CREATE TABLE IF NOT EXISTS rutinas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT             NOT NULL,
  nombre          VARCHAR(150)    NOT NULL,
  descripcion     TEXT,
  nivel           ENUM('principiante', 'intermedio', 'avanzado') DEFAULT 'intermedio',
  objetivo        VARCHAR(255),
  generada_por_ia BOOLEAN         DEFAULT FALSE,
  activa          BOOLEAN         DEFAULT TRUE,
  creado_en       DATETIME        DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =============================================
-- 6. EJERCICIOS DE RUTINA
-- =============================================
CREATE TABLE IF NOT EXISTS ejercicios_rutina (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  rutina_id       INT             NOT NULL,
  nombre          VARCHAR(150)    NOT NULL,
  series          TINYINT UNSIGNED DEFAULT 3,
  repeticiones    TINYINT UNSIGNED DEFAULT 10,
  orden           TINYINT UNSIGNED DEFAULT 1,
  completado      BOOLEAN         DEFAULT FALSE,
  FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE CASCADE
);

-- =============================================
-- 7. PROGRESO DEL USUARIO
-- =============================================
CREATE TABLE IF NOT EXISTS progreso (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id          INT             NOT NULL,
  semana              DATE            NOT NULL,
  puntuacion_promedio DECIMAL(5,2),
  sesiones_completadas TINYINT UNSIGNED DEFAULT 0,
  tiempo_entreno_min  SMALLINT UNSIGNED DEFAULT 0,
  racha_dias          TINYINT UNSIGNED DEFAULT 0,
  mejora_porcentaje   DECIMAL(5,2),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  UNIQUE KEY uq_usuario_semana (usuario_id, semana)
);

-- =============================================
-- 8. NOTIFICACIONES
-- =============================================
CREATE TABLE IF NOT EXISTS notificaciones (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id  INT             NOT NULL,
  tipo        ENUM('logro', 'rutina', 'racha', 'recordatorio', 'analisis') NOT NULL,
  titulo      VARCHAR(200)    NOT NULL,
  mensaje     TEXT            NOT NULL,
  leida       BOOLEAN         DEFAULT FALSE,
  creado_en   DATETIME        DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =============================================
-- 9. CONFIGURACIÓN DEL USUARIO
-- =============================================
CREATE TABLE IF NOT EXISTS configuracion (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id            INT             NOT NULL UNIQUE,
  unidad_medida         ENUM('metric', 'imperial') DEFAULT 'metric',
  idioma                ENUM('es', 'en', 'pt')     DEFAULT 'es',
  tema                  ENUM('dark', 'light', 'auto') DEFAULT 'dark',
  calidad_video         ENUM('baja', 'media', 'alta', 'auto') DEFAULT 'alta',
  guardar_videos        BOOLEAN         DEFAULT TRUE,
  notif_sesion          BOOLEAN         DEFAULT TRUE,
  notif_analisis        BOOLEAN         DEFAULT TRUE,
  notif_contenido       BOOLEAN         DEFAULT FALSE,
  compartir_progreso    BOOLEAN         DEFAULT TRUE,
  permitir_comentarios  BOOLEAN         DEFAULT FALSE,
  visibilidad_analisis  ENUM('solo', 'entrenador', 'equipo', 'todos') DEFAULT 'solo',
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =============================================
-- 10. CONTENIDO EDUCATIVO
-- =============================================
CREATE TABLE IF NOT EXISTS contenido (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  titulo      VARCHAR(200)    NOT NULL,
  categoria   ENUM('saque', 'recepcion', 'bloqueo', 'pose', 'preparacion') NOT NULL,
  duracion    VARCHAR(20),
  descripcion TEXT,
  video_url   VARCHAR(500),
  imagen_url  VARCHAR(500),
  activo      BOOLEAN         DEFAULT TRUE,
  creado_en   DATETIME        DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 11. DISPOSITIVOS ACTIVOS
-- =============================================
CREATE TABLE IF NOT EXISTS dispositivos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id      INT             NOT NULL,
  nombre          VARCHAR(100)    NOT NULL,
  tipo            ENUM('movil', 'escritorio', 'tablet') DEFAULT 'escritorio',
  token_sesion    VARCHAR(500)    NOT NULL,
  ultimo_acceso   DATETIME        DEFAULT CURRENT_TIMESTAMP,
  ip              VARCHAR(45),
  activo          BOOLEAN         DEFAULT TRUE,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================================
-- 12. PANEL DEL ENTRENADOR — todas las FKs apuntan a usuarios(id)
-- (no existen tablas separadas entrenadores/deportistas; el rol de
-- usuarios discrimina el papel de cada fila referenciada)
-- =====================================================================

CREATE TABLE IF NOT EXISTS equipos (
    id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id INT NOT NULL COMMENT 'usuarios.id con rol=entrenador',
    nombre        VARCHAR(100) NOT NULL,
    categoria     VARCHAR(50) NULL,
    temporada     VARCHAR(20) NULL,
    activo        TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_equipo_entrenador (entrenador_id),
    CONSTRAINT fk_equipo_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS equipo_deportista (
    id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    equipo_id       INT UNSIGNED NOT NULL,
    deportista_id   INT NOT NULL COMMENT 'usuarios.id con rol=atleta',
    fecha_inicio    DATE NOT NULL,
    fecha_fin       DATE NULL,
    posicion        VARCHAR(50) NULL,
    numero_camiseta SMALLINT UNSIGNED NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_equipo_deportista_activo (equipo_id, deportista_id, fecha_inicio),
    KEY idx_ed_deportista (deportista_id),
    CONSTRAINT fk_ed_equipo FOREIGN KEY (equipo_id) REFERENCES equipos(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ed_deportista FOREIGN KEY (deportista_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS horarios (
    id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id INT NOT NULL,
    equipo_id     INT UNSIGNED NULL,
    deportista_id INT NULL COMMENT 'null = evento grupal',
    titulo        VARCHAR(150) NOT NULL,
    tipo_evento   ENUM('entrenamiento','partido','evaluacion','reunion','otro') NOT NULL DEFAULT 'entrenamiento',
    fecha         DATE NOT NULL,
    hora_inicio   TIME NOT NULL,
    hora_fin      TIME NOT NULL,
    ubicacion     VARCHAR(150) NULL,
    estado        ENUM('programado','en_curso','completado','cancelado') NOT NULL DEFAULT 'programado',
    notas         TEXT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_horario_fecha (entrenador_id, fecha),
    KEY idx_horario_equipo (equipo_id),
    CONSTRAINT fk_horario_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_horario_equipo FOREIGN KEY (equipo_id) REFERENCES equipos(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_horario_deportista FOREIGN KEY (deportista_id) REFERENCES usuarios(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Plantillas de rutina creadas por el entrenador (distinto de `rutinas`,
-- que es la copia personal/activa del atleta)
CREATE TABLE IF NOT EXISTS rutinas_plantillas (
    id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id INT NOT NULL,
    nombre        VARCHAR(150) NOT NULL,
    descripcion   TEXT NULL,
    categoria     ENUM('fuerza','tecnica','resistencia','velocidad','flexibilidad','tactica') NOT NULL,
    nivel         ENUM('principiante','intermedio','avanzado') NOT NULL DEFAULT 'intermedio',
    duracion_minutos SMALLINT UNSIGNED NOT NULL DEFAULT 60,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_plantilla_entrenador (entrenador_id, categoria),
    CONSTRAINT fk_plantilla_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS plantilla_ejercicios (
    id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    rutina_plantilla_id INT UNSIGNED NOT NULL,
    nombre_ejercicio  VARCHAR(150) NOT NULL,
    series            SMALLINT UNSIGNED NULL,
    repeticiones      VARCHAR(30) NULL,
    descanso_segundos SMALLINT UNSIGNED NULL,
    orden             SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    notas             VARCHAR(255) NULL,
    PRIMARY KEY (id),
    KEY idx_plantilla_ejercicio (rutina_plantilla_id, orden),
    CONSTRAINT fk_plantilla_ejercicio FOREIGN KEY (rutina_plantilla_id) REFERENCES rutinas_plantillas(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Puente no destructivo: liga la rutina personal del atleta con quién
-- se la asignó y de qué plantilla viene (ambas columnas nullable —
-- si el atleta la creó solo, quedan en NULL)
ALTER TABLE rutinas
    ADD COLUMN IF NOT EXISTS entrenador_id INT NULL AFTER usuario_id,
    ADD COLUMN IF NOT EXISTS plantilla_id INT UNSIGNED NULL AFTER entrenador_id;

ALTER TABLE rutinas
    ADD CONSTRAINT fk_rutina_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_rutina_plantilla FOREIGN KEY (plantilla_id) REFERENCES rutinas_plantillas(id)
        ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS partidos (
    id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id INT NOT NULL,
    equipo_id     INT UNSIGNED NOT NULL,
    horario_id    BIGINT UNSIGNED NULL,
    rival         VARCHAR(150) NOT NULL,
    fecha         DATE NOT NULL,
    sets_ganados  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    sets_perdidos TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ubicacion     VARCHAR(150) NULL,
    notas         TEXT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_partido_equipo (equipo_id, fecha),
    CONSTRAINT fk_partido_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_partido_equipo FOREIGN KEY (equipo_id) REFERENCES equipos(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_partido_horario FOREIGN KEY (horario_id) REFERENCES horarios(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS estadisticas_jugador (
    id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    partido_id             INT UNSIGNED NOT NULL,
    deportista_id          INT NOT NULL,
    saques_exitosos        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    saques_fallidos        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    ataques_exitosos       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    ataques_fallidos       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    bloqueos               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    recepciones_exitosas   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    recepciones_falladas   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    errores_no_forzados    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    puntos_totales         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    minutos_jugados        SMALLINT UNSIGNED NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_stat_partido_jugador (partido_id, deportista_id),
    KEY idx_stat_deportista (deportista_id),
    CONSTRAINT fk_stat_partido FOREIGN KEY (partido_id) REFERENCES partidos(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stat_deportista FOREIGN KEY (deportista_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Puente no destructivo: hace visible sesiones_analisis en el panel del
-- entrenador, sin duplicar lo que esa tabla ya resuelve
ALTER TABLE sesiones_analisis
    ADD COLUMN entrenador_id INT NULL AFTER usuario_id,
    ADD COLUMN revisado_por_entrenador BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN fecha_revision DATETIME NULL;

ALTER TABLE sesiones_analisis
    ADD CONSTRAINT fk_sesion_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE SET NULL ON UPDATE CASCADE;

-- =====================================================================
-- 13. MICROSERVICIO IA-FASTAPI (chat del entrenador con el asistente)
-- =====================================================================

CREATE TABLE IF NOT EXISTS perfiles_ia_entrenador (
    id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id       INT NOT NULL,
    estilo_comunicacion ENUM('tecnico','sencillo','motivacional') NOT NULL DEFAULT 'sencillo',
    nivel_experiencia   ENUM('principiante','intermedio','avanzado','profesional') NOT NULL DEFAULT 'intermedio',
    objetivos_generales TEXT NULL,
    preferencias        JSON NULL,
    idioma              VARCHAR(10) NOT NULL DEFAULT 'es',
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_perfil_entrenador (entrenador_id),
    CONSTRAINT fk_perfil_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS conversaciones (
    id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id  INT NOT NULL,
    titulo         VARCHAR(150) NOT NULL DEFAULT 'Nueva conversación',
    estado         ENUM('activa','archivada','eliminada') NOT NULL DEFAULT 'activa',
    resumen_ia     TEXT NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_conv_entrenador (entrenador_id, estado, updated_at),
    CONSTRAINT fk_conv_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mensajes (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    conversacion_id BIGINT UNSIGNED NOT NULL,
    rol             ENUM('usuario','asistente','sistema') NOT NULL,
    contenido       MEDIUMTEXT NOT NULL,
    metadata        JSON NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_msg_conversacion (conversacion_id, created_at),
    CONSTRAINT fk_msg_conversacion FOREIGN KEY (conversacion_id) REFERENCES conversaciones(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS memoria_contextual (
    id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id     INT NOT NULL,
    tipo              ENUM('preferencia','hecho','patron','objetivo') NOT NULL,
    clave             VARCHAR(100) NOT NULL,
    valor             JSON NOT NULL,
    relevancia_score  DECIMAL(4,3) NOT NULL DEFAULT 0.500,
    veces_usado       INT UNSIGNED NOT NULL DEFAULT 0,
    ultima_vez_usado  DATETIME NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_memoria_clave (entrenador_id, clave),
    KEY idx_memoria_relevancia (entrenador_id, relevancia_score DESC),
    CONSTRAINT fk_memoria_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contexto_conversacion (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    conversacion_id BIGINT UNSIGNED NOT NULL,
    deportista_id   INT NULL,
    equipo_id       INT UNSIGNED NULL,
    datos_contexto  JSON NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_contexto_conversacion (conversacion_id),
    KEY idx_contexto_deportista (deportista_id),
    CONSTRAINT fk_contexto_conversacion FOREIGN KEY (conversacion_id) REFERENCES conversaciones(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_contexto_deportista FOREIGN KEY (deportista_id) REFERENCES usuarios(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_contexto_equipo FOREIGN KEY (equipo_id) REFERENCES equipos(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS documentos_ia (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id       INT NOT NULL,
    conversacion_id     BIGINT UNSIGNED NULL,
    origen              ENUM('subido','generado') NOT NULL,
    tipo_documento      ENUM('rutina','dieta','planificacion','informe','evaluacion','cronograma','sesion','otro') NOT NULL DEFAULT 'otro',
    nombre_archivo      VARCHAR(255) NOT NULL,
    extension           VARCHAR(10) NOT NULL,
    ruta_almacenamiento VARCHAR(500) NOT NULL,
    contenido_extraido  LONGTEXT NULL,
    metadata            JSON NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_doc_entrenador (entrenador_id, tipo_documento),
    KEY idx_doc_conversacion (conversacion_id),
    CONSTRAINT fk_doc_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_doc_conversacion FOREIGN KEY (conversacion_id) REFERENCES conversaciones(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS planes_generados (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrenador_id   INT NOT NULL,
    conversacion_id BIGINT UNSIGNED NULL,
    deportista_id   INT NULL,
    equipo_id       INT UNSIGNED NULL,
    tipo_plan       ENUM('rutina','dieta','planificacion','informe','evaluacion','cronograma','sesion') NOT NULL,
    contenido       JSON NOT NULL,
    documento_id    BIGINT UNSIGNED NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_plan_entrenador (entrenador_id, tipo_plan),
    KEY idx_plan_deportista (deportista_id),
    CONSTRAINT fk_plan_entrenador FOREIGN KEY (entrenador_id) REFERENCES usuarios(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_plan_conversacion FOREIGN KEY (conversacion_id) REFERENCES conversaciones(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_plan_deportista FOREIGN KEY (deportista_id) REFERENCES usuarios(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_plan_equipo FOREIGN KEY (equipo_id) REFERENCES equipos(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_plan_documento FOREIGN KEY (documento_id) REFERENCES documentos_ia(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS intents_detectados (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    mensaje_id          BIGINT UNSIGNED NOT NULL,
    intent              VARCHAR(80) NOT NULL,
    confianza           DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    entidades_extraidas JSON NULL,
    ruta_seleccionada   VARCHAR(100) NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_intent_mensaje (mensaje_id),
    KEY idx_intent_tipo (intent),
    CONSTRAINT fk_intent_mensaje FOREIGN KEY (mensaje_id) REFERENCES mensajes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS registro_uso_ia (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    mensaje_id          BIGINT UNSIGNED NOT NULL,
    proveedor           ENUM('gemini','openai','ollama') NOT NULL,
    modelo              VARCHAR(60) NOT NULL,
    tokens_entrada      INT UNSIGNED NOT NULL DEFAULT 0,
    tokens_salida       INT UNSIGNED NOT NULL DEFAULT 0,
    tiempo_respuesta_ms INT UNSIGNED NOT NULL DEFAULT 0,
    exito               TINYINT(1) NOT NULL DEFAULT 1,
    error_detalle       TEXT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_uso_mensaje (mensaje_id),
    KEY idx_uso_proveedor_fecha (proveedor, created_at),
    CONSTRAINT fk_uso_mensaje FOREIGN KEY (mensaje_id) REFERENCES mensajes(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;