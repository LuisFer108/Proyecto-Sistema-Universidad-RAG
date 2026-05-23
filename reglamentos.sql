-- ============================================================
-- REGLAMENTOS UNIVERSITARIOS
-- Script generado a partir de Reglamentos.txt
-- Compatible con PostgreSQL
-- ============================================================

-- -------------------------------------------------------
-- 1. TABLAS
-- -------------------------------------------------------

CREATE TABLE IF NOT EXISTS reglamentos (
    reglamento_id   SERIAL PRIMARY KEY,
    codigo          VARCHAR(50)  NOT NULL UNIQUE,
    titulo          VARCHAR(200) NOT NULL,
    categoria       VARCHAR(80)  NOT NULL,  -- 'beca' | 'credito' | 'academico' | 'disciplinario' | 'grupos' | 'servicios' | 'general'
    aplica_a        VARCHAR(100),           -- 'estudiantes_becados' | 'docentes' | 'todos' | etc.
    vigente         BOOLEAN      DEFAULT TRUE,
    fecha_registro  DATE         DEFAULT CURRENT_DATE,
    descripcion     TEXT
);

CREATE TABLE IF NOT EXISTS reglamento_articulos (
    articulo_id     SERIAL PRIMARY KEY,
    reglamento_id   INT          NOT NULL REFERENCES reglamentos(reglamento_id) ON DELETE CASCADE,
    numero_articulo VARCHAR(20),            -- 'Art. 1', 'Reg. 3', etc.
    titulo_articulo VARCHAR(200),
    contenido       TEXT         NOT NULL,
    tipo            VARCHAR(50)  DEFAULT 'norma',  -- 'norma' | 'condicion' | 'sancion' | 'proceso' | 'nota'
    orden           INT          NOT NULL,
    activo          BOOLEAN      DEFAULT TRUE
);

-- Índice full-text para búsqueda por palabras clave
CREATE INDEX IF NOT EXISTS idx_reg_art_fts
    ON reglamento_articulos USING gin(to_tsvector('spanish', contenido));

CREATE INDEX IF NOT EXISTS idx_reg_categoria
    ON reglamentos(categoria);

CREATE INDEX IF NOT EXISTS idx_reg_activo
    ON reglamentos(vigente);


-- -------------------------------------------------------
-- 2. DATOS — REGLAMENTOS
-- -------------------------------------------------------

