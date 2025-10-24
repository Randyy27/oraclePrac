-- ============================================================
-- VALIDACIÓ EXERCICI 2 - GRUP 02
-- Comprovació de la taula A, seqüència i trigger de gestorUsuaris
-- ============================================================
-- Concedir privilegis necessaris a usuariTest
--executar com a gestotr
GRANT SELECT, INSERT ON A TO usuariTest;

CONNECT usuariTest/grup02;

SELECT table_name, owner
FROM all_tables
WHERE table_name = 'A' AND owner = 'GESTORUSUARIS';

-- Comprovar que existeix la seqüència i el trigger
SELECT sequence_name, last_number
FROM all_sequences
WHERE sequence_owner = 'GESTORUSUARIS';

SELECT trigger_name, table_name
FROM all_triggers
WHERE table_owner = 'GESTORUSUARIS';

-- Comptar el nombre de registres
SELECT COUNT(*) AS total_registres
FROM gestorUsuaris.A;

-- Mostrar el contingut de la taula per validació visual
SELECT * FROM gestorUsuaris.A ORDER BY id_seq;

-- Prova de la restricció UNIQUE
DECLARE
  e_duplicat EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_duplicat, -1); -- ORA-00001
BEGIN
  INSERT INTO gestorUsuaris.A (cognoms, nom) VALUES ('Bon', 'hola');
EXCEPTION
  WHEN e_duplicat THEN
    DBMS_OUTPUT.PUT_LINE('Restricció UNIQUE verificada correctament (duplicat detectat).');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('S''ha produït un altre error inesperat: ' || SQLERRM);
END;
/
