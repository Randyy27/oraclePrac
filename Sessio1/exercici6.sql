-- exercici6.sql
CONNECT ESPECTACLES/grup02;

-- TRIGGER: tr_cap_zones_up
-- Incrementa la capacitat del recinte quan s'insereix un seient
CREATE OR REPLACE TRIGGER tr_cap_zones_up
AFTER INSERT ON SEIENTS
FOR EACH ROW
BEGIN
    UPDATE RECINTES
    SET capacitat = capacitat + 1
    WHERE id_recinte = :NEW.id_recinte;
END;
/
SHOW ERRORS;

-- TRIGGER: tr_cap_zones_down
-- Decrementa la capacitat del recinte quan s'elimina un seient
CREATE OR REPLACE TRIGGER tr_cap_zones_down
AFTER DELETE ON SEIENTS
FOR EACH ROW
BEGIN
    UPDATE RECINTES
    SET capacitat = capacitat - 1
    WHERE id_recinte = :OLD.id_recinte;
END;
/
SHOW ERRORS;

-- Donar permís al usuariTest per fer la validació
GRANT SELECT, INSERT, DELETE ON SEIENTS TO usuariTest;
GRANT SELECT ON RECINTES TO usuariTest;