INSERT INTO reglamentos (codigo, titulo, categoria, aplica_a, descripcion) VALUES
('REG-BEC-GEN',  'Reglamento General de Becados y Créditos',  'beca',          'estudiantes_becados_creditos', 'Normas comunes a todos los estudiantes con beca o crédito educativo.'),
('REG-BEC-DEP',  'Reglamento Beca Deportes',                  'beca',          'estudiantes_beca_deportes',    'Condiciones para mantener la beca otorgada por méritos deportivos.'),
('REG-BEC-TAL',  'Reglamento Beca Talento',                   'beca',          'estudiantes_beca_talento',     'Condiciones para mantener la beca otorgada por talento académico.'),
('REG-BEC-SAP',  'Reglamento Beca Sapiencia',                 'beca',          'estudiantes_beca_sapiencia',   'Condiciones para mantener la beca Sapiencia, incluye servicio social.'),
('REG-BEC-VR',   'Reglamento Beca Vélez Reyes',               'beca',          'estudiantes_beca_velez_reyes', 'Condiciones para mantener la beca Vélez Reyes, incluye asistencia a reuniones.'),
('REG-CRE-SUF',  'Reglamento Crédito SUFI',                   'credito',       'estudiantes_credito_sufi',     'Condiciones del crédito educativo con SUFI.'),
('REG-CRE-SAP',  'Reglamento Crédito Sapiencia',              'credito',       'estudiantes_credito_sapiencia','Condiciones del crédito educativo con Sapiencia, incluye servicio social.'),
('REG-CRE-ICE',  'Reglamento Crédito ICETEX',                 'credito',       'estudiantes_credito_icetex',   'Condiciones del crédito educativo con ICETEX.'),
('REG-ACA',      'Reglamento Académico',                      'academico',     'estudiantes',                  'Normas generales del proceso académico: admisiones, materias, graduación y permanencia.'),
('REG-DIS',      'Reglamento Disciplinario',                  'disciplinario', 'estudiantes',                  'Clasificación de faltas, sanciones y procesos disciplinarios para estudiantes.'),
('REG-GRP-DEP',  'Reglamento Grupos Deportivos',              'grupos',        'estudiantes_grupos_deportivos', 'Normas de participación y permanencia en grupos deportivos universitarios.'),
('REG-GRP-EST',  'Reglamento Grupos Estudiantiles',           'grupos',        'estudiantes_grupos_estudiantiles','Normas de operación de los grupos estudiantiles.'),
('REG-GRP-ART',  'Reglamento Grupos Artísticos',              'grupos',        'comunidad_educativa',          'Normas de los cursos y grupos artísticos gestionados por Bienestar.'),
('REG-IDI',      'Reglamento Idiomas',                        'servicios',     'comunidad_educativa',          'Normas del departamento de idiomas y certificación lingüística.'),
('REG-MON',      'Reglamento Monitores',                      'servicios',     'estudiantes',                  'Condiciones para ser monitor académico.'),
('REG-DOC',      'Reglamento Docentes',                       'docentes',      'docentes',                     'Normas de permanencia, evaluación y ascenso del cuerpo docente.'),
('REG-GEN',      'Reglamento General',                        'general',       'todos',                        'Estructura organizacional, comités y departamentos de la universidad.');


-- -------------------------------------------------------
-- 3. DATOS — ARTÍCULOS
-- -------------------------------------------------------

-- REG-BEC-GEN
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-GEN'), 'Art. 1', 'Todos los estudiantes becados deben graduarse. Los estudiantes con crédito acuerdan con el prestamista las condiciones de retiro.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-GEN'), 'Art. 2', 'Todos los estudiantes becados o con créditos deben matricular al menos 5 materias por semestre.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-GEN'), 'Art. 3', 'Todos los estudiantes becados o con créditos deben cumplir con el reglamento académico y disciplinario de la universidad.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-GEN'), 'Art. 4', 'Todos los estudiantes becados o con créditos deben seguir el reglamento de sus respectivas becas o contratos.', 'norma', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-GEN'), 'Art. 5', 'Los costos de materias canceladas los asume el estudiante.', 'condicion', 5);

-- REG-BEC-DEP
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 1', 'Mantener durante todo el pregrado la permanencia en el grupo deportivo por el que ganó la beca.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 2', 'Mantener las metas deportivas establecidas al momento de aceptar la beca.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 3', 'Mantener un promedio acumulado mínimo de 3.2.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 4', 'No perder más de una materia por semestre.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 5', 'No perder una materia más de 1 vez.', 'condicion', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 6', 'No perder más de 3 materias en todo el pregrado.', 'condicion', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 7', 'No cancelar materias.', 'condicion', 7),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-DEP'), 'Art. 8', 'No repetir más de 1 vez la materia perdida.', 'condicion', 8);

-- REG-BEC-TAL
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-TAL'), 'Art. 1', 'Mantener promedio acumulado mínimo de 3.4.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-TAL'), 'Art. 2', 'No perder más de una materia por semestre.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-TAL'), 'Art. 3', 'No perder una materia más de 1 vez.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-TAL'), 'Art. 4', 'No perder más de 2 materias en todo el pregrado.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-TAL'), 'Art. 5', 'No cancelar más de 1 materia en todo el pregrado.', 'condicion', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-TAL'), 'Art. 6', 'No repetir más de 1 vez la materia cancelada o perdida.', 'condicion', 6);

