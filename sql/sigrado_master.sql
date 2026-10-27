-- =====================================================================
-- SIGRADO - SISTEMA DE GESTIÓN DE TRABAJOS DE GRADO
-- Script SQL adaptado para Supabase (PostgreSQL)
-- Basado en la especificación de 11 tablas y flujo de 6 fases
-- =====================================================================

-- 1. TIPOS ENUM (PostgreSQL / Supabase)
DO $$ BEGIN
    CREATE TYPE rol_enum AS ENUM ('administrador', 'comite', 'docente', 'estudiante');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE origen_propuesta_enum AS ENUM ('Docente', 'Estudiante');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE estado_propuesta_enum AS ENUM ('Pendiente', 'Aprobada', 'Correcciones', 'Rechazada');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE tipo_modalidad_enum AS ENUM ('Desarrollo tecnologico', 'Emprendimiento', 'Investigacion', 'Otro');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE tipo_nivel_enum AS ENUM ('Tecnologico', 'Profesional');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE tipo_idea_enum AS ENUM ('Propia', 'Banco');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE responsable_enum AS ENUM ('comite', 'estudiante', 'director', 'evaluador');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE estado_proyecto_enum AS ENUM ('En curso', 'Rechazado', 'Cancelado', 'Finalizado');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE tipo_documento_enum AS ENUM (
        'SoportePago',
        'Propuesta_FDC124',
        'Turnitin_FDC124',
        'Propuesta_FDC124_Firmada',
        'Informe_FDC125',
        'Turnitin_FDC125',
        'Informe_FDC125_Firmado',
        'Rejilla_FDC129',
        'Acta_Sustentacion',
        'Otro'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE rol_respuesta_enum AS ENUM ('comite', 'director', 'evaluador');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE estado_respuesta_enum AS ENUM ('Aprobado', 'Correcciones', 'Rechazado');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. TABLA: roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    nombre rol_enum NOT NULL UNIQUE
);

-- 3. TABLA: usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    documento VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    telefono VARCHAR(20),
    programa VARCHAR(80) DEFAULT 'Ingeniería de Sistemas',
    activo SMALLINT DEFAULT 1,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. TABLA: usuario_rol
CREATE TABLE IF NOT EXISTS usuario_rol (
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (usuario_id, rol_id)
);

-- 5. TABLA: periodos
CREATE TABLE IF NOT EXISTS periodos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    inicio_propuestas_banco DATE NOT NULL,
    fin_propuestas_banco DATE NOT NULL,
    inicio_nuevos_proyectos DATE NOT NULL,
    fin_nuevos_proyectos DATE NOT NULL,
    fin_aprobacion_propuesta DATE NOT NULL,
    activo SMALLINT DEFAULT 1
);

-- 6. TABLA: formatos
CREATE TABLE IF NOT EXISTS formatos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    url_plantilla VARCHAR(500) NOT NULL,
    activo SMALLINT DEFAULT 1
);

-- 7. TABLA: propuestas_banco
CREATE TABLE IF NOT EXISTS propuestas_banco (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    proponente_id INT NOT NULL REFERENCES usuarios(id),
    origen origen_propuesta_enum NOT NULL DEFAULT 'Docente',
    titulo VARCHAR(255) NOT NULL,
    tipo_modalidad tipo_modalidad_enum NOT NULL,
    tipo_nivel tipo_nivel_enum NOT NULL,
    linea_investigacion VARCHAR(120),
    periodo_id INT NOT NULL REFERENCES periodos(id),
    objetivo_general TEXT NOT NULL,
    descripcion TEXT,
    estado estado_propuesta_enum NOT NULL DEFAULT 'Pendiente',
    disponible SMALLINT DEFAULT 1,
    fecha_propuesta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_revision TIMESTAMP,
    revisor_id INT REFERENCES usuarios(id),
    observacion_comite TEXT
);

