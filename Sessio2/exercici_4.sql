--------------------------------------------------------------------------------
-- EXERCICI 4: IMPLEMENTACIÓ COMPLETA (PRIVILEGIS + FUNCIONS + INSERTEXPERIMENT)
--------------------------------------------------------------------------------


/*---------------------------------------------------------------------------
    1. PRIVILEGIS (executar com a GestorUCI)
---------------------------------------------------------------------------*/

-- TestUCI només pot gestionar experiments i repeticions
GRANT INSERT, UPDATE ON EXPERIMENT TO testUCI;
GRANT INSERT, UPDATE ON REPETICIO TO testUCI;

-- TestUCI necessita executar la funció principal
GRANT EXECUTE ON insertExperiment TO testUCI;

-- Prohibir modificar Dataset i Samples
REVOKE INSERT, UPDATE, DELETE ON DATASET FROM testUCI;
REVOKE INSERT, UPDATE, DELETE ON SAMPLES FROM testUCI;



/*---------------------------------------------------------------------------
    2. FUNCIONS AUXILIARS NECESSÀRIES
---------------------------------------------------------------------------*/

-- (A) HASH SHA256 DEL JSON (PK de PARÀMETRES)
CREATE OR REPLACE FUNCTION get_param_hash(p_json JSON) 
RETURN VARCHAR2 IS
    v_hash VARCHAR2(64);
BEGIN
    SELECT STANDARD_HASH(p_json.to_string, 'SHA256')
    INTO v_hash
    FROM dual;
    RETURN v_hash;
END;
/
--------------------------------------------------------------------------------

-- (B) OBTENIR ID DEL DATASET
CREATE OR REPLACE FUNCTION get_dataset_id(p_name VARCHAR2)
RETURN NUMBER IS
    v_id NUMBER;
BEGIN
    SELECT id 
    INTO v_id
    FROM dataset
    WHERE name = p_name;

    RETURN v_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
--------------------------------------------------------------------------------

-- (C) OBTENIR / CREAR CLASSIFICADOR
CREATE OR REPLACE FUNCTION get_classificador_id(
    p_short VARCHAR2,
    p_long  VARCHAR2
) RETURN NUMBER IS
    v_id NUMBER;
BEGIN
    SELECT id 
    INTO v_id
    FROM classificador
    WHERE nom = p_short;

    RETURN v_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        INSERT INTO classificador(id, nom)
        VALUES (seq_classificador.NEXTVAL, p_short)
        RETURNING id INTO v_id;

        RETURN v_id;
END;
/
--------------------------------------------------------------------------------

-- (D) INSERIR PARÀMETRES SI NO EXISTEIXEN
CREATE OR REPLACE PROCEDURE ensure_parametres(
    p_hash   IN VARCHAR2,
    p_valors IN JSON
) IS
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_exists
    FROM parametres
    WHERE param_id = p_hash;

    IF v_exists = 0 THEN
        INSERT INTO parametres(param_id, valors)
        VALUES (p_hash, p_valors);
    END IF;
END;
/
--------------------------------------------------------------------------------



/*---------------------------------------------------------------------------
    3. FUNCIÓ PRINCIPAL insertExperiment (demanada a l’enunciat)
---------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION insertExperiment(
    p_dataset         IN VARCHAR2,
    p_classificador   IN VARCHAR2,
    p_nom_llarg_class IN VARCHAR2,
    p_iteracio        IN NUMBER,
    p_valors          IN JSON,
    p_data_experiment IN DATE,
    p_fscore          IN NUMBER,
    p_accuracy        IN NUMBER
) RETURN BOOLEAN IS

    v_dataset_id   NUMBER;
    v_class_id     NUMBER;
    v_param_hash   VARCHAR2(64);
    v_exp_id       NUMBER;

BEGIN
    --------------------------------------------------------------------
    -- 1. OBTENIR Dataset (ha d'existir)
    --------------------------------------------------------------------
    v_dataset_id := get_dataset_id(p_dataset);

    IF v_dataset_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Dataset no existeix: ' || p_dataset);
    END IF;

    --------------------------------------------------------------------
    -- 2. OBTENIR O CREAR Classificador 
    --------------------------------------------------------------------
    v_class_id := get_classificador_id(
        p_classificador,
        p_nom_llarg_class
    );

    --------------------------------------------------------------------
    -- 3. CALCULAR HASH dels paràmetres + inserir si cal
    --------------------------------------------------------------------
    v_param_hash := get_param_hash(p_valors);
    ensure_parametres(v_param_hash, p_valors);

    --------------------------------------------------------------------
    -- 4. CREAR EXPERIMENT
    --------------------------------------------------------------------
    INSERT INTO experiment(
        id_experiment,
        data,
        accuracy,
        f_score,
        dataset_id,
        classif_id,
        param_id
    ) VALUES (
        seq_experiment.NEXTVAL,
        p_data_experiment,
        p_accuracy,
        p_fscore,
        v_dataset_id,
        v_class_id,
        v_param_hash
    )
    RETURNING id_experiment INTO v_exp_id;

    --------------------------------------------------------------------
    -- 5. INSERIR REPETICIONS (fins a 50, segons p_iteracio)
    --------------------------------------------------------------------
    FOR i IN 1..p_iteracio LOOP
        INSERT INTO repeticio(
            id_rep,
            num,
            expe_id
        ) VALUES (
            seq_repeticio.NEXTVAL,
            i,
            v_exp_id
        );
    END LOOP;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR A insertExperiment: ' || SQLERRM);
        RETURN FALSE;
END;
/
--------------------------------------------------------------------------------
-- FI SCRIPT
--------------------------------------------------------------------------------
