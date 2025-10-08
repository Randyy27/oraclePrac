-- ======================================
-- EXERCICI 3
-- ======================================


CREATE USER userPLSQL IDENTIFIED BY grup02
  PROFILE perfil_dev
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;

GRANT rol_dev TO userPLSQL;
ALTER USER userPLSQL DEFAULT ROLE rol_dev;

-- ===== (2) gestorUsuaris: crear tabla B y dar permisos =====
-- Cambia de conexión a gestorUsuaris antes de ejecutar esto
DROP table B;
CREATE TABLE B (
  id NUMBER,
  CONSTRAINT pk_B PRIMARY KEY (id)
);

-- Aunque rol_dev ya tiene INSERT ANY TABLE en tu diseño,
-- damos el permiso de objeto por claridad y mínimo privilegio:
GRANT INSERT ON B TO userPLSQL;

-- ===== (3) userPLSQL: insertar 100 números aleatorios =====

DECLARE
  v_inserted NUMBER := 0;
  v_val      NUMBER;
BEGIN
  WHILE v_inserted < 100 LOOP
    v_val := TRUNC(DBMS_RANDOM.VALUE(1, 1000000));
    BEGIN
      INSERT INTO gestorUsuaris.B (id) VALUES (v_val);
      v_inserted := v_inserted + 1;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
  END LOOP;
  COMMIT;
END;
/
SELECT COUNT(*) FROM gestorUsuaris.B;

