-- valida_exercici5.sql
CONNECT usuariTest/grup02;

-- Declarar un bloque PL/SQL para probar la función
SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_nom    ESPECTACLES.ESPECTACLES.nom_espectacle%TYPE;
    v_inici  ESPECTACLES.ESPECTACLES.data_inici%TYPE;
    v_fi     ESPECTACLES.ESPECTACLES.data_fi%TYPE;
    v_preu   ESPECTACLES.ESPECTACLES.preu%TYPE;
BEGIN
    -- Llamada a la función con un recinte conocido (ajústalo según tus datos)
    v_cursor := ESPECTACLES.llistatEspectacles('Palau Sant Jordi');

    LOOP
        FETCH v_cursor INTO v_nom, v_inici, v_fi, v_preu;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Espectacle: ' || v_nom || 
                             ', Inici: ' || v_inici || 
                             ', Fi: ' || v_fi || 
                             ', Preu: ' || v_preu);
    END LOOP;
    CLOSE v_cursor;
END;
/
