-- BDUCI.sql
-- Base de dades completa per a UCI Experiments
-- Conté: perfils, rols, usuaris (basats en l'estructura existent), objectes (taules, seqüències, triggers),
-- funcions PL/SQL auxiliars, la funció insertExperiment, vistes materialitzades i vistes per anàlisi.
-- Executar com a usuari amb privilegis de creació d'objectes (GestorUCI segons l'enunciat).

SET SERVEROUTPUT ON;

--------------------------------------------------------
-- 0) (Opcional) PERFILS, ROLS i USUARIS ja existents
-- (Aquests blocs es podrien comentar si ja es van crear a l'exercici 1)
--------------------------------------------------------
-- Crear PROFILE si no existe
BEGIN
  EXECUTE IMMEDIATE '
    CREATE PROFILE perfil_test LIMIT
        FAILED_LOGIN_ATTEMPTS 3
        PASSWORD_LIFE_TIME UNLIMITED
        SESSIONS_PER_USER UNLIMITED
  ';
EXCEPTION
  WHEN OTHERS THEN 
    IF SQLCODE != -955 THEN  -- ORA-00955: name already used
      RAISE;
    END IF;
END;
/

BEGIN
  BEGIN
    EXECUTE IMMEDIATE q'[
      CREATE PROFILE perfil_dev LIMIT
        FAILED_LOGIN_ATTEMPTS 3
        PASSWORD_LIFE_TIME 270
        SESSIONS_PER_USER 4
    ]';
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
END;
/

BEGIN
  BEGIN
    EXECUTE IMMEDIATE q'[
      CREATE PROFILE perfil_gestor LIMIT
        FAILED_LOGIN_ATTEMPTS 3
        PASSWORD_LIFE_TIME 270
        SESSIONS_PER_USER 4
    ]';
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
END;
/

-- Rols
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE rol_test'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE rol_dev'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'CREATE ROLE rol_gestor'; EXCEPTION WHEN OTHERS THEN NULL; END; /

-- Grants generals a rols (exemples)
BEGIN
  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO rol_test';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO rol_dev';
  EXECUTE IMMEDIATE 'GRANT SELECT ANY TABLE TO rol_dev';
  EXECUTE IMMEDIATE 'GRANT INSERT ANY TABLE TO rol_dev';
  EXECUTE IMMEDIATE 'GRANT UPDATE ANY TABLE TO rol_dev';
  EXECUTE IMMEDIATE 'GRANT DELETE ANY TABLE TO rol_dev';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ANY PROCEDURE TO rol_dev';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO rol_gestor';
  EXECUTE IMMEDIATE 'GRANT SELECT ANY TABLE TO rol_gestor';
  EXECUTE IMMEDIATE 'GRANT INSERT ANY TABLE TO rol_gestor';
  EXECUTE IMMEDIATE 'GRANT UPDATE ANY TABLE TO rol_gestor';
  EXECUTE IMMEDIATE 'GRANT DELETE ANY TABLE TO rol_gestor';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ANY PROCEDURE TO rol_gestor';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Usuaris (nomes crear si no existeixen)
BEGIN
  EXECUTE IMMEDIATE 'CREATE USER testUCI IDENTIFIED BY grup02 PROFILE perfil_test';
  EXECUTE IMMEDIATE 'GRANT rol_test TO testUCI';
  EXECUTE IMMEDIATE 'ALTER USER testUCI DEFAULT ROLE rol_test';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'CREATE USER GestorUCI IDENTIFIED BY grup02 PROFILE perfil_gestor';
  EXECUTE IMMEDIATE 'GRANT rol_gestor TO GestorUCI';
  EXECUTE IMMEDIATE 'ALTER USER GestorUCI DEFAULT ROLE rol_gestor';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Quota per tablespace users (pot fallar si ja es va fer)
BEGIN
  EXECUTE IMMEDIATE 'ALTER USER testUCI DEFAULT TABLESPACE users QUOTA UNLIMITED ON users';
  EXECUTE IMMEDIATE 'ALTER USER GestorUCI DEFAULT TABLESPACE users QUOTA UNLIMITED ON users';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
--------------------------------------------------------
-- 1) DROP OBJECTS PREVIS (en ordre per dependències)
--    (Només per desenvolupament: en producció valorar comentar)
--------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW MV_EXP_RESULTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP VIEW BEST_PARAM_CONFIG'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP VIEW BEST_ACCURACY'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE RESULT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE METRIC CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE RUN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EXPERIMENT_PARAMETERS CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PARAMETERS CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EXPERIMENT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CLASSIFICADOR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SAMPLES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DATASET CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /

