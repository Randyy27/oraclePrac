GRANT SELECT ON gestorUsuaris.B TO usuariTest;
SELECT COUNT(*) FROM gestorUsuaris.B;

SELECT * 
FROM gestorUsuaris.B
FETCH FIRST 10 ROWS ONLY;
