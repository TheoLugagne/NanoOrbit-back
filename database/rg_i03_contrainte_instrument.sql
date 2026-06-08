ALTER TABLE EMBARQUE
    ADD UNIQUE INDEX uk_rg_i03_ref_instrument (ref_instrument);

DROP TRIGGER IF EXISTS trg_embarque_rg_i03_before_insert;
DROP TRIGGER IF EXISTS trg_embarque_rg_i03_before_update;

DELIMITER /

CREATE TRIGGER trg_embarque_rg_i03_before_insert
    BEFORE INSERT ON EMBARQUE
    FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM EMBARQUE
        WHERE ref_instrument = NEW.ref_instrument
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG-I03 : cet instrument est déjà embarqué sur un autre satellite';
    END IF;
END/

CREATE TRIGGER trg_embarque_rg_i03_before_update
    BEFORE UPDATE ON EMBARQUE
    FOR EACH ROW
BEGIN
    IF NEW.ref_instrument <> OLD.ref_instrument
       AND EXISTS (
           SELECT 1
           FROM EMBARQUE
           WHERE ref_instrument = NEW.ref_instrument
             AND id_satellite <> NEW.id_satellite
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG-I03 : cet instrument est déjà embarqué sur un autre satellite';
    END IF;
END/

