-- DATOS DE PRUEBA

-- =========================================================
-- DESACTIVAR TEMPORALMENTE LOS TRIGGERS
-- =========================================================
ALTER TABLE usuarios DISABLE TRIGGER ALL;
ALTER TABLE estudiantes DISABLE TRIGGER ALL;
ALTER TABLE docentes DISABLE TRIGGER ALL;
ALTER TABLE administrativos DISABLE TRIGGER ALL;
ALTER TABLE aulas DISABLE TRIGGER ALL;
ALTER TABLE materias DISABLE TRIGGER ALL;
ALTER TABLE cursos DISABLE TRIGGER ALL;
ALTER TABLE horarios_clases DISABLE TRIGGER ALL;
ALTER TABLE inscripciones DISABLE TRIGGER ALL;
ALTER TABLE evaluaciones_curso DISABLE TRIGGER ALL;
ALTER TABLE notas_estudiantes DISABLE TRIGGER ALL;
ALTER TABLE evaluacion_docente DISABLE TRIGGER ALL;
ALTER TABLE reservas_aulas DISABLE TRIGGER ALL;
ALTER TABLE registro_disciplinario DISABLE TRIGGER ALL;

-- =========================================================
-- DOCENTES (300)
-- =========================================================

WITH nuevos_usuarios AS (
    INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
    SELECT
        'Docente_' || gs,
        'Apellido_' || gs,
        'docente' || gs || '@demo.com',
        'demo',
        'docente'::tipo_rol
    FROM generate_series(1,300) gs
    ON CONFLICT (email) DO NOTHING
    RETURNING usuario_id -- Solo captura los IDs de los usuarios que SÍ se crearon nuevos
)
INSERT INTO docentes (docente_id, codigo_docente, titulo_profesional, escalafon)
SELECT
    usuario_id,
    'DOC-' || LPAD(usuario_id::TEXT, 5, '0'),
    'Magister en Educación',
    'Asociado'
FROM nuevos_usuarios;


-- =========================================================
-- ADMINISTRATIVOS (200)
-- =========================================================

WITH nuevos_usuarios AS (
    INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
    SELECT
        'Admin_' || gs,
        'Apellido_' || gs,
        'admin' || gs || '@demo.com',
        'demo',
        'administrativo'::tipo_rol
    FROM generate_series(1,200) gs
    ON CONFLICT (email) DO NOTHING
    RETURNING usuario_id
)
INSERT INTO administrativos (administrativo_id, cargo, departamento)
SELECT
    usuario_id,
    CASE
        WHEN random() < 0.3 THEN 'Coordinador'
        WHEN random() < 0.6 THEN 'Auxiliar'
        ELSE 'Director'
    END,
    CASE
        WHEN random() < 0.2 THEN 'Registro Académico'
        WHEN random() < 0.4 THEN 'Bienestar'
        WHEN random() < 0.6 THEN 'Financiera'
        WHEN random() < 0.8 THEN 'Decanatura'
        ELSE 'TI'
    END
FROM nuevos_usuarios;

-- =========================================================
-- ESTUDIANTES (3000)
-- =========================================================

WITH nuevos_usuarios AS (
    INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
    SELECT
        'Estudiante_' || gs,
        'Apellido_' || gs,
        'estudiante' || gs || '@demo.com',
        'demo',
        'estudiante'::tipo_rol
    FROM generate_series(1,3000) gs
    ON CONFLICT (email) DO NOTHING
    RETURNING usuario_id
)
INSERT INTO estudiantes (estudiante_id, codigo_estudiantil, carrera_id, fecha_ingreso)
SELECT
    usuario_id,
    'EST-' || LPAD(usuario_id::TEXT, 6, '0'),
    (
        SELECT carrera_id
        FROM carreras
        ORDER BY random()
        LIMIT 1
    ),
    CURRENT_DATE - ((random() * 1200)::INT)
FROM nuevos_usuarios;

-- =========================================================
-- MATERIAS (100)
-- =========================================================

