-- 1. Crear usuaris
-- 2. Donar quota i CREATE SESSION
-- 3. Donar privilegis mínims a GestorUCI (directes, no per rol)
GRANT CREATE SESSION TO GestorUCI;
GRANT CREATE TABLE TO GestorUCI;
GRANT CREATE SEQUENCE TO GestorUCI;
GRANT CREATE PROCEDURE TO GestorUCI;
GRANT CREATE TRIGGER TO GestorUCI;

-- Privilegio CLAVE para STANDARD_HASH
GRANT EXECUTE ON DBMS_CRYPTO TO GestorUCI;

-- Rol mínimo para testUCI
GRANT CREATE SESSION TO testUCI;

-- Activar salida (opcional, para debugging)
SET SERVEROUTPUT ON;

-- 1. Limpieza SEGURA
BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

-- 2. Secuencias
CREATE SEQUENCE seq_dataset_id;
CREATE SEQUENCE seq_classificador;
CREATE SEQUENCE seq_experiment;
CREATE SEQUENCE seq_repeticio;

-- 3. Tablas
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
    FOREIGN KEY (DATASET_ID) REFERENCES DATASET(ID),
    FOREIGN KEY (CLASSIF_ID) REFERENCES CLASSIFICADOR(ID),
    FOREIGN KEY (PARAM_ID) REFERENCES PARAMETERS(PARAM_ID)
);

CREATE TABLE REPETICIO (
    ID_REP    NUMBER PRIMARY KEY,
    NUM       NUMBER,
    EXPE_ID   NUMBER,
    FOREIGN KEY (EXPE_ID) REFERENCES EXPERIMENT(ID_EXPERIMENT) ON DELETE CASCADE
);

-- 4. Triggers (ahora sí, porque las tablas son del usuario actual)
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

-- 5. Función de hash (usando DBMS_CRYPTO)
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

-- 6. Otras funciones
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
RETURN NUMBER AUTHID DEFINER IS
    v_id NUMBER;
BEGIN
    SELECT ID INTO v_id FROM CLASSIFICADOR WHERE NOM = p_short;
    RETURN v_id;
EXCEPTION WHEN NO_DATA_FOUND THEN
    INSERT INTO CLASSIFICADOR(ID, NOM) VALUES (seq_classificador.NEXTVAL, p_short) RETURNING ID INTO v_id;
    RETURN v_id;
END;
/

CREATE OR REPLACE PROCEDURE ensure_parametres(p_hash VARCHAR2, p_valors CLOB)
AUTHID DEFINER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM PARAMETERS WHERE PARAM_ID = p_hash;
    IF v_count = 0 THEN
        INSERT INTO PARAMETERS(PARAM_ID, VALORS) VALUES (p_hash, p_valors);
    END IF;
END;
/

-- 7. Función principal
CREATE OR REPLACE FUNCTION insertExperiment(
    p_dataset         IN VARCHAR2,
    p_classificador   IN VARCHAR2,
    p_nom_llarg_class IN VARCHAR2,
    p_iteracio        IN NUMBER,
    p_valors          IN CLOB,
    p_data_experiment IN DATE,
    p_fscore          IN NUMBER,
    p_accuracy        IN NUMBER
) RETURN BOOLEAN AUTHID DEFINER IS
    v_dataset_id NUMBER;
    v_class_id   NUMBER;
    v_param_hash VARCHAR2(64);
    v_exp_id     NUMBER;
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

    FOR i IN 1..LEAST(p_iteracio, 50) LOOP
        INSERT INTO REPETICIO(NUM, EXPE_ID) VALUES (i, v_exp_id);
    END LOOP;

    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN RETURN FALSE;
END;
/

-- 8. Único GRANT necesario
GRANT EXECUTE ON insertExperiment TO testUCI;

-- Comprovació que funciona
SET SERVEROUTPUT ON;  -- Asegura que los mensajes se muestren

DECLARE
    ok BOOLEAN;
BEGIN
    ok := GestorUCI.insertExperiment(
        p_dataset         => 'Iris',
        p_classificador   => 'SVM',
        p_nom_llarg_class => 'Support Vector Machine',
        p_iteracio        => 5,
        p_valors          => '{"C": 1.0, "kernel": "rbf"}',
        p_data_experiment => SYSDATE,
        p_fscore          => 0.95,
        p_accuracy        => 0.96
    );

    IF ok THEN
        DBMS_OUTPUT.PUT_LINE('Éxito: experimento insertado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Fracaso: no se insertó el experimento.');
    END IF;
END;
/


-- Ver el experimento insertado
SELECT * FROM GestorUCI.EXPERIMENT 
WHERE DATASET_ID = (SELECT ID FROM GestorUCI.DATASET WHERE NAME = 'Iris');

-- Ver las repeticiones de TODOS los experimentos del dataset 'Iris'
SELECT * FROM GestorUCI.REPETICIO 
WHERE EXPE_ID IN (
    SELECT ID_EXPERIMENT 
    FROM GestorUCI.EXPERIMENT 
    WHERE DATASET_ID = (SELECT ID FROM GestorUCI.DATASET WHERE NAME = 'Iris')
);
