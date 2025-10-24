
-- Connexió com SYS
CONNECT / AS SYSDBA;

-- Creació del tablespace PROVA (màxim 512MB)
CREATE TABLESPACE PROVA
DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/prova.dbf'
SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 512M;

-- Creació de l’usuari gestorUsuaris
CREATE USER gestorUsuaris IDENTIFIED BY gestor
DEFAULT TABLESPACE PROVA
QUOTA UNLIMITED ON PROVA;

-- Concessió de privilegis bàsics
GRANT CONNECT, RESOURCE, CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO gestorUsuaris;

-- Connexió com a gestorUsuaris
CONNECT gestorUsuaris/gestor@FREEPDB1;

-- Creació de la taula Test al tablespace PROVA
CREATE TABLE Test (
    camp1 VARCHAR2(30),
    camp2 NUMBER
) TABLESPACE PROVA;

-- Creació de la seqüència per a insercions massives
CREATE SEQUENCE seq_test START WITH 1 INCREMENT BY 1;

-- Inserció de 150.000 registres amb un bloc PL/SQL
BEGIN
  FOR i IN 1..150000 LOOP
    INSERT INTO Test (camp1, camp2)
    VALUES ('Valor ' || i, seq_test.NEXTVAL);
  END LOOP;
  COMMIT;
END;
/

-- Consulta de l’espai utilitzat
SELECT tablespace_name, bytes/1024/1024 AS MB, autoextensible
FROM dba_data_files
WHERE tablespace_name='PROVA';

-- En cas de quedar-se sense espai:
-- ALTER DATABASE DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/prova.dbf' RESIZE 512M;

EXIT;
