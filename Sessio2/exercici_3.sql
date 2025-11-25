--------------------------------------------------------
-- BDUCI.sql - Base de dades completa UCI Experiments
--------------------------------------------------------

-- DROP TABLES (EN ORDRE DE DEPENDÈNCIES)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE REPETICIO CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EXPERIMENT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PARAMETRES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CLASSIFICADOR CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SAMPLES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DATASET CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

--------------------------------------------------------
-- DATASET
--------------------------------------------------------

CREATE TABLE DATASET (
    ID           NUMBER PRIMARY KEY,
    NOM         VARCHAR2(40),
    FEAT_SIZE    NUMBER,
    NUM_CLASSES  NUMBER,
    INFO         JSON
);

--------------------------------------------------------
-- SAMPLES
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
-- CLASSIFICADOR
--------------------------------------------------------

CREATE TABLE CLASSIFICADOR (
    ID    NUMBER PRIMARY KEY,
    NOMCURT VARCHAR2(50) NOT NULL,
    NOM VARCHAR2(50)
);

--------------------------------------------------------
-- PARAMETRES
--------------------------------------------------------

CREATE TABLE PARAMETRES (
    PARAM_ID    VARCHAR2(64) PRIMARY KEY,
    VALORS      JSON
);

--------------------------------------------------------
-- EXPERIMENT
--------------------------------------------------------

CREATE TABLE EXPERIMENT (
    ID_EXPERIMENT  NUMBER PRIMARY KEY,
    DATA           DATE,
    ACCURACY       NUMBER(6,4),
    F_SCORE        NUMBER(6,4),
    DATASET_ID     NUMBER,
    CLASSIF_ID     NUMBER,
    PARAM_ID       VARCHAR2(64),
    
    CONSTRAINT EXP_DS_FK FOREIGN KEY (DATASET_ID)
        REFERENCES DATASET(ID),

    CONSTRAINT EXP_CLAS_FK FOREIGN KEY (CLASSIF_ID)
        REFERENCES CLASSIFICADOR(ID),

    CONSTRAINT EXP_PAR_FK FOREIGN KEY (PARAM_ID)
        REFERENCES PARAMETRES(PARAM_ID)
);

--------------------------------------------------------
-- REPETICIO
--------------------------------------------------------

CREATE TABLE REPETICIO (
    ID_REP    NUMBER PRIMARY KEY,
    NUM       NUMBER,
    EXPE_ID   NUMBER,
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
-- FINAL
--------------------------------------------------------

PROMPT 'BDUCI creada correctament';
