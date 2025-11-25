-- Asegurar salida de mensajes (para debugging)
SET SERVEROUTPUT ON;

--------------------------------------------------------
-- 1. LIMPIEZA SEGURA DE OBJETOS EXISTENTES
--------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables ORDER BY table_name DESC) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
  FOR v IN (SELECT view_name FROM user_views WHERE view_name LIKE 'MV_%' OR view_name LIKE 'BEST_%') LOOP
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ' || v.view_name;
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
      EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
END;
/

--------------------------------------------------------
-- 2. SEQUENCES
--------------------------------------------------------
CREATE SEQUENCE seq_dataset_id START WITH 1 NOCACHE;
CREATE SEQUENCE seq_classificador START WITH 1 NOCACHE;
CREATE SEQUENCE seq_experiment START WITH 1 NOCACHE;
CREATE SEQUENCE seq_repeticio START WITH 1 NOCACHE;

--------------------------------------------------------
-- 3. TAULES
--------------------------------------------------------
CREATE TABLE DATASET (
    ID          NUMBER PRIMARY KEY,
    NAME        VARCHAR2(100) UNIQUE NOT NULL,
    FEAT_SIZE   NUMBER,
    NUMCLASSES  NUMBER,
    INFO        CLOB CHECK (INFO IS JSON)
);

CREATE TABLE CLASSIFICADOR (
    ID    NUMBER PRIMARY KEY,
    NOM   VARCHAR2(100) NOT NULL
);

CREATE TABLE PARAMETERS (
    PARAM_ID    VARCHAR2(64) PRIMARY KEY,
    VALORS      CLOB CHECK (VALORS IS JSON)
);

CREATE TABLE EXPERIMENT (
    ID_EXPERIMENT   NUMBER PRIMARY KEY,
    DATA_EXPERIMENT DATE,
    ACCURACY        NUMBER(9,6),
    F_SCORE         NUMBER(9,6),
    DATASET_ID      NUMBER,
    CLASSIF_ID      NUMBER,
    PARAM_ID        VARCHAR2(64),
    CONSTRAINT fk_exp_dataset FOREIGN KEY (DATASET_ID) REFERENCES DATASET(ID),
    CONSTRAINT fk_exp_classif FOREIGN KEY (CLASSIF_ID) REFERENCES CLASSIFICADOR(ID),
    CONSTRAINT fk_exp_params  FOREIGN KEY (PARAM_ID) REFERENCES PARAMETERS(PARAM_ID)
);

CREATE TABLE REPETICIO (
    ID_REP    NUMBER PRIMARY KEY,
    NUM       NUMBER,
    EXPE_ID   NUMBER,
    CONSTRAINT fk_rep_exp FOREIGN KEY (EXPE_ID) REFERENCES EXPERIMENT(ID_EXPERIMENT) ON DELETE CASCADE
);

--------------------------------------------------------
-- 4. TRIGGERS (asignación automática de IDs)
--------------------------------------------------------
CREATE OR REPLACE TRIGGER tr_dataset_before_insert
BEFORE INSERT ON DATASET
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  :NEW.ID := seq_dataset_id.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER tr_classificador_before_insert
BEFORE INSERT ON CLASSIFICADOR
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  :NEW.ID := seq_classificador.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER tr_experiment_before_insert
BEFORE INSERT ON EXPERIMENT
FOR EACH ROW
WHEN (NEW.ID_EXPERIMENT IS NULL)
BEGIN
  :NEW.ID_EXPERIMENT := seq_experiment.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER tr_repeticio_before_insert
BEFORE INSERT ON REPETICIO
FOR EACH ROW
WHEN (NEW.ID_REP IS NULL)
BEGIN
  :NEW.ID_REP := seq_repeticio.NEXTVAL;
END;
/

--------------------------------------------------------
-- 5. FUNCIONS AUXILIARS
--------------------------------------------------------
CREATE OR REPLACE FUNCTION get_param_hash(p_valors CLOB)
RETURN VARCHAR2
AUTHID DEFINER
IS
    v_hash RAW(2000);
    v_sub  VARCHAR2(32767);
BEGIN
    v_sub := DBMS_LOB.SUBSTR(p_valors, 32767, 1);
    v_hash := DBMS_CRYPTO.HASH(
        src => UTL_I18N.STRING_TO_RAW(v_sub, 'AL32UTF8'),
        typ => DBMS_CRYPTO.HASH_SH256
    );
    RETURN RAWTOHEX(v_hash);
END;
/

CREATE OR REPLACE FUNCTION get_dataset_id(p_name VARCHAR2)
RETURN NUMBER
AUTHID DEFINER
IS
    v_id NUMBER;
BEGIN
    SELECT ID INTO v_id FROM DATASET WHERE NAME = p_name;
    RETURN v_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
/

CREATE OR REPLACE FUNCTION get_classificador_id(p_short VARCHAR2, p_long VARCHAR2)
RETURN NUMBER
AUTHID DEFINER
IS
    v_id NUMBER;
BEGIN
    SELECT ID INTO v_id FROM CLASSIFICADOR WHERE NOM = p_short;
    RETURN v_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        INSERT INTO CLASSIFICADOR(ID, NOM) VALUES (seq_classificador.NEXTVAL, p_short) RETURNING ID INTO v_id;
        RETURN v_id;
END;
/

CREATE OR REPLACE PROCEDURE ensure_parametres(p_hash VARCHAR2, p_valors CLOB)
AUTHID DEFINER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM PARAMETERS WHERE PARAM_ID = p_hash;
    IF v_count = 0 THEN
        INSERT INTO PARAMETERS(PARAM_ID, VALORS) VALUES (p_hash, p_valors);
    END IF;
END;
/

--------------------------------------------------------
-- 6. FUNCIÓN PRINCIPAL: insertExperiment
--------------------------------------------------------
CREATE OR REPLACE FUNCTION insertExperiment(
    p_dataset         IN VARCHAR2,
    p_classificador   IN VARCHAR2,
    p_nom_llarg_class IN VARCHAR2,
    p_iteracio        IN NUMBER,
    p_valors          IN CLOB,
    p_data_experiment IN DATE,
    p_fscore          IN NUMBER,
    p_accuracy        IN NUMBER
) RETURN BOOLEAN
AUTHID DEFINER
IS
    v_dataset_id   NUMBER;
    v_class_id     NUMBER;
    v_param_hash   VARCHAR2(64);
    v_exp_id       NUMBER;
BEGIN
    v_dataset_id := get_dataset_id(p_dataset);
    IF v_dataset_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'Dataset no existeix: ' || p_dataset);
    END IF;

    v_class_id := get_classificador_id(p_classificador, p_nom_llarg_class);
    v_param_hash := get_param_hash(p_valors);
    ensure_parametres(v_param_hash, p_valors);

    INSERT INTO EXPERIMENT(
        DATA_EXPERIMENT, ACCURACY, F_SCORE, DATASET_ID, CLASSIF_ID, PARAM_ID
    ) VALUES (
        p_data_experiment, p_accuracy, p_fscore, v_dataset_id, v_class_id, v_param_hash
    ) RETURNING ID_EXPERIMENT INTO v_exp_id;

    FOR i IN 1..LEAST(p_iteracio, 50) LOOP
        INSERT INTO REPETICIO(NUM, EXPE_ID) VALUES (i, v_exp_id);
    END LOOP;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/

--------------------------------------------------------
-- 7. PRIVILEGIS PER A testUCI
--------------------------------------------------------
GRANT EXECUTE ON insertExperiment TO testUCI;

--------------------------------------------------------
-- 8. VISTA MATERIALITZADA (Exercici 5)
--------------------------------------------------------
CREATE MATERIALIZED VIEW MV_EXP_RESULTS
BUILD IMMEDIATE
REFRESH COMPLETE
ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    d.NAME          AS DATASET_NAME,
    c.NOM           AS CLASSIFICADOR,
    p.PARAM_ID,                  -- ✅ clave de agrupación (VARCHAR2)
    p.VALORS        AS PARAMETRES, -- ✅ se muestra, pero no se agrupa
    TRUNC(e.DATA_EXPERIMENT) AS DATA_EXP,
    AVG(e.ACCURACY) AS AVG_ACCURACY,
    AVG(e.F_SCORE)  AS AVG_F_SCORE,
    COUNT(*)        AS NUM_EXPERIMENTS
FROM
    EXPERIMENT e
    JOIN DATASET d        ON e.DATASET_ID = d.ID
    JOIN CLASSIFICADOR c  ON e.CLASSIF_ID = c.ID
    JOIN PARAMETERS p     ON e.PARAM_ID = p.PARAM_ID
GROUP BY
    d.NAME,
    c.NOM,
    p.PARAM_ID,                  -- agrupar por clave, no por CLOB
    p.VALORS,                   
    TRUNC(e.DATA_EXPERIMENT);

--------------------------------------------------------
-- 9. ÍNDEXS EN LA VISTA MATERIALITZADA
--------------------------------------------------------
CREATE INDEX IDX_MV_DATASET ON MV_EXP_RESULTS (DATASET_NAME);
CREATE INDEX IDX_MV_CLASSIF ON MV_EXP_RESULTS (CLASSIFICADOR);
CREATE INDEX IDX_MV_DS_CL_ACC ON MV_EXP_RESULTS (DATASET_NAME, CLASSIFICADOR, AVG_ACCURACY DESC);

--------------------------------------------------------
-- 10. VISTA FINAL: millors paràmetres per dataset i classificador
--------------------------------------------------------
CREATE OR REPLACE VIEW BEST_PARAM_CONFIG AS
WITH stats AS (
    SELECT
        DATASET_NAME,
        CLASSIFICADOR,
        STDDEV(AVG_ACCURACY) AS STD_ACCURACY,
        STDDEV(AVG_F_SCORE)  AS STD_F_SCORE,
        MAX(AVG_ACCURACY)    AS BEST_ACC
    FROM MV_EXP_RESULTS
    GROUP BY DATASET_NAME, CLASSIFICADOR
)
SELECT
    m.DATASET_NAME,
    m.CLASSIFICADOR,
    m.PARAMETRES,
    m.AVG_ACCURACY,
    m.AVG_F_SCORE,
    s.STD_ACCURACY,
    s.STD_F_SCORE
FROM
    MV_EXP_RESULTS m
    JOIN stats s
        ON m.DATASET_NAME = s.DATASET_NAME
        AND m.CLASSIFICADOR = s.CLASSIFICADOR
        AND m.AVG_ACCURACY = s.BEST_ACC;
