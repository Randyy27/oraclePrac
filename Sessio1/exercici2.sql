-- ============================================================
-- EXERCICI 2 - GRUP 02
-- Creació d'usuari gestorUsuaris, taula A, seqüència i trigger
-- ============================================================
-- DROP USER gestorUsuaris_g2 CASCADE; -- en cas que ho necesitem

-- Crear usuari amb perfil existent
CREATE USER gestorUsuaris_g2
IDENTIFIED BY grup02
PROFILE perfil_gestor
DEFAULT TABLESPACE users
QUOTA UNLIMITED ON users;

-- Assignar el rol de gestor ja creat
GRANT rol_gestor TO gestorUsuaris_g2;

-- Establir rol per defecte
ALTER USER gestorUsuaris_g2 DEFAULT ROLE rol_gestor;

-- Concedir privilegis directes per treballar amb PL/SQL i objectes propis
GRANT CREATE SESSION TO gestorUsuaris_g2;
GRANT CREATE TABLE TO gestorUsuaris_g2;
GRANT CREATE SEQUENCE TO gestorUsuaris_g2;
GRANT CREATE TRIGGER TO gestorUsuaris_g2;
GRANT CREATE PROCEDURE TO gestorUsuaris_g2;

-- Confirmar canvis
SELECT username, profile, default_tablespace, account_status
FROM dba_users
WHERE username = 'GESTORUSUARIS_G2';
-- Connexió com a usuari gestorUsuaris ja ha sigut creat al ex 1 per error pero es part del exericici 2
CONNECT gestorUsuaris/grup02;

-- Eliminar objectes anteriors
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE A CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE seq_A';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_A_seq';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Crear taula A
CREATE TABLE A (
  id_seq NUMBER PRIMARY KEY,
  cognoms VARCHAR2(20),
  nom VARCHAR2(20),
  CONSTRAINT unq_nom UNIQUE (cognoms, nom)
);

-- Crear seqüència autonumèrica
CREATE SEQUENCE seq_A START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Crear trigger que assigna id_seq abans d'inserir
CREATE OR REPLACE TRIGGER trg_A_seq
BEFORE INSERT ON A
FOR EACH ROW
BEGIN
  :NEW.id_seq := seq_A.NEXTVAL;
END;
/

-- Insercions de prova
INSERT INTO A (cognoms, nom) VALUES ('Bon','hola');
INSERT INTO A (cognoms, nom) VALUES ('Bon','adeu');
INSERT INTO A (cognoms, nom) VALUES ('hola','bonaTarda');
COMMIT;

PROMPT === Taula A i trigger creats correctament ===

-- Validació ràpida
SELECT * FROM A;