--------------------------------------------------------
-- 2) SEQUENCES
--------------------------------------------------------
CREATE SEQUENCE seq_dataset_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_samples_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_classificador START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_experiment START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_repeticio START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_run_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_result_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_metric_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

--------------------------------------------------------
-- 3) TAULES PRINCIPALS
--------------------------------------------------------
-- DATASET
CREATE TABLE DATASET (
    ID          NUMBER PRIMARY KEY,
    NAME        VARCHAR2(100) UNIQUE NOT NULL,
    FEAT_SIZE   NUMBER,
    NUMCLASSES  NUMBER,
    INFO        CLOB CHECK ( INFO IS JSON )
);

-- SAMPLES
CREATE TABLE SAMPLES (
    ID_DATASET  NUMBER NOT NULL,
    ID          NUMBER       NOT NULL,
    FEATURES    VECTOR,
    LABEL       VARCHAR2(200),
    CONSTRAINT SAMPLES_PK PRIMARY KEY (ID_DATASET, ID),
    CONSTRAINT SAMPLES_FK FOREIGN KEY (ID_DATASET)
       REFERENCES DATASET(ID) ON DELETE CASCADE
);

-- CLASSIFICADOR
CREATE TABLE CLASSIFICADOR (
    ID    NUMBER PRIMARY KEY,
    NOM   VARCHAR2(100) NOT NULL
);

-- PARAMETERS (valors JSON amb PK hash)
CREATE TABLE PARAMETERS (
    PARAM_ID    VARCHAR2(64) PRIMARY KEY,
    VALORS      CLOB CHECK ( VALORS IS JSON ),
    CREATED_AT  TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- EXPERIMENT
CREATE TABLE EXPERIMENT (
    ID_EXPERIMENT  NUMBER PRIMARY KEY,
    DATA_EXPERIMENT DATE,
    ACCURACY       NUMBER(9,6),
    F_SCORE        NUMBER(9,6),
    DATASET_ID     NUMBER,
    CLASSIF_ID     NUMBER,
    PARAM_ID       VARCHAR2(64),
    CONSTRAINT EXP_DS_FK FOREIGN KEY (DATASET_ID)
        REFERENCES DATASET(ID),
    CONSTRAINT EXP_CLAS_FK FOREIGN KEY (CLASSIF_ID)
        REFERENCES CLASSIFICADOR(ID),
    CONSTRAINT EXP_PAR_FK FOREIGN KEY (PARAM_ID)
        REFERENCES PARAMETERS(PARAM_ID)
);

-- REPETICIO
CREATE TABLE REPETICIO (
    ID_REP    NUMBER PRIMARY KEY,
    NUM       NUMBER,
    EXPE_ID   NUMBER,
    CONSTRAINT REP_EXP_FK FOREIGN KEY (EXPE_ID)
        REFERENCES EXPERIMENT(ID_EXPERIMENT) ON DELETE CASCADE
);

-- RUN i RESULT (opcinals per a experiments mes detallats)
CREATE TABLE RUN (
    ID      NUMBER PRIMARY KEY,
    EXPERIMENT_ID NUMBER,
    RUN_INDEX NUMBER,
    FOLD NUMBER,
    SEED NUMBER,
    STARTED_AT TIMESTAMP,
    FINISHED_AT TIMESTAMP,
    SUCCESS VARCHAR2(1),
    CONSTRAINT RUN_EXP_FK FOREIGN KEY (EXPERIMENT_ID) REFERENCES EXPERIMENT(ID_EXPERIMENT) ON DELETE CASCADE
);

CREATE TABLE METRIC (
    ID NUMBER PRIMARY KEY,
    NAME VARCHAR2(100) UNIQUE,
    DESC VARCHAR2(1000)
);

CREATE TABLE RESULT (
    ID NUMBER PRIMARY KEY,
    RUN_ID NUMBER,
    METRIC_ID NUMBER,
    METRIC_VAL NUMBER,
    EXTRA_INFO CLOB,
    CONSTRAINT RESULT_RUN_FK FOREIGN KEY (RUN_ID) REFERENCES RUN(ID) ON DELETE CASCADE,
    CONSTRAINT RESULT_METRIC_FK FOREIGN KEY (METRIC_ID) REFERENCES METRIC(ID)
);

--------------------------------------------------------
-- 4) TRIGGERS PER A ASSIGNAR IDS AMB SEQÜENCIES
--------------------------------------------------------
CREATE OR REPLACE TRIGGER tr_dataset_before_insert
BEFORE INSERT ON DATASET
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  SELECT seq_dataset_id.NEXTVAL INTO :NEW.ID FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_samples_before_insert
BEFORE INSERT ON SAMPLES
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  SELECT seq_samples_id.NEXTVAL INTO :NEW.ID FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_classificador_before_insert
BEFORE INSERT ON CLASSIFICADOR
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  SELECT seq_classificador.NEXTVAL INTO :NEW.ID FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_experiment_before_insert
BEFORE INSERT ON EXPERIMENT
FOR EACH ROW
WHEN (NEW.ID_EXPERIMENT IS NULL)
BEGIN
  SELECT seq_experiment.NEXTVAL INTO :NEW.ID_EXPERIMENT FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_repeticio_before_insert
