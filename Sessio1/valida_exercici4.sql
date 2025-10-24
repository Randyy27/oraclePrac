CONNECT usuariTest/grup02;

SET SERVEROUTPUT ON;

DECLARE
  v_llista SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
BEGIN
  -- Generem 150 números aleatoris (amb alguns repetits)
  FOR i IN 1..150 LOOP
    v_llista.EXTEND;
    v_llista(i) := TRUNC(DBMS_RANDOM.VALUE(1, 120)); -- valors entre 1 i 120
  END LOOP;

  -- Cridem al procediment del gestorUsuaris
  gestorUsuaris.procediment_1(v_llista);

  DBMS_OUTPUT.PUT_LINE('Procediment executat correctament.');
END;
/

-- Comprovem que hi ha exactament 100 registres únics
SELECT COUNT(*) AS total_uniques
FROM gestorUsuaris.C;

-- Mostrem una mostra dels primers 10 valors
SELECT * FROM gestorUsuaris.C FETCH FIRST 10 ROWS ONLY;