-- REG-BEC-SAP
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-SAP'), 'Art. 1', 'No perder ninguna materia durante el pregrado.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-SAP'), 'Art. 2', 'No cancelar más de 1 materia en todo el pregrado.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-SAP'), 'Art. 3', 'No repetir más de 1 vez la materia cancelada.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-SAP'), 'Art. 4', 'Mantener un promedio acumulado mínimo de 3.3.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-SAP'), 'Art. 5', 'Realizar semestralmente 40 horas de servicio social previamente aprobado por Sapiencia mediante planillas. Se entregará al final el proceso en planillas firmadas por el jefe del lugar donde se realizaron.', 'condicion', 5);

-- REG-BEC-VR
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-VR'), 'Art. 1', 'No perder ninguna materia durante el pregrado.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-VR'), 'Art. 2', 'No cancelar más de 1 materia en todo el pregrado.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-VR'), 'Art. 3', 'No repetir más de 1 vez la materia cancelada.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-VR'), 'Art. 4', 'Mantener un promedio acumulado mínimo de 3.8.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-BEC-VR'), 'Art. 5', 'Asistir al menos al 80% de las reuniones enviadas vía WhatsApp o correo estudiantil, o faltar informando una excusa válida.', 'condicion', 5);

-- REG-CRE-SUF
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 1', 'Mantener promedio acumulado mínimo de 3.2.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 2', 'Haber aprobado todas las materias.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 3', 'No cancelar más de 2 materias en todo el pregrado.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 4', 'No repetir más de 1 vez la materia cancelada.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 5', 'Deben girarse mensualmente los montos acordados a la hora de firmar el crédito.', 'norma', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 6', 'De no girarse por un mes, SUFI se contactará con el codeudor para que asuma ese giro y con el estudiante para preguntar la causa. Si es válida, se le dará un plazo para pagar.', 'proceso', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 7', 'De no girarse por dos meses, se repite el proceso del artículo anterior.', 'proceso', 7),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 8', 'De no girarse por tres meses, se inicia proceso con centrales de riesgo y no renovación del crédito para el siguiente semestre, según sea el caso.', 'sancion', 8),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SUF'), 'Art. 9', 'Para más información contactar directamente a SUFI.', 'nota', 9);

-- REG-CRE-SAP
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 1', 'Graduarse en el tiempo estipulado del pregrado más 1 semestre adicional.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 2', 'Mantener promedio acumulado mínimo de 3.2.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 3', 'No perder materias.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 4', 'No cancelar más de 3 materias en todo el pregrado.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 5', 'No repetir más de 1 vez la materia cancelada.', 'condicion', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 6', 'Deben girarse los montos estipulados a la hora de firmar el crédito.', 'norma', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 7', 'Deben cumplirse semestralmente 40 horas de servicio social previamente aprobado por Sapiencia, con planillas firmadas por el jefe del lugar donde se realizaron.', 'condicion', 7),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 8', 'De no cumplir con los pagos, se inicia proceso de investigación del caso. Dependiendo de la causa, se aplazan los pagos, se perdonan o se cobran al codeudor. Sin causa válida, inician proceso en central de riesgo con el codeudor.', 'proceso', 8),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-SAP'), 'Art. 9', 'Para más información contactar directamente a Sapiencia.', 'nota', 9);

-- REG-CRE-ICE
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 1', 'Graduarse en el tiempo estipulado del pregrado más 1 semestre adicional.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 2', 'Mantener promedio acumulado mínimo de 3.1.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 3', 'No perder más de 3 materias en todo el pregrado.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 4', 'No cancelar más de 3 materias en todo el pregrado.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 5', 'No repetir más de 1 vez la materia cancelada o perdida.', 'condicion', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 6', 'Comunicar tras la graduación la información del primer empleo para iniciar el cobro de las cuotas.', 'norma', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-CRE-ICE'), 'Art. 7', 'Para más información contactar directamente a ICETEX.', 'nota', 7);