INSERT INTO materias (
    codigo_materia,
    nombre,
    creditos,
    carrera_id
)
SELECT
    'MAT-' || LPAD(gs::TEXT, 3, '0'),
    'Materia de Prueba ' || gs,
    (ARRAY[2, 3, 4])[floor(random() * 3 + 1)],
    (
        SELECT facultad_id
        FROM facultades
        ORDER BY random()
        LIMIT 1
    )
FROM generate_series(1,50) gs
ON CONFLICT (codigo_materia) DO NOTHING;

-- =========================================================
-- PRERREQUISITOS (15) 
-- =========================================================

INSERT INTO prerrequisitos (
    materia_id,
    materia_prerrequisito_id
)
SELECT
    m1.materia_id,
    m2.materia_id
FROM materias m1
JOIN materias m2 ON m1.materia_id <> m2.materia_id
WHERE m1.materia_id IN (
    SELECT materia_id 
    FROM materias 
    ORDER BY random() 
    LIMIT 15
)
ORDER BY random()
LIMIT 15
ON CONFLICT DO NOTHING;

-- =========================================================
-- CURSOS (200)
-- =========================================================

INSERT INTO cursos (
    materia_id,
    docente_id,
    periodo_id,
    nombre_grupo,
    cupo_maximo
)
SELECT
    (
        SELECT materia_id
        FROM materias
        ORDER BY random()
        LIMIT 1
    ),
    (
        SELECT docente_id
        FROM docentes
        ORDER BY random()
        LIMIT 1
    ),
    (
        SELECT periodo_id
        FROM periodos_academicos
        WHERE actual = TRUE
        LIMIT 1
    ),
    'G-' || gs,
    35 + (random() * 10)::INT
FROM generate_series(1,200) gs;

-- =========================================================
-- HORARIOS DE CLASES
-- =========================================================

INSERT INTO horarios_clases (
    curso_id,
    aula_id,
    dia_semana,
    hora_inicio,
    hora_fin
)
SELECT
    c.curso_id,
    (
        SELECT aula_id
        FROM aulas
        ORDER BY random()
        LIMIT 1
    ),
    (random() * 5 + 1)::INT,
    v.hora_seleccionada::TIME,
    (v.hora_seleccionada::TIME + INTERVAL '2 hours')::TIME -- Asigna automáticamente 2 horas de duración
FROM cursos c
CROSS JOIN LATERAL (
    SELECT (
        ARRAY[
            '06:00',
            '08:00',
            '10:00',
            '14:00',
            '16:00',
            '18:00'
        ]
    )[floor(random() * 6 + 1)] AS hora_seleccionada
) v;

-- =========================================================
-- EVALUACIONES POR CURSO
-- =========================================================

INSERT INTO evaluaciones_curso (
    curso_id,
    nombre_evaluacion,
    porcentaje,
    fecha_limite
)
SELECT
    curso_id,
    'Primer Parcial',
    30,
    CURRENT_TIMESTAMP + INTERVAL '30 days'
FROM cursos;

INSERT INTO evaluaciones_curso (
    curso_id,
    nombre_evaluacion,
    porcentaje,
    fecha_limite
)
SELECT
    curso_id,
    'Segundo Parcial',
    30,
    CURRENT_TIMESTAMP + INTERVAL '60 days'
FROM cursos;

INSERT INTO evaluaciones_curso (
    curso_id,
    nombre_evaluacion,
    porcentaje,
    fecha_limite
)
SELECT
    curso_id,
    'Proyecto Final',
    40,
    CURRENT_TIMESTAMP + INTERVAL '90 days'
FROM cursos;

-- =========================================================
-- NOTAS DE ESTUDIANTES
-- =========================================================

INSERT INTO notas_estudiantes (
    inscripcion_id,
    evaluacion_id,
    calificacion
)
SELECT
    i.inscripcion_id,
    e.evaluacion_id,
    ROUND((random() * 5)::numeric, 2)
FROM inscripciones i
JOIN evaluaciones_curso e
    ON e.curso_id = i.curso_id
