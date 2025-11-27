--------------------------------------------------------
-- EXERCICI 3 - Creació de l’esquema complet de la BD UCI
-- Pràctica UCI – Grup 02
--------------------------------------------------------

-- Eliminació prèvia d’objectes si existeixen
BEGIN EXECUTE IMMEDIATE 'DROP TABLE REPETICIO CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EXPERIMENT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PARAMETERS CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CLASSIFICADOR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SAMPLES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DATASET CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

--------------------------------------------------------
-- TAULA DATASET
--------------------------------------------------------
CREATE TABLE DATASET (
    ID          NUMBER PRIMARY KEY,
    NAME        VARCHAR2(100) UNIQUE NOT NULL,
    FEAT_SIZE   NUMBER,
    NUMCLASSES  NUMBER,
    INFO        CLOB CHECK (INFO IS JSON)
);

--------------------------------------------------------
-- TAULA SAMPLES
--------------------------------------------------------
CREATE TABLE SAMPLES (
    ID_DATASET   NUMBER NOT NULL,
    ID           NUMBER NOT NULL,
    FEATURES     VECTOR,
    LABEL        VARCHAR2(16),
    CONSTRAINT SAMPLES_PK PRIMARY KEY (ID_DATASET, ID),
    CONSTRAINT SAMPLES_FK FOREIGN KEY (ID_DATASET)
        REFERENCES DATASET(ID) ON DELETE CASCADE
);

--------------------------------------------------------
-- TAULA CLASSIFICADOR
--------------------------------------------------------
CREATE TABLE CLASSIFICADOR (
    ID    NUMBER PRIMARY KEY,
    NOM   VARCHAR2(100) NOT NULL
);

--------------------------------------------------------
-- TAULA PARAMETERS
--------------------------------------------------------
CREATE TABLE PARAMETERS (
    PARAM_ID   VARCHAR2(64) PRIMARY KEY,
    VALORS     CLOB CHECK (VALORS IS JSON)
);

--------------------------------------------------------
-- TAULA EXPERIMENT
--------------------------------------------------------
CREATE TABLE EXPERIMENT (
    ID_EXPERIMENT   NUMBER PRIMARY KEY,
    DATA_EXPERIMENT DATE,
    ACCURACY        NUMBER(9,6),
    F_SCORE         NUMBER(9,6),
    DATASET_ID      NUMBER,
    CLASSIF_ID      NUMBER,
    PARAM_ID        VARCHAR2(64),
    CONSTRAINT EXP_DS_FK  FOREIGN KEY (DATASET_ID) REFERENCES DATASET(ID),
    CONSTRAINT EXP_CL_FK  FOREIGN KEY (CLASSIF_ID) REFERENCES CLASSIFICADOR(ID),
    CONSTRAINT EXP_PAR_FK FOREIGN KEY (PARAM_ID) REFERENCES PARAMETERS(PARAM_ID)
);

--------------------------------------------------------
-- TAULA REPETICIO
--------------------------------------------------------
CREATE TABLE REPETICIO (
    ID_REP   NUMBER PRIMARY KEY,
    NUM      NUMBER,
    EXPE_ID  NUMBER,
    CONSTRAINT REP_EXP_FK FOREIGN KEY (EXPE_ID)
        REFERENCES EXPERIMENT(ID_EXPERIMENT) ON DELETE CASCADE
);

--------------------------------------------------------
-- SEQÜÈNCIES
--------------------------------------------------------
CREATE SEQUENCE SEQ_DATASET START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_CLASSIFICADOR START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_EXPERIMENT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_REPETICIO START WITH 1 INCREMENT BY 1;

--------------------------------------------------------
PROMPT 'BDUCI creada correctament'
--------------------------------------------------------
