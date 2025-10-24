-- ============================================================
-- EXERCICI 4 - GRUP 02
-- Creació de la taula C i del procediment procediment_1
-- ============================================================
GRANT CREATE PROCEDURE TO gestorUsuaris;
GRANT CREATE TABLE TO gestorUsuaris;
GRANT CREATE SEQUENCE TO gestorUsuaris;
GRANT CREATE TRIGGER TO gestorUsuaris;
GRANT CREATE SESSION TO gestorUsuaris;

CONNECT gestorUsuaris_g2/grup02;

-- Eliminar taula i procediment si ja existeixen
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE C CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP PROCEDURE procediment_1';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Crear taula C
CREATE TABLE C (
  id NUMBER PRIMARY KEY
);

-- Crear el procediment procediment_1
CREATE OR REPLACE PROCEDURE procediment_1(p_llista IN SYS.ODCINUMBERLIST) AS
  v_count NUMBER := 0;
BEGIN
  FOR i IN 1..p_llista.COUNT LOOP
    BEGIN
      INSERT INTO C VALUES (p_llista(i));
      v_count := v_count + 1;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN NULL; -- ignora duplicats
    END;

    EXIT WHEN v_count >= 100; -- màxim 100 insercions
  END LOOP;
  COMMIT;
END procediment_1;
/

-- Donar permisos a usuariTest per poder validar
GRANT EXECUTE ON procediment_1 TO usuariTest;
GRANT SELECT ON C TO usuariTest;
