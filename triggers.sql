-- ============================================================================
-- TRIGGER 1: LIMITAR LA INSCRIPCIÓN DE MATERIAS (MÁXIMO 6 POR SEMESTRE)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_validar_limite_materias()
RETURNS TRIGGER AS $$
DECLARE
    v_total_inscritas INT;
    v_periodo_actual_id INT;
BEGIN
    SELECT periodo_id INTO v_periodo_actual_id 
    FROM cursos 
    WHERE curso_id = NEW.curso_id;

    SELECT COUNT(*) INTO v_total_inscritas
    FROM inscripciones i
    JOIN cursos c ON i.curso_id = c.curso_id
    WHERE i.estudiante_id = NEW.estudiante_id
      AND c.periodo_id = v_periodo_actual_id;

    IF v_total_inscritas >= 6 THEN
        RAISE EXCEPTION 'Operación denegada. El estudiante ya cuenta con el máximo de 6 materias inscritas en este periodo académico.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_limite_materias ON inscripciones;
CREATE TRIGGER trg_limite_materias
BEFORE INSERT ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION fn_validar_limite_materias();


-- ============================================================================
-- TRIGGER 2: CONTROL RESTRICTIVO DE PRERREQUISITOS ACADÉMICOS
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_validar_prerrequisitos()
RETURNS TRIGGER AS $$
DECLARE
    v_materia_actual_id INT;
    v_prerrequisito_faltante VARCHAR(150);
BEGIN
    SELECT materia_id INTO v_materia_actual_id FROM cursos WHERE curso_id = NEW.curso_id;

    SELECT m.nombre INTO v_prerrequisito_faltante
    FROM prerrequisitos p
    JOIN materias m ON p.materia_prerrequisito_id = m.materia_id
    WHERE p.materia_id = v_materia_actual_id
      AND p.materia_prerrequisito_id NOT IN (
          SELECT h.materia_id 
          FROM historial_academico h 
          WHERE h.estudiante_id = NEW.estudiante_id 
            AND h.nota_final >= 3.0
      )
    LIMIT 1;

    IF v_prerrequisito_faltante IS NOT NULL THEN
        RAISE EXCEPTION 'Inscripción rechazada. El estudiante no cumple con los prerrequisitos obligatorios. Falta aprobar: %.', v_prerrequisito_faltante;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_prerrequisitos ON inscripciones;
CREATE TRIGGER trg_validar_prerrequisitos
BEFORE INSERT ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION fn_validar_prerrequisitos();


-- ============================================================================
-- TRIGGER 3: ASEGURAR QUE LAS EVALUACIONES NO SUPEREN EL 100%
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_validar_porcentaje_evaluaciones()
RETURNS TRIGGER AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COALESCE(SUM(porcentaje), 0)
    INTO v_total
    FROM evaluaciones_curso
    WHERE curso_id = NEW.curso_id;

    IF TG_OP = 'UPDATE' THEN
        v_total := v_total - OLD.porcentaje;
    END IF;

    v_total := v_total + NEW.porcentaje;

    IF v_total > 100 THEN
        RAISE EXCEPTION 'La suma de evaluaciones excede el 100%%. Total actual: %', v_total;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_porcentaje_evaluaciones ON evaluaciones_curso;
CREATE TRIGGER trg_porcentaje_evaluaciones
BEFORE INSERT OR UPDATE ON evaluaciones_curso
FOR EACH ROW
EXECUTE FUNCTION fn_validar_porcentaje_evaluaciones();


-- ============================================================================
-- TRIGGER 4: BLOQUEO TRANSACCIONAL POR SANCIONES DISCIPLINARIAS ACTIVAS
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_verificar_sancion_activa()
RETURNS TRIGGER AS $$
DECLARE
    v_usuario_sancionado_id INT;
    v_tiene_sancion_vigente BOOLEAN;