-- REG-ACA
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 1',  'La universidad tiene programas y planes de estudio que los estudiantes aceptan al inscribirse.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 2',  'Los estudiantes deben cumplir con los créditos requeridos por su respectivo programa.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 3',  'Cada crédito equivale a 48 horas de trabajo: 16 horas de clase y 32 de trabajo autónomo. Cada materia se califica de 0.0 a 5.0.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 4',  'La nota mínima aprobatoria es 3.0.', 'norma', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 5',  'Los estudiantes son admitidos tras pagar los derechos de admisión, certificar el grado de educación media (o equivalente), haber presentado las Pruebas Saber 11, pasar la entrevista de admisión, y cumplir todas las fechas establecidas por cada programa.', 'proceso', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 6',  'Se puede solicitar un semestre de receso enviando carta al Consejo Académico con las causas y su respaldo. Solo es posible por 1 semestre, salvo fuerza mayor.', 'proceso', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 7',  'Un estudiante activo es aquel que matricula al menos 1 materia por semestre.', 'norma', 7),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 8',  'El programa profesional debe finalizarse dentro de los 10 años (20 semestres) tras la admisión al respectivo programa.', 'condicion', 8),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 9',  'La condición de graduación es mediante prácticas profesionales durante 1 semestre o mediante tesis. Las prácticas se coordinan con el Departamento de Talento.', 'condicion', 9),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 10', '6 créditos de los requeridos por cada programa deben ser de formación humanística y científica (materias disponibles para todos los programas, sobre temas diferentes a los del programa).', 'condicion', 10),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 11', 'Para obtener el título se deben cumplir todos los requisitos: aprobar todos los créditos del programa, completar la tesis o prácticas profesionales, y certificar el requisito de idioma del pregrado (B1 en inglés para todos los pregrados).', 'condicion', 11),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-ACA'), 'Art. 12', 'Algunas materias tienen prerrequisitos que deben cumplirse antes de inscribirse: materias previas aprobadas o requisitos de inglés.', 'norma', 12);

-- REG-DIS
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 1', 'Los estudiantes deben ser respetuosos y cumplir con el reglamento disciplinario dentro del plantel y en los espacios en los que representen a la universidad.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 2', 'Faltas leves: interrupción reiterada de una clase, comer en zonas no autorizadas, no devolver libros de la biblioteca, llegar más de 30 minutos tarde a una clase o evaluación, y otros actos de desorden.', 'norma', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 3', 'Faltas graves: plagio de un trabajo o evaluación, uso de elementos no permitidos en exámenes, suplantación de identidad, falsificación de notas o documentos oficiales, y daño material a bienes de la universidad. En faltas de examen o trabajo, además de la falta se anula la evaluación.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 4', 'Faltas gravísimas: violencia física o verbal (incluyendo bullying o amenazas), acoso o discriminación, robo dentro del plantel o en actos representativos, tráfico de drogas o posesión de armas, y cometer faltas leves o graves mientras se tiene un contrato de desempeño activo.', 'norma', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 5', 'Sanción por acumulación de 3 faltas leves: suspensión de 2 semanas sin derecho a presentar trabajos o evaluaciones de ese período, más contrato de desempeño.', 'sancion', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 6', 'Sanción por 1 falta grave: anotación en hoja de vida y contrato de desempeño para el semestre actual y el siguiente.', 'sancion', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 7', 'Sanción por 1 falta gravísima: anotación en hoja de vida y expulsión inmediata sin derecho a revincularse a la universidad.', 'sancion', 7),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 8', 'Solo docentes y administrativos tienen derecho a asignar faltas disciplinarias.', 'norma', 8),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 9', 'Antes de proceder con sanciones, se garantiza la presunción de inocencia del estudiante y el estudio del caso por el comité disciplinario.', 'proceso', 9),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DIS'), 'Art. 10', 'El contrato de desempeño exige: promedio semestral igual o superior a 3.5, no cometer faltas de ningún tipo durante su vigencia, reuniones semanales con un psicólogo de la universidad, y certificado de mejora emitido por el psicólogo.', 'condicion', 10);

