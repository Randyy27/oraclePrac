-- valida_exercici6.sql
CONNECT usuariTest/grup02;
SET SERVEROUTPUT ON;

DECLARE
    v_id_recinte RECINTES.id_recinte%TYPE;
    v_capacitat_abans NUMBER;
    v_capacitat_despres NUMBER;
    v_id_seient NUMBER;
BEGIN
    -- Triar un recinte existent per fer la prova
    SELECT id_recinte INTO v_id_recinte
    FROM (SELECT id_recinte FROM ESPECTACLES.RECINTES WHERE ROWNUM = 1);

    -- Obtenir la capacitat inicial
    SELECT capacitat INTO v_capacitat_abans
    FROM ESPECTACLES.RECINTES
    WHERE id_recinte = v_id_recinte;

    DBMS_OUTPUT.PUT_LINE('Capacitat abans: ' || v_capacitat_abans);

    -- Inserir un nou seient de prova
    v_id_seient := 9999; -- ID temporal de prova
    INSERT INTO ESPECTACLES.SEIENTS (id_seient, id_recinte)
    VALUES (v_id_seient, v_id_recinte);

    -- Consultar la capacitat després de la inserció
    SELECT capacitat INTO v_capacitat_despres
    FROM ESPECTACLES.RECINTES
    WHERE id_recinte = v_id_recinte;

    DBMS_OUTPUT.PUT_LINE('Capacitat després d''inserir: ' || v_capacitat_despres);

    IF v_capacitat_despres = v_capacitat_abans + 1 THEN
        DBMS_OUTPUT.PUT_LINE(' Trigger tr_cap_zones_up OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE(' Error en tr_cap_zones_up');
    END IF;

    -- Esborrar el seient afegit
    DELETE FROM ESPECTACLES.SEIENTS WHERE id_seient = v_id_seient;

    -- Tornar a consultar la capacitat
    SELECT capacitat INTO v_capacitat_despres
    FROM ESPECTACLES.RECINTES
    WHERE id_recinte = v_id_recinte;

    DBMS_OUTPUT.PUT_LINE('Capacitat després d''esborrar: ' || v_capacitat_despres);

    IF v_capacitat_despres = v_capacitat_abans THEN
        DBMS_OUTPUT.PUT_LINE(' Trigger tr_cap_zones_down OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE(' Error en tr_cap_zones_down');
    END IF;
END;
/