-- 8. TABLA: proyectos
CREATE TABLE IF NOT EXISTS proyectos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    banco_id INT REFERENCES propuestas_banco(id),
    titulo VARCHAR(255) NOT NULL,
    objetivo_general TEXT NOT NULL,
    descripcion TEXT,
    tipo_idea tipo_idea_enum NOT NULL,
    tipo_modalidad tipo_modalidad_enum NOT NULL,
    tipo_nivel tipo_nivel_enum NOT NULL,
    linea_investigacion VARCHAR(120),
    periodo_id INT NOT NULL REFERENCES periodos(id),
    codigo_modalidad VARCHAR(20) UNIQUE,
    fase SMALLINT DEFAULT 1,
    responsable responsable_enum DEFAULT 'comite',
    estado estado_proyecto_enum DEFAULT 'En curso',
    director_id INT REFERENCES usuarios(id),
    evaluador_id INT REFERENCES usuarios(id),
    codirector_id INT REFERENCES usuarios(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. TABLA: proyecto_integrantes
CREATE TABLE IF NOT EXISTS proyecto_integrantes (
    proyecto_id INT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    es_responsable SMALLINT DEFAULT 0,
    PRIMARY KEY (proyecto_id, usuario_id)
);

-- 10. TABLA: documentos
CREATE TABLE IF NOT EXISTS documentos (
    id SERIAL PRIMARY KEY,
    proyecto_id INT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    fase SMALLINT NOT NULL,
    tipo tipo_documento_enum NOT NULL,
    version INT NOT NULL DEFAULT 1,
    url VARCHAR(500) NOT NULL,
    titulo VARCHAR(255),
    observaciones TEXT,
    subido_por INT NOT NULL REFERENCES usuarios(id),
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_doc_version UNIQUE (proyecto_id, tipo, version)
);

-- 11. TABLA: respuestas
CREATE TABLE IF NOT EXISTS respuestas (
    id SERIAL PRIMARY KEY,
    proyecto_id INT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    fase SMALLINT NOT NULL,
    ronda INT NOT NULL DEFAULT 1,
    usuario_id INT NOT NULL REFERENCES usuarios(id),
    rol rol_respuesta_enum NOT NULL,
    estado estado_respuesta_enum NOT NULL,
    acta_numero VARCHAR(50),
    acta_fecha DATE,
    comentario TEXT,
    documento_id INT REFERENCES documentos(id),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. TABLA: historial
CREATE TABLE IF NOT EXISTS historial (
    id SERIAL PRIMARY KEY,
    proyecto_id INT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    usuario_id INT NOT NULL REFERENCES usuarios(id),
    accion VARCHAR(100) NOT NULL,
    fase SMALLINT,
    acta_numero VARCHAR(50),
    comentario TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. TABLA: sustentaciones
CREATE TABLE IF NOT EXISTS sustentaciones (
    id SERIAL PRIMARY KEY,
    proyecto_id INT NOT NULL UNIQUE REFERENCES proyectos(id) ON DELETE CASCADE,
    fecha_hora TIMESTAMP NOT NULL,
    lugar_enlace VARCHAR(255) NOT NULL,
    resultado VARCHAR(50),
    acta_numero VARCHAR(50),
    registrado_por INT NOT NULL REFERENCES usuarios(id)
);

-- =====================================================================
-- DATOS INICIALES SEMILLA
-- =====================================================================

INSERT INTO roles (id, nombre) VALUES 
(1, 'administrador'),
(2, 'comite'),
(3, 'docente'),
(4, 'estudiante')
ON CONFLICT (id) DO NOTHING;

-- Usuarios de prueba (contraseña por defecto para todos: '123456')
INSERT INTO usuarios (id, documento, nombres, apellidos, email, password_hash, telefono, programa, activo) VALUES
(1, '1001', 'Carlos', 'Administrador', 'admin@sigrado.edu.co', '123456', '3001112233', 'Ingeniería de Sistemas', 1),
(2, '1002', 'Martha', 'Comité Grados', 'comite@sigrado.edu.co', '123456', '3002223344', 'Ingeniería de Sistemas', 1),
(3, '1003', 'Elsa Patricia', 'Carvajal', 'elsa.carvajal@sigrado.edu.co', '123456', '3003334455', 'Ingeniería de Sistemas', 1),
(4, '1004', 'Fernando', 'Evaluador Pérez', 'fernando.perez@sigrado.edu.co', '123456', '3004445566', 'Ingeniería de Sistemas', 1),
(5, '1005', 'Juan Diego', 'Estudiante Gómez', 'juan.gomez@sigrado.edu.co', '123456', '3005556677', 'Ingeniería de Sistemas', 1),
(6, '1006', 'Laura Sofía', 'Pareja Torres', 'laura.torres@sigrado.edu.co', '123456', '3006667788', 'Ingeniería de Sistemas', 1)
ON CONFLICT (id) DO NOTHING;

-- Asignación de Roles
INSERT INTO usuario_rol (usuario_id, rol_id) VALUES
(1, 1), -- Carlos es Administrador
(1, 3), -- Carlos también es Docente (ejemplo de multirrol)
(2, 2), -- Martha es Comité
(3, 3), -- Elsa es Docente
(4, 3), -- Fernando es Docente
(5, 4), -- Juan Diego es Estudiante
(6, 4)  -- Laura Sofía es Estudiante
ON CONFLICT DO NOTHING;

-- Periodo Académico
INSERT INTO periodos (id, codigo, inicio_propuestas_banco, fin_propuestas_banco, inicio_nuevos_proyectos, fin_nuevos_proyectos, fin_aprobacion_propuesta, activo) VALUES
(1, '2026-2', '2026-08-01', '2026-09-15', '2026-08-10', '2026-10-30', '2026-11-20', 1)
ON CONFLICT (id) DO NOTHING;

-- Formatos Institucionales
INSERT INTO formatos (id, codigo, nombre, url_plantilla, activo) VALUES
(1, 'F-DC-124', 'Formato de Presentación de Propuesta de Trabajo de Grado', 'https://drive.google.com/templates/f-dc-124-propuesta', 1),
(2, 'F-DC-125', 'Formato de Informe Final de Trabajo de Grado', 'https://drive.google.com/templates/f-dc-125-informe-final', 1),
(3, 'F-DC-129', 'Rejilla de Evaluación de Trabajo de Grado', 'https://drive.google.com/templates/f-dc-129-rejilla', 1)
ON CONFLICT (id) DO NOTHING;

-- Ideas del Banco iniciales
INSERT INTO propuestas_banco (id, codigo, proponente_id, origen, titulo, tipo_modalidad, tipo_nivel, linea_investigacion, periodo_id, objetivo_general, descripcion, estado, disponible) VALUES
(1, 'BAN-00001', 3, 'Docente', 'Sistema Inteligente de Monitoreo de Cultivos con IoT y Visión por Computador', 'Desarrollo tecnologico', 'Profesional', 'Inteligencia Artificial y Telecomunicaciones', 1, 'Desarrollar una plataforma integral de monitoreo agrícola en tiempo real usando microcontroladores y algoritmos de clasificación de imágenes.', 'Implementación de sensores ESP32, Python backend y visión artificial para detección temprana de plagas.', 'Aprobada', 1),
(2, 'BAN-00002', 3, 'Docente', 'Módulo Web de Trazabilidad Ganadera basado en Blockchain para Pequeños Productores', 'Investigacion', 'Tecnologico', 'Sistemas de Información y Seguridad', 1, 'Evaluar la factibilidad y diseño de contratos inteligentes para el registro inmutable de sanidad animal.', 'Desarrollo de prototipo con smart contracts ligeros y frontend web amigable.', 'Aprobada', 1)
ON CONFLICT (id) DO NOTHING;