BEFORE INSERT ON REPETICIO
FOR EACH ROW
WHEN (NEW.ID_REP IS NULL)
BEGIN
  SELECT seq_repeticio.NEXTVAL INTO :NEW.ID_REP FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_run_before_insert
BEFORE INSERT ON RUN
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  SELECT seq_run_id.NEXTVAL INTO :NEW.ID FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_metric_before_insert
BEFORE INSERT ON METRIC
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  SELECT seq_metric_id.NEXTVAL INTO :NEW.ID FROM dual;
END;
/
CREATE OR REPLACE TRIGGER tr_result_before_insert
BEFORE INSERT ON RESULT
FOR EACH ROW
WHEN (NEW.ID IS NULL)
BEGIN
  SELECT seq_result_id.NEXTVAL INTO :NEW.ID FROM dual;
END;
/
--------------------------------------------------------
-- 5) FUNCIONS I PROCEDURES AUXILIARS PL/SQL
--------------------------------------------------------
-- (A) Funcio per calcular hash SHA256 d'un CLOB JSON
CREATE OR REPLACE FUNCTION get_param_hash(p_valors CLOB)
RETURN VARCHAR2 IS
    v_hash VARCHAR2(64);
    v_sub  VARCHAR2(32767);
    v_len  INTEGER;
BEGIN
    -- Per a consistencia en l'hash, normalitzar l'entrada pot ser necessari (ordenar claus)
    -- Aquí fem una solucio simple: agafem el substr de tot el CLOB (fins 32767 chars)
    v_len := DBMS_LOB.GETLENGTH(p_valors);
    IF v_len > 32767 THEN
        v_sub := DBMS_LOB.SUBSTR(p_valors, 32767, 1);
    ELSE
        v_sub := DBMS_LOB.SUBSTR(p_valors, v_len, 1);
    END IF;

    v_hash := STANDARD_HASH(v_sub, 'SHA256');
    RETURN v_hash;
END;
/
-- (B) get_dataset_id
CREATE OR REPLACE FUNCTION get_dataset_id(p_name VARCHAR2)
RETURN NUMBER IS
    v_id NUMBER;
BEGIN
    SELECT id INTO v_id FROM dataset WHERE name = p_name;
    RETURN v_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
-- (C) get_classificador_id (retorna id; crea si no existeix)
CREATE OR REPLACE FUNCTION get_classificador_id(p_short VARCHAR2, p_long VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
BEGIN
    SELECT id INTO v_id FROM classificador WHERE nom = p_short;
    RETURN v_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        INSERT INTO classificador(id, nom) VALUES (seq_classificador.NEXTVAL, p_short) RETURNING id INTO v_id;
        RETURN v_id;
END;
/
-- (D) ensure_parametres: inserta si no existeixen
CREATE OR REPLACE PROCEDURE ensure_parametres(p_hash VARCHAR2, p_valors CLOB) IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM parameters WHERE param_id = p_hash;
    IF v_count = 0 THEN
        INSERT INTO parameters(param_id, valors) VALUES (p_hash, p_valors);
    END IF;
END;
/
--------------------------------------------------------
-- 6) FUNCIO PRINCIPAL insertExperiment (signatura demanada)
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
) RETURN BOOLEAN IS

    v_dataset_id   NUMBER;
    v_class_id     NUMBER;
    v_param_hash   VARCHAR2(64);
    v_exp_id       NUMBER;