-- REG-GRP-DEP
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-DEP'), 'Art. 1', 'Tener un grupo fijo para las competencias.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-DEP'), 'Art. 2', 'Participar en todas las competencias aceptadas por el profesor titular del equipo.', 'norma', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-DEP'), 'Art. 3', 'Representar adecuadamente a la universidad en todos los eventos.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-DEP'), 'Art. 4', 'Los estudiantes deben asistir al menos al 80% de las prácticas deportivas.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-DEP'), 'Art. 5', 'Las convocatorias se realizan mediante inscripción en la sala de deportes al inicio de cada semestre, con pruebas físicas para admitir a los estudiantes nuevos.', 'proceso', 5);

-- REG-GRP-EST
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-EST'), 'Art. 1', 'Cumplir con al menos el 80% de las actividades agendadas semestralmente y enviadas al comité estudiantil.', 'condicion', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-EST'), 'Art. 2', 'Representar adecuadamente a la universidad en todos los eventos a los que asistan.', 'norma', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-EST'), 'Art. 3', 'Hacer convocatorias al inicio de cada semestre en el evento "Vive tus grupos", con proceso de admisión definido por la junta directiva del grupo estudiantil.', 'proceso', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-EST'), 'Art. 4', 'El departamento de contabilidad realizará auditoría de los gastos.', 'norma', 4);

-- REG-GRP-ART
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-ART'), 'Art. 1', 'Deben ser grupos gestionados y dinamizados por el Departamento de Bienestar.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-ART'), 'Art. 2', 'Los cursos son gratuitos para estudiantes y con descuento para otras personas de la comunidad educativa. El descuento lo define semestralmente el Departamento de Bienestar.', 'norma', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-ART'), 'Art. 3', 'Los cursos, los cupos y sus temas son definidos semestralmente únicamente por el Departamento de Bienestar.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-ART'), 'Art. 4', 'Los cupos se asignan según orden de inscripción (para estudiantes) o según orden de pago (para no estudiantes).', 'proceso', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-ART'), 'Art. 5', 'Deben tener un acto de clausura al final de cada semestre.', 'condicion', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GRP-ART'), 'Art. 6', 'Para conocer precios de cursos y descuentos, debe contactarse al Departamento de Bienestar.', 'nota', 6);

-- REG-IDI
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-IDI'), 'Art. 1', 'Deben haber al menos 10 profesores en cada sede por cada idioma que se enseñe.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-IDI'), 'Art. 2', 'El Departamento de Idiomas certifica a estudiantes y docentes mediante la validación de un examen TOEFL, IELTS o British Council, o mediante la aprobación de un curso o examen de certificación en alguna de las sedes de idiomas de la universidad.', 'proceso', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-IDI'), 'Art. 3', 'Para conocer precios de cursos y descuentos, debe contactarse al Departamento de Idiomas.', 'nota', 3);

-- REG-MON
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-MON'), 'Art. 1', 'Los interesados deben postularse con el Departamento de Talento, que les suministrará toda la información.', 'proceso', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-MON'), 'Art. 2', 'Solo se puede ser monitor en 1 materia por semestre, la cual el estudiante ya debió haber cursado y aprobado.', 'condicion', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-MON'), 'Art. 3', 'Los monitores se seleccionan según sus calificaciones en la materia correspondiente.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-MON'), 'Art. 4', 'Deben cumplir con al menos 10 horas de monitoría señaladas y recibirán un pago mensual.', 'condicion', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-MON'), 'Art. 5', 'La renovación del puesto de monitor depende del promedio de calificación asignado por los estudiantes atendidos. Si el promedio es menor a 3.0, no se renueva.', 'condicion', 5);