BEGIN
    IF TG_TABLE_NAME = 'inscripciones' THEN
        v_usuario_sancionado_id := NEW.estudiante_id;
    ELSIF TG_TABLE_NAME = 'reservas_aulas' THEN
        v_usuario_sancionado_id := NEW.usuario_id;
    END IF;

    SELECT EXISTS (
        SELECT 1 
        FROM registro_disciplinario 
        WHERE usuario_id = v_usuario_sancionado_id 
          AND estado = 'activa'
          AND CURRENT_DATE BETWEEN fecha_inicio_sancion AND fecha_fin_sancion
    ) INTO v_tiene_sancion_vigente;

    IF v_tiene_sancion_vigente THEN
        RAISE EXCEPTION 'Acceso denegado a la plataforma. El usuario se encuentra suspendido del sistema debido a una sanción disciplinaria vigente.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verificar_sancion_inscripcion ON inscripciones;
CREATE TRIGGER trg_verificar_sancion_inscripcion
BEFORE INSERT ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_sancion_activa();

DROP TRIGGER IF EXISTS trg_verificar_sancion_reserva ON reservas_aulas;
CREATE TRIGGER trg_verificar_sancion_reserva
BEFORE INSERT ON reservas_aulas
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_sancion_activa();


-- ============================================================================
-- TRIGGER 5: VALIDAR CUPOS MÁXIMOS (CONCURRENCIA CONTROLADA)
-- ============================================================================
-- CORRECCIÓN: Cascarón vacío eliminado por completo. Solo queda la definición válida.
CREATE OR REPLACE FUNCTION fn_validar_cupos()
RETURNS TRIGGER AS $$
DECLARE
    v_cupo_maximo INT;
    v_total_inscritos INT;
BEGIN
    -- Bloquear fila del curso para evitar condiciones de carrera (race conditions)
    SELECT cupo_maximo
    INTO v_cupo_maximo
    FROM cursos
    WHERE curso_id = NEW.curso_id
    FOR UPDATE;

    -- Contar inscritos actuales
    SELECT COUNT(*)
    INTO v_total_inscritos
    FROM inscripciones
    WHERE curso_id = NEW.curso_id;

    -- Validar disponibilidad
    IF v_total_inscritos >= v_cupo_maximo THEN
        RAISE EXCEPTION 'No hay cupos disponibles para este curso.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_cupos ON inscripciones;
CREATE TRIGGER trg_validar_cupos
BEFORE INSERT ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION fn_validar_cupos();


-- ============================================================================
-- TRIGGER 6: VALIDAR CHOQUE DE AULAS
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_validar_choque_aulas()
RETURNS TRIGGER AS $$
DECLARE
    v_conflicto INT;
BEGIN
    SELECT COUNT(*)
    INTO v_conflicto
    FROM horarios_clases hc
    WHERE hc.aula_id = NEW.aula_id
      AND hc.dia_semana = NEW.dia_semana
      AND (
            NEW.hora_inicio < hc.hora_fin
        AND NEW.hora_fin > hc.hora_inicio
      );

    IF v_conflicto > 0 THEN
        RAISE EXCEPTION 'El aula ya está ocupada en ese horario.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_choque_aulas ON horarios_clases;
CREATE TRIGGER trg_choque_aulas
BEFORE INSERT OR UPDATE ON horarios_clases
FOR EACH ROW
EXECUTE FUNCTION fn_validar_choque_aulas();


-- ============================================================================
-- TRIGGER 7: VALIDAR CHOQUE DE DOCENTES
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_validar_choque_docente()
RETURNS TRIGGER AS $$
DECLARE
    v_docente_id INT;
    v_conflicto INT;
BEGIN
    SELECT docente_id
    INTO v_docente_id
    FROM cursos
    WHERE curso_id = NEW.curso_id;

    SELECT COUNT(*)
    INTO v_conflicto
    FROM horarios_clases hc
    JOIN cursos c ON hc.curso_id = c.curso_id
    WHERE c.docente_id = v_docente_id
      AND hc.dia_semana = NEW.dia_semana
      AND (
            NEW.hora_inicio < hc.hora_fin
        AND NEW.hora_fin > hc.hora_inicio
      );

    IF v_conflicto > 0 THEN
        RAISE EXCEPTION 'El docente ya tiene una clase en ese horario.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_choque_docente ON horarios_clases;
CREATE TRIGGER trg_choque_docente
BEFORE INSERT OR UPDATE ON horarios_clases
FOR EACH ROW
EXECUTE FUNCTION fn_validar_choque_docente();