BEGIN
    -- Validar dataset
    v_dataset_id := get_dataset_id(p_dataset);
    IF v_dataset_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'Dataset no existeix: ' || p_dataset);
    END IF;

    -- Classificador (crear si cal)
    v_class_id := get_classificador_id(p_classificador, p_nom_llarg_class);

    -- Hash dels paràmetres i assegurar insercio
    v_param_hash := get_param_hash(p_valors);
    ensure_parametres(v_param_hash, p_valors);

    -- Inserir experiment
    INSERT INTO experiment(
        id_experiment, data_experiment, accuracy, f_score, dataset_id, classif_id, param_id
    ) VALUES (
        seq_experiment.NEXTVAL, p_data_experiment, p_accuracy, p_fscore, v_dataset_id, v_class_id, v_param_hash
    ) RETURNING id_experiment INTO v_exp_id;

    -- Inserir repeticions (fins a 50 en l'enunciat; si p_iteracio>50 fem només 50)
    FOR i IN 1..LEAST(p_iteracio,50) LOOP
        INSERT INTO repeticio(id_rep, num, expe_id) VALUES (seq_repeticio.NEXTVAL, i, v_exp_id);
    END LOOP;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR insertExperiment: ' || SQLERRM);
        RETURN FALSE;
END;
/
--------------------------------------------------------
-- 7) PRIVILEGIS ADICIONALS: EXECUTAR COM A GESTORUCI
--    Concedir a testUCI els permisos necessaris per a cridar la funcio
--------------------------------------------------------
-- Atenció: executar aquestes instruccions com a GestorUCI
GRANT EXECUTE ON insertExperiment TO testUCI;
GRANT INSERT, UPDATE ON experiment TO testUCI;
GRANT INSERT, UPDATE ON repeticio TO testUCI;
-- No permetre que testUCI modifiqui DATASET i SAMPLES
REVOKE INSERT, UPDATE, DELETE ON dataset FROM testUCI;
REVOKE INSERT, UPDATE, DELETE ON samples FROM testUCI;

--------------------------------------------------------
-- 8) VISTES MATERIALITZADES I VISTES PER A L'ANALISI (EXERCICI 5)
--------------------------------------------------------
-- 8.1 Vista materialitzada: mitjana d'accuracy i f-score per dataset, classificador i paràmetres
-- Cal que la vista utilitzi dades agregades de la taula EXPERIMENT i els valors de PARAMETERS i CLASSIFICADOR
CREATE MATERIALIZED VIEW MV_EXP_RESULTS
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
AS
SELECT 
    d.name AS dataset_name,
    c.nom  AS classificador,
    p.valors AS parametres,
    TRUNC(e.data_experiment) AS data_exp_trunc,
    AVG(e.accuracy) AS avg_accuracy,
    AVG(e.f_score) AS avg_fscore
FROM experiment e
JOIN dataset d ON e.dataset_id = d.id
JOIN classificador c ON e.classif_id = c.id
JOIN parameters p ON e.param_id = p.param_id
GROUP BY 
    d.name, 
    c.nom, 
    p.valors, 
    TRUNC(e.data_experiment);

-- 8.2 Indexs sobre la vista materialitzada (millora consultes)
CREATE INDEX IDX_MV_DATASET ON MV_EXP_RESULTS(dataset_name);
CREATE INDEX IDX_MV_CLASSIF ON MV_EXP_RESULTS(classificador);
CREATE INDEX IDX_MV_PARAMS ON MV_EXP_RESULTS(parametres);
/
-- 8.3 Vista intermitja: obtenir la millor accuracy per (dataset, classificador)
CREATE OR REPLACE VIEW BEST_ACCURACY AS
SELECT dataset_name, classificador, MAX(avg_accuracy) AS best_acc
FROM MV_EXP_RESULTS
GROUP BY dataset_name, classificador;
/
-- 8.4 Vista final: per cada dataset i classificador, els paràmetres amb millor accuracy i desviacions tipus
CREATE OR REPLACE VIEW BEST_PARAM_CONFIG AS
SELECT
    mv.dataset_name,
    mv.classificador,
    mv.parametres,
    mv.avg_accuracy,
    STDDEV(mv.avg_accuracy) OVER (PARTITION BY mv.dataset_name, mv.classificador) AS std_accuracy,
    mv.avg_fscore,
    STDDEV(mv.avg_fscore) OVER (PARTITION BY mv.dataset_name, mv.classificador) AS std_fscore
FROM MV_EXP_RESULTS mv
JOIN BEST_ACCURACY b
  ON mv.dataset_name = b.dataset_name
 AND mv.classificador = b.classificador
 AND mv.avg_accuracy = b.best_acc;
/
--------------------------------------------------------
-- 9) EXEMPLES D'UTILITZACIÓ I EXPLAIN PLAN (comentaris)
-- 9.1 Exemple de consultes a la vista materialitzada
-- SELECT * FROM MV_EXP_RESULTS WHERE dataset_name = 'Iris' AND classificador = 'SVM';
-- 9.2 Consultes a la vista final
-- SELECT * FROM BEST_PARAM_CONFIG WHERE dataset_name = 'Iris';
-- 9.3 Per comparar plans d'execució, utilitzeu:
-- EXPLAIN PLAN FOR SELECT * FROM BEST_PARAM_CONFIG WHERE dataset_name = 'Iris';
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT 'BDUCI.sql: script complet creat';