ON CONFLICT DO NOTHING;

-- =========================================================
-- HISTORIAL ACADÉMICO
-- =========================================================

INSERT INTO historial_academico (
    estudiante_id,
    materia_id,
    periodo_id,
    nota_final
)
SELECT
    (
        SELECT estudiante_id
        FROM estudiantes
        ORDER BY random()
        LIMIT 1
    ),
    (
        SELECT materia_id
        FROM materias
        ORDER BY random()
        LIMIT 1
    ),
    (
        SELECT periodo_id
        FROM periodos_academicos
        LIMIT 1
    ),
    ROUND((random() * 5)::numeric, 2)
FROM generate_series(1,5000)
ON CONFLICT DO NOTHING;

-- =========================================================
-- RESERVAS DE AULAS
-- =========================================================

INSERT INTO reservas_aulas (
    usuario_id,
    aula_id,
    fecha_reserva,
    hora_inicio,
    hora_fin,
    motivo
)
SELECT
    (
        SELECT usuario_id
        FROM usuarios
        ORDER BY random()
        LIMIT 1
    ),
    (
        SELECT aula_id
        FROM aulas
        ORDER BY random()
        LIMIT 1
    ),
    CURRENT_DATE + ((random() * 30)::INT),
    '08:00',
    '10:00',
    'Actividad Académica'
FROM generate_series(1,1000);

-- =========================================================
-- REGISTROS DISCIPLINARIOS
-- =========================================================

INSERT INTO registro_disciplinario (
    usuario_id,
    administrativo_id,
    titulo_falta,
    descripcion,
    gravedad,
    estado,
    fecha_incidente,
    fecha_inicio_sancion,
    fecha_fin_sancion
)
SELECT
    (
        SELECT usuario_id
        FROM usuarios
        WHERE rol IN ('estudiante', 'docente')
        ORDER BY random()
        LIMIT 1
    ),
    (
        SELECT administrativo_id
        FROM administrativos
        ORDER BY random()
        LIMIT 1
    ),
    'Falta disciplinaria',
    'Incumplimiento del reglamento institucional.',
    (
        ARRAY[
            'leve',
            'grave',
            'gravisima'
        ]
    )[floor(random() * 3 + 1)]::gravedad_falta,
    (
        ARRAY[
            'en_proceso',
            'activa',
            'cumplida'
        ]
    )[floor(random() * 3 + 1)]::estado_sancion,
    CURRENT_DATE - ((random() * 60)::INT),
    CURRENT_DATE - ((random() * 30)::INT),
    CURRENT_DATE + ((random() * 30)::INT)
FROM generate_series(1,150);

-- =========================================================
-- EVALUACIÓN DOCENTE
-- =========================================================

INSERT INTO evaluacion_docente (
    inscripcion_id,
    calificacion_numerica,
    comentarios
)
SELECT
    inscripcion_id,
    (random() * 4 + 1)::INT,
    'Buen desempeño docente.'
FROM inscripciones
ORDER BY random()
LIMIT 3000;

ALTER TABLE usuarios ENABLE TRIGGER ALL;
ALTER TABLE estudiantes ENABLE TRIGGER ALL;
ALTER TABLE docentes ENABLE TRIGGER ALL;
ALTER TABLE administrativos ENABLE TRIGGER ALL;
ALTER TABLE aulas ENABLE TRIGGER ALL;
ALTER TABLE materias ENABLE TRIGGER ALL;
ALTER TABLE cursos ENABLE TRIGGER ALL;
ALTER TABLE horarios_clases ENABLE TRIGGER ALL;
ALTER TABLE inscripciones ENABLE TRIGGER ALL;
ALTER TABLE evaluaciones_curso ENABLE TRIGGER ALL;
ALTER TABLE notas_estudiantes ENABLE TRIGGER ALL;
ALTER TABLE evaluacion_docente ENABLE TRIGGER ALL;
ALTER TABLE reservas_aulas ENABLE TRIGGER ALL;
ALTER TABLE registro_disciplinario ENABLE TRIGGER ALL;