--------------------------------------------------------
-- EXERCICI 5 - Vistes agregades i millor configuració
-- Pràctica UCI – Grup 02
--------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------
-- 1. VISTA MATERIALITZADA AMB RESULTATS D'EXPERIMENTS
--------------------------------------------------------
CREATE MATERIALIZED VIEW MV_EXP_RESULTS
BUILD IMMEDIATE
REFRESH COMPLETE
ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    d.NAME                           AS DATASET_NAME,
    c.NOM                            AS CLASSIFICADOR,
    p.PARAM_ID,
    DBMS_LOB.SUBSTR(p.VALORS, 4000)  AS PARAMETRES,
    TRUNC(e.DATA_EXPERIMENT)         AS DATA_EXP,
    AVG(e.ACCURACY)                  AS AVG_ACCURACY,
    AVG(e.F_SCORE)                   AS AVG_F_SCORE,
    COUNT(*)                         AS NUM_EXPERIMENTS
FROM EXPERIMENT e
JOIN DATASET d       ON e.DATASET_ID = d.ID
JOIN CLASSIFICADOR c ON e.CLASSIF_ID = c.ID
JOIN PARAMETERS p    ON e.PARAM_ID = p.PARAM_ID
GROUP BY
    d.NAME, c.NOM, p.PARAM_ID, DBMS_LOB.SUBSTR(p.VALORS,4000), TRUNC(e.DATA_EXPERIMENT)
/
--------------------------------------------------------

--------------------------------------------------------
-- 2. ÍNDEXS PER OPTIMITZAR CONSULTES SOBRE MV_EXP_RESULTS
--------------------------------------------------------
CREATE INDEX IDX_MV_DATASET  ON MV_EXP_RESULTS (DATASET_NAME);
CREATE INDEX IDX_MV_CLASSIF  ON MV_EXP_RESULTS (CLASSIFICADOR);
/
--------------------------------------------------------

--------------------------------------------------------
-- 3. VISTA FINAL AMB LA MILLOR CONFIGURACIÓ PER DATASET
--    I CLASSIFICADOR
--------------------------------------------------------
CREATE OR REPLACE VIEW BEST_PARAM_CONFIG AS
WITH stats AS (
    SELECT
        DATASET_NAME,
        CLASSIFICADOR,
        STDDEV(AVG_ACCURACY) AS STD_ACCURACY,
        STDDEV(AVG_F_SCORE)  AS STD_F_SCORE,
        MAX(AVG_ACCURACY)    AS BEST_ACC
    FROM MV_EXP_RESULTS
    GROUP BY DATASET_NAME, CLASSIFICADOR
)
SELECT
    m.DATASET_NAME,
    m.CLASSIFICADOR,
    m.PARAMETRES,
    m.AVG_ACCURACY,
    m.AVG_F_SCORE,
    s.STD_ACCURACY,
    s.STD_F_SCORE
FROM MV_EXP_RESULTS m
JOIN stats s
    ON m.DATASET_NAME = s.DATASET_NAME
   AND m.CLASSIFICADOR = s.CLASSIFICADOR
   AND m.AVG_ACCURACY = s.BEST_ACC
/
--------------------------------------------------------

--------------------------------------------------------
-- 4. REFRESCAR LA MATERIALIZED VIEW (opcional per proves)
--------------------------------------------------------
BEGIN
    DBMS_MVIEW.REFRESH('MV_EXP_RESULTS', 'C');
END;
/
--------------------------------------------------------
-- FI DE L'EXERCICI 5
--------------------------------------------------------
