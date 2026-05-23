-- BASE DE DATOS


-- ============================================================================
-- EXTENSIONES Y TIPOS DE DATOS
-- ============================================================================

-- Habilitamos la extensión pgcrypto para manejo avanzado de hashing de contraseñas
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Roles del Sistema Virtual
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_rol') THEN
        CREATE TYPE tipo_rol AS ENUM ('administrativo', 'docente', 'estudiante');
    END IF;
END $$;

-- Clasificación del Régimen Disciplinario
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gravedad_falta') THEN
        CREATE TYPE gravedad_falta AS ENUM ('leve', 'grave', 'gravisima');
    END IF;
END $$;

-- Estados de Sanciones Disciplinarias
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_sancion') THEN
        CREATE TYPE estado_sancion AS ENUM ('en_proceso', 'activa', 'cumplida', 'apelada');
    END IF;
END $$;




-- Tabla Raíz: Usuarios Globales
CREATE TABLE IF NOT EXISTS usuarios (
    usuario_id SERIAL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255),
    rol tipo_rol NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad
    CONSTRAINT pk_usuarios PRIMARY KEY (usuario_id),
    CONSTRAINT uq_usuarios_email UNIQUE (email),
    CONSTRAINT chk_email_valido CHECK (email LIKE '%_@__%.__%')
);

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios (email);
CREATE INDEX IF NOT EXISTS idx_usuarios_apellidos ON usuarios (apellido, nombre);


-- Tabla Maestra Académica: Facultades
CREATE TABLE IF NOT EXISTS facultades (
    facultad_id SERIAL,
    nombre VARCHAR(100) NOT NULL,
    codigo_facultad VARCHAR(10) NOT NULL, -- Ej: 'FAC-ING', 'FAC-SAL'
    
    CONSTRAINT pk_facultades PRIMARY KEY (facultad_id),
    CONSTRAINT uq_facultades_nombre UNIQUE (nombre),
    CONSTRAINT uq_facultades_codigo UNIQUE (codigo_facultad)
);


-- Tabla Maestra Académica: Carreras (Programas de Pregrado)
-- Relación (1 a Muchos): Una Facultad tiene muchas Carreras.
CREATE TABLE IF NOT EXISTS carreras (
    carrera_id SERIAL,
    facultad_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    codigo_carrera VARCHAR(10) NOT NULL, -- Ej: 'ING-SIS', 'ENF'
    
    CONSTRAINT pk_carreras PRIMARY KEY (carrera_id),
    CONSTRAINT uq_carreras_nombre UNIQUE (nombre),
    CONSTRAINT uq_carreras_codigo UNIQUE (codigo_carrera),
    CONSTRAINT fk_carreras_facultades FOREIGN KEY (facultad_id) 
        REFERENCES facultades(facultad_id) ON DELETE RESTRICT
);


-- Tabla Maestra de Infraestructura: Edificios
-- Representa los 9 bloques físicos para la simulación.
CREATE TABLE IF NOT EXISTS edificios (
    edificio_id SERIAL,
    nombre VARCHAR(100) NOT NULL,
    codigo_bloque VARCHAR(10) NOT NULL, -- Ej: 'BL-01', 'BL-ING'
    
    CONSTRAINT pk_edificios PRIMARY KEY (edificio_id),
    CONSTRAINT uq_edificios_codigo UNIQUE (codigo_bloque)
);


-- Tabla Maestra de Tiempos: Periodos Académicos
CREATE TABLE IF NOT EXISTS periodos_academicos (
    periodo_id SERIAL,
    codigo_periodo VARCHAR(10) NOT NULL, -- Ej: '2026-1'
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    actual BOOLEAN DEFAULT FALSE,
    
    CONSTRAINT pk_periodos_academicos PRIMARY KEY (periodo_id),
    CONSTRAINT uq_codigo_periodo UNIQUE (codigo_periodo),
    CONSTRAINT chk_fechas_periodo CHECK (fecha_fin > fecha_inicio)
);

CREATE INDEX IF NOT EXISTS idx_periodo_actual ON periodos_academicos (actual) WHERE actual = TRUE;


-- ============================================================================
-- INSERCIÓN DE DATOS SEMILLA (SEEDERS) REQUERIDOS
-- ============================================================================

-- A. Poblar las 5 Facultades Solicitadas
INSERT INTO facultades (nombre, codigo_facultad) VALUES
('Ingeniería', 'FAC-ING'),
('Ciencias Aplicadas', 'FAC-CIAP'),
('Ciencias Humanas', 'FAC-HUM'),
('Artes y Diseño', 'FAC-ART'),
('Ciencias de la Salud', 'FAC-SAL')
ON CONFLICT (nombre) DO NOTHING;


-- B. Poblar los 10 Programas de Pregrado distribuidos según sus Facultades
INSERT INTO carreras (facultad_id, nombre, codigo_carrera) VALUES
((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-ING'), 'Ingeniería de Sistemas', 'ING-SIS'),
((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-ING'), 'Ingeniería Civil', 'ING-CIV'),

((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-CIAP'), 'Matemáticas', 'LIC-MAT'),
((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-CIAP'), 'Física', 'LIC-FIS'),

((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-HUM'), 'Ciencias Sociales', 'CS-SOC'),
((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-HUM'), 'Trabajo Social', 'TRB-SOC'),

((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-ART'), 'Diseño Gráfico', 'DIS-GRA'),
((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-ART'), 'Artes Plásticas', 'ART-PLA'),

((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-SAL'), 'Enfermería', 'ENF'),
((SELECT facultad_id FROM facultades WHERE codigo_facultad = 'FAC-SAL'), 'Atención Prehospitalaria', 'APH')
ON CONFLICT (nombre) DO NOTHING;


-- C. Poblar los 9 Edificios de la Planta Física
INSERT INTO edificios (nombre, codigo_bloque) VALUES
('Bloque de Ingeniería', 'BL-ING'),
('Edificio de Ciencias Básicas', 'BL-CIEN'),
('Facultad de Ciencias Humanas', 'BL-HUM'),
('Edificio de Idiomas', 'BL-IDM'),
('Bloque de Ciencias de la Salud', 'BL-SAL'),
('Edificio de Postgrados', 'BL-POST'),
('Bloque de Artes y Diseño', 'BL-ART'),
('Centro de Innovación Virtual', 'BL-VIRT'),
('Edificio de Administración Central', 'BL-ADM')
ON CONFLICT (codigo_bloque) DO NOTHING;


-- D. Poblar Periodo Académico
INSERT INTO periodos_academicos (codigo_periodo, fecha_inicio, fecha_fin, actual) VALUES
('2026-1', '2026-01-20', '2026-05-30', TRUE)
ON CONFLICT (codigo_periodo) DO NOTHING;


-- ============================================================================
-- SUBTIPOS DE USUARIOS, AULAS Y PENSUM
-- ============================================================================


-- Subtipo: Estudiantes (Relación 1:1 con Usuarios)
CREATE TABLE IF NOT EXISTS estudiantes (
    estudiante_id INT,
    codigo_estudiantil VARCHAR(20) NOT NULL,
    carrera_id INT NOT NULL,
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    
    CONSTRAINT pk_estudiantes PRIMARY KEY (estudiante_id),
    CONSTRAINT uq_codigo_estudiantil UNIQUE (codigo_estudiantil),
    CONSTRAINT fk_estudiantes_usuarios FOREIGN KEY (estudiante_id) 
        REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    CONSTRAINT fk_estudiantes_carreras FOREIGN KEY (carrera_id) 
        REFERENCES carreras(carrera_id) ON DELETE RESTRICT
);

-- Subtipo: Docentes (Relación 1:1 con Usuarios)
CREATE TABLE IF NOT EXISTS docentes (
    docente_id INT,
    codigo_docente VARCHAR(20) NOT NULL,
    titulo_profesional VARCHAR(100) NOT NULL,
    escalafon VARCHAR(50) DEFAULT 'Asociado',
    
    CONSTRAINT pk_docentes PRIMARY KEY (docente_id),
    CONSTRAINT uq_codigo_docente UNIQUE (codigo_docente),
    CONSTRAINT fk_docentes_usuarios FOREIGN KEY (docente_id) 
        REFERENCES usuarios(usuario_id) ON DELETE CASCADE
);

-- Subtipo: Administrativos (Relación 1:1 con Usuarios)
CREATE TABLE IF NOT EXISTS administrativos (
    administrativo_id INT,
    cargo VARCHAR(100) NOT NULL,
    departamento VARCHAR(100) NOT NULL,
    
    CONSTRAINT pk_administrativos PRIMARY KEY (administrativo_id),
    CONSTRAINT fk_administrativos_usuarios FOREIGN KEY (administrativo_id) 
        REFERENCES usuarios(usuario_id) ON DELETE CASCADE
);

-- Aulas
CREATE TABLE IF NOT EXISTS aulas (
    aula_id SERIAL,
    edificio_id INT NOT NULL,
    piso INT NOT NULL,
    numero_aula VARCHAR(10) NOT NULL,
    capacidad INT NOT NULL DEFAULT 35,
    
    CONSTRAINT pk_aulas PRIMARY KEY (aula_id),
    CONSTRAINT fk_aulas_edificios FOREIGN KEY (edificio_id) 
        REFERENCES edificios(edificio_id) ON DELETE CASCADE,
    CONSTRAINT chk_piso_valido CHECK (piso BETWEEN 1 AND 5),
    CONSTRAINT uq_aula_especifica UNIQUE (edificio_id, piso, numero_aula)
);

-- 9 Bloques x 5 Pisos x 4 Aulas = 180 Aulas
DO $$
DECLARE
    r_edificio RECORD;
    v_piso INT;
    v_aula INT;
    v_num_aula VARCHAR(10);
BEGIN
    -- Recorremos cada uno de los 9 edificios guardados en el Paso 2
    FOR r_edificio IN SELECT edificio_id FROM edificios LOOP
        -- Iteramos los 5 pisos por edificio
        FOR v_piso IN 1..5 LOOP
            -- Iteramos las 4 aulas por piso
            FOR v_aula IN 1..4 LOOP
                -- Construimos la nomenclatura del salón (Ej: Piso 1, Aula 4 = "104")
                v_num_aula := (v_piso * 100 + v_aula)::VARCHAR;
                
                INSERT INTO aulas (edificio_id, piso, numero_aula, capacidad)
                VALUES (r_edificio.edificio_id, v_piso, v_num_aula, 40)
                ON CONFLICT (edificio_id, piso, numero_aula) DO NOTHING;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;



-- Materias
CREATE TABLE IF NOT EXISTS materias (
    materia_id SERIAL,
    carrera_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    codigo_materia VARCHAR(15) NOT NULL,
    creditos INT NOT NULL CHECK (creditos BETWEEN 1 AND 8),
    
    CONSTRAINT pk_materias PRIMARY KEY (materia_id),
    CONSTRAINT uq_codigo_materia UNIQUE (codigo_materia),
    CONSTRAINT fk_materias_carreras FOREIGN KEY (carrera_id) 
        REFERENCES carreras(carrera_id) ON DELETE RESTRICT
);

-- Prerrequisitos de Materias 
CREATE TABLE IF NOT EXISTS prerrequisitos (
    materia_id INT,
    materia_prerrequisito_id INT,
    
    CONSTRAINT pk_prerrequisitos PRIMARY KEY (materia_id, materia_prerrequisito_id),
    CONSTRAINT fk_materia_base FOREIGN KEY (materia_id) 
        REFERENCES materias(materia_id) ON DELETE CASCADE,
    CONSTRAINT fk_materia_requisito FOREIGN KEY (materia_prerrequisito_id) 
        REFERENCES materias(materia_id) ON DELETE RESTRICT,
    -- Evita que una materia sea prerrequisito de sí misma de forma directa
    CONSTRAINT chk_no_autorreferencia CHECK (materia_id <> materia_prerrequisito_id)
);

-- Historial Académico Histórico
CREATE TABLE IF NOT EXISTS historial_academico (
    historial_id SERIAL,
    estudiante_id INT NOT NULL,
    materia_id INT NOT NULL,
    periodo_id INT NOT NULL,
    nota_final NUMERIC(3,2) NOT NULL CHECK (nota_final BETWEEN 0.0 AND 5.0),
    aprobada BOOLEAN GENERATED ALWAYS AS (nota_final >= 3.0) STORED,
    
    CONSTRAINT pk_historial_academico PRIMARY KEY (historial_id),
    CONSTRAINT fk_historial_estudiantes FOREIGN KEY (estudiante_id) 
        REFERENCES estudiantes(estudiante_id) ON DELETE CASCADE,
    CONSTRAINT fk_historial_materias FOREIGN KEY (materia_id) 
        REFERENCES materias(materia_id) ON DELETE RESTRICT,
    CONSTRAINT fk_historial_periodos FOREIGN KEY (periodo_id) 
        REFERENCES periodos_academicos(periodo_id) ON DELETE RESTRICT,
    CONSTRAINT uq_estudiante_materia_periodo UNIQUE (estudiante_id, materia_id, periodo_id)
);

-- Cursos (Secciones o Grupos Abiertos en el semestre actual)
CREATE TABLE IF NOT EXISTS cursos (
    curso_id SERIAL,
    materia_id INT NOT NULL,
    docente_id INT NOT NULL,
    periodo_id INT NOT NULL,
    nombre_grupo VARCHAR(10) NOT NULL, -- Ej: 'Grupo 01', 'Paralelo B'
    cupo_maximo INT NOT NULL DEFAULT 35,
    
    CONSTRAINT pk_cursos PRIMARY KEY (curso_id),
    CONSTRAINT fk_cursos_materias FOREIGN KEY (materia_id) 
        REFERENCES materias(materia_id) ON DELETE RESTRICT,
    CONSTRAINT fk_cursos_docentes FOREIGN KEY (docente_id) 
        REFERENCES docentes(docente_id) ON DELETE RESTRICT,
    CONSTRAINT fk_cursos_periodos FOREIGN KEY (periodo_id) 
        REFERENCES periodos_academicos(periodo_id) ON DELETE RESTRICT,
    CONSTRAINT uq_curso_unico UNIQUE (materia_id, periodo_id, nombre_grupo)
);

-- Horarios de Clases de los Cursos
CREATE TABLE IF NOT EXISTS horarios_clases (
    horario_id SERIAL,
    curso_id INT NOT NULL,
    aula_id INT NOT NULL,
    dia_semana INT NOT NULL, -- 1=Lunes, 2=Martes, ..., 6=Sábado
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    
    CONSTRAINT pk_horarios_clases PRIMARY KEY (horario_id),
    CONSTRAINT fk_horarios_cursos FOREIGN KEY (curso_id) 
        REFERENCES cursos(curso_id) ON DELETE CASCADE,
    CONSTRAINT fk_horarios_aulas FOREIGN KEY (aula_id) 
        REFERENCES aulas(aula_id) ON DELETE RESTRICT,
    CONSTRAINT chk_dia_semana CHECK (dia_semana BETWEEN 1 AND 6),
    CONSTRAINT chk_rango_horas CHECK (hora_fin > hora_inicio)
);

-- Índices de rendimiento académico clave para cruces de horarios rápidos
CREATE INDEX IF NOT EXISTS idx_horarios_aula_dia ON horarios_clases (aula_id, dia_semana);
CREATE INDEX IF NOT EXISTS idx_cursos_periodo ON cursos (periodo_id);

-- ============================================================================
-- INSCRIPCIONES, NOTAS, EVALUACIÓN DOCENTE, DISCIPLINA Y RESERVAS
-- ============================================================================


-- Inscripciones de Materias
CREATE TABLE IF NOT EXISTS inscripciones (
    inscripcion_id SERIAL,
    estudiante_id INT NOT NULL,
    curso_id INT NOT NULL,
    fecha_inscripcion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad
    CONSTRAINT pk_inscripciones PRIMARY KEY (inscripcion_id),
    CONSTRAINT fk_inscripciones_estudiantes FOREIGN KEY (estudiante_id) 
        REFERENCES estudiantes(estudiante_id) ON DELETE CASCADE,
    CONSTRAINT fk_inscripciones_cursos FOREIGN KEY (curso_id) 
        REFERENCES cursos(curso_id) ON DELETE RESTRICT,
    -- Evita que un estudiante se inscriba dos veces al mismo curso/grupo
    CONSTRAINT uq_estudiante_curso_unico UNIQUE (estudiante_id, curso_id)
);

-- Evaluaciones por Curso
-- Definida por el docente
CREATE TABLE IF NOT EXISTS evaluaciones_curso (
    evaluacion_id SERIAL,
    curso_id INT NOT NULL,
    nombre_evaluacion VARCHAR(100) NOT NULL, -- Ej: 'Primer Parcial', 'Proyecto Final'
    porcentaje INT NOT NULL,
    fecha_limite TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Restricciones 
    CONSTRAINT pk_evaluaciones_curso PRIMARY KEY (evaluacion_id),
    CONSTRAINT fk_evaluaciones_cursos FOREIGN KEY (curso_id) 
        REFERENCES cursos(curso_id) ON DELETE CASCADE,
    CONSTRAINT chk_porcentaje_positivo CHECK (porcentaje BETWEEN 1 AND 100)
);

-- Calificaciones Estudiantes
-- Almacena la nota numérica obtenida por cada estudiante en cada corte de evaluación.
CREATE TABLE IF NOT EXISTS notas_estudiantes (
    nota_id SERIAL,
    inscripcion_id INT NOT NULL,
    evaluacion_id INT NOT NULL,
    calificacion NUMERIC(3,2) NOT NULL,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones
    CONSTRAINT pk_notas_estudiantes PRIMARY KEY (nota_id),
    CONSTRAINT fk_notas_inscripciones FOREIGN KEY (inscripcion_id) 
        REFERENCES inscripciones(inscripcion_id) ON DELETE CASCADE,
    CONSTRAINT fk_notas_evaluaciones FOREIGN KEY (evaluacion_id) 
        REFERENCES evaluaciones_curso(evaluacion_id) ON DELETE CASCADE,
    -- Validación de escala de calificación obligatoria (0.0 a 5.0)
    CONSTRAINT chk_rango_calificacion CHECK (calificacion BETWEEN 0.0 AND 5.0),
    CONSTRAINT uq_nota_por_evaluacion UNIQUE (inscripcion_id, evaluacion_id)
);

-- Sistema de Evaluación Docente
-- Sección para que los alumnos califiquen de 1 a 5 a sus respectivos docentes.
CREATE TABLE IF NOT EXISTS evaluacion_docente (
    evaluacion_docente_id SERIAL,
    inscripcion_id INT NOT NULL, -- Garantiza que el alumno cursó la materia con ese docente
    calificacion_numerica INT NOT NULL, -- Escala fija del 1 al 5
    comentarios TEXT,
    fecha_evaluacion DATE DEFAULT CURRENT_DATE,
    
    -- Restricciones
    CONSTRAINT pk_evaluacion_docente PRIMARY KEY (evaluacion_docente_id),
    CONSTRAINT fk_evaluacion_inscripcion FOREIGN KEY (inscripcion_id) 
        REFERENCES inscripciones(inscripcion_id) ON DELETE CASCADE,
    -- Restricción estricta de calificación de 1 a 5
    CONSTRAINT chk_escala_docente CHECK (calificacion_numerica BETWEEN 1 AND 5),
    CONSTRAINT uq_evaluacion_docente_unica UNIQUE (inscripcion_id)
);




-- Sistema Central de Reservas de Aulas
-- Permite tanto a docentes como a estudiantes reservar
CREATE TABLE IF NOT EXISTS reservas_aulas (
    reserva_id SERIAL,
    usuario_id INT NOT NULL, -- Apoya el polimorfismo (puede ser estudiante o docente)
    aula_id INT NOT NULL,
    fecha_reserva DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha_solicitud TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones
    CONSTRAINT pk_reservas_aulas PRIMARY KEY (reserva_id),
    CONSTRAINT fk_reservas_usuarios FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservas_aulas FOREIGN KEY (aula_id) 
        REFERENCES aulas(aula_id) ON DELETE RESTRICT,
    CONSTRAINT chk_rango_horas_reserva CHECK (hora_fin > hora_inicio),
    -- Bloqueo preventivo: La reserva es por horas, no puede exceder el fin del día
    CONSTRAINT chk_fecha_reserva_futura CHECK (fecha_reserva >= CURRENT_DATE)
);

-- Registro Disciplinario
-- Administrado exclusivamente por el personal administrativo.
CREATE TABLE IF NOT EXISTS registro_disciplinario (
    falta_id SERIAL,
    usuario_id INT NOT NULL, -- El infractor (estudiante o docente)
    administrativo_id INT NOT NULL, -- El administrativo que emite y procesa la sanción
    titulo_falta VARCHAR(150) NOT NULL, -- Ej: 'Plagio de tesis', 'Suplantación de identidad'
    descripcion TEXT NOT NULL,
    gravedad gravedad_falta NOT NULL,
    estado estado_sancion DEFAULT 'en_proceso',
    fecha_incidente DATE NOT NULL,
    fecha_inicio_sancion DATE,
    fecha_fin_sancion DATE,
    
    -- Restricciones
    CONSTRAINT pk_registro_disciplinario PRIMARY KEY (falta_id),
    CONSTRAINT fk_disciplina_infractor FOREIGN KEY (usuario_id) 
        REFERENCES usuarios(usuario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_disciplina_administrativo FOREIGN KEY (administrativo_id) 
        REFERENCES administrativos(administrativo_id) ON DELETE RESTRICT,
    CONSTRAINT chk_rango_fechas_sancion CHECK (fecha_fin_sancion >= fecha_inicio_sancion)
);

-- ============================================================================
-- ÍNDICES OPERATIVOS
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_inscripciones_estudiante ON inscripciones (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_hora ON reservas_aulas (fecha_reserva, hora_inicio, hora_fin);
CREATE INDEX IF NOT EXISTS idx_disciplina_activo ON registro_disciplinario (usuario_id, estado) WHERE estado = 'activa';