-- REG-DOC
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DOC'), 'Art. 1', 'Los docentes de planta con más de 5 años en la universidad pueden postularse a decanatura de su facultad o a jefe de carrera. Son elegidos democráticamente por los docentes de la facultad. El período de cada puesto es de 4 años y deben seguir dictando al menos 12 horas de clase semanales.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DOC'), 'Art. 2', 'El comité académico, con asesoría del equipo de contabilidad, define el sueldo de los docentes de planta y de cátedra anualmente.', 'norma', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DOC'), 'Art. 3', 'Para la permanencia semestral, los docentes deben recibir en promedio más de 3.4 en la evaluación docente.', 'condicion', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-DOC'), 'Art. 4', 'Los docentes con faltas de respeto o acoso reportadas y comprobadas por el comité disciplinario serán inmediatamente despedidos.', 'sancion', 4);

-- REG-GEN
INSERT INTO reglamento_articulos (reglamento_id, numero_articulo, contenido, tipo, orden) VALUES
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 1',  'La universidad tendrá un rector o rectora elegido por un período de 4 años, democráticamente por los decanos, el psicólogo en jefe, el comité de planeación y el jefe de administración. Los candidatos deben ser docentes de planta con más de 6 años de antigüedad.', 'norma', 1),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 2',  'La universidad cuenta con: junta directiva, equipo de contabilidad, equipo administrativo, equipo de marketing, equipo de recursos humanos, equipo médico y equipo psicológico.', 'norma', 2),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 3',  'La junta directiva la componen: el rector(a), los decanos, el psicólogo en jefe, el comité de planeación, el jefe de contabilidad y su asistente, y el jefe de administración. Deben reunirse al menos 1 vez al mes.', 'norma', 3),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 4',  'El comité de planeación lo componen: el jefe de planeación, los directores de los equipos, un gerente de operaciones y su asistente, un representante de los docentes, el representante de los estudiantes a la junta directiva y un Project Manager. Deben reunirse al menos 2 veces al mes.', 'norma', 4),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 5',  'El comité estudiantil lo componen los representantes de cada carrera, elegidos semestralmente por votación, y el representante de los estudiantes a la junta directiva. Deben reunirse al menos 3 veces al mes.', 'norma', 5),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 6',  'El representante de los estudiantes a la junta directiva se elige democráticamente entre los estudiantes cada semestre.', 'norma', 6),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 7',  'El comité académico lo componen: los jefes de carrera, el representante de los estudiantes a la junta directiva, los decanos y el jefe de planeación. Deben reunirse al menos 2 veces al mes.', 'norma', 7),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 8',  'El comité disciplinario lo componen: psicólogos que no sean del departamento de psicología, un representante de los docentes y un representante del equipo administrativo.', 'norma', 8),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 9',  'Departamento de Talento: encargado del desarrollo profesional de los estudiantes, incluyendo asesoría profesional, monitorías y prácticas profesionales.', 'norma', 9),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 10', 'Departamento de Bienestar: encargado del desarrollo artístico y cultural de todos los integrantes de la comunidad educativa. Abarca los grupos artísticos y la planeación cultural.', 'norma', 10),
((SELECT reglamento_id FROM reglamentos WHERE codigo='REG-GEN'), 'Art. 11', 'Departamento de Idiomas: encargado de la oferta de idiomas de la universidad.', 'norma', 11);


-- -------------------------------------------------------
-- 4. VISTA ÚTIL PARA EL RAG
-- -------------------------------------------------------

CREATE OR REPLACE VIEW v_reglamentos_completos AS
SELECT
    r.codigo,
    r.titulo        AS reglamento,
    r.categoria,
    r.aplica_a,
    a.numero_articulo,
    a.contenido,
    a.tipo,
    a.orden
FROM reglamentos r
JOIN reglamento_articulos a ON r.reglamento_id = a.reglamento_id
WHERE r.vigente = TRUE AND a.activo = TRUE
ORDER BY r.categoria, r.codigo, a.orden;

-- Búsqueda full-text: ejemplo de uso
-- SELECT numero_articulo, contenido
-- FROM reglamento_articulos
-- WHERE to_tsvector('spanish', contenido) @@ plainto_tsquery('spanish', 'promedio beca cancelar');