--------------------------------------------------------
-- EXERCICI 4 - Inserció d'experiments amb PL/SQL
-- Pràctica UCI – Grup 02
--------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------
-- 1. PRIVILEGIS NECESSARIS
--------------------------------------------------------
GRANT CREATE PROCEDURE TO GestorUCI;
GRANT CREATE TRIGGER TO GestorUCI;
GRANT EXECUTE ON DBMS_CRYPTO TO GestorUCI;

--------------------------------------------------------
-- 2. TRIGGERS PER ASSIGNACIÓ AUTOMÀTICA D'IDs
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
-- 3. FUNCIONS AUXILIARS
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
RETURN NUMBER AUTHID DEFINER IS
    v_id NUMBER;
BEGIN
    SELECT ID INTO v_id FROM DATASET WHERE NAME = p_name;
    RETURN v_id;
EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
/

CREATE OR REPLACE FUNCTION get_classificador_id(p_short VARCHAR2, p_long VARCHAR2)
RETURN NUMBER AUTHID DEFINER
IS
    v_id NUMBER;
BEGIN
    SELECT ID INTO v_id FROM CLASSIFICADOR WHERE NOM = p_short;
    RETURN v_id;
EXCEPTION WHEN NO_DATA_FOUND THEN
    INSERT INTO CLASSIFICADOR(ID, NOM)
    VALUES (seq_classificador.NEXTVAL, p_short)
    RETURNING ID INTO v_id;
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
-- 4. FUNCIÓ PRINCIPAL: insertExperiment
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
) RETURN BOOLEAN AUTHID DEFINER
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

    INSERT INTO EXPERIMENT(DATA_EXPERIMENT, ACCURACY, F_SCORE, DATASET_ID, CLASSIF_ID, PARAM_ID)
    VALUES (p_data_experiment, p_accuracy, p_fscore, v_dataset_id, v_class_id, v_param_hash)
    RETURNING ID_EXPERIMENT INTO v_exp_id;

    FOR i IN 1..LEAST(p_iteracio,50) LOOP
        INSERT INTO REPETICIO(NUM, EXPE_ID) VALUES (i, v_exp_id);
    END LOOP;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR insertExperiment: ' || SQLERRM);
        RETURN FALSE;
END;
/

--------------------------------------------------------
-- 5. GRANT PER A testUCI
--------------------------------------------------------
GRANT EXECUTE ON insertExperiment TO testUCI;

DECLARE
    ok BOOLEAN;
BEGIN
    ok := insertExperiment(
        'Iris', 'SVM', 'Support Vector Machine',
        10, '{"C":1.0,"kernel":"rbf"}',
        SYSDATE, 0.96, 0.95
    );

    IF ok THEN DBMS_OUTPUT.PUT_LINE('OK: experiment inserit.');
    ELSE DBMS_OUTPUT.PUT_LINE('ERROR: no inserit.');
    END IF;
END;
/

