-- Mostrar perfils associats als usuaris
SELECT username, profile 
FROM dba_users
WHERE username IN ('USUARITEST','USUARIDEV','USUARIGESTOR');

-- Mostrar els rols que tenen assignats
SELECT grantee, granted_role 
FROM dba_role_privs
WHERE grantee IN ('USUARITEST','USUARIDEV','USUARIGESTOR');

-- Mostrar privilegis de sistema dels rols
SELECT grantee, privilege 
FROM dba_sys_privs
WHERE grantee IN ('ROL_TEST','ROL_DEV','ROL_GESTOR');

------------------------------------------------
-- 2. Validar con usuariTest
-- Ejecutar conectado como usuariTest
------------------------------------------------

-- SELECT hauria de funcionar
SELECT * FROM dual;

-- Intentar crear taula (ha de fallar)
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE prova_test (id NUMBER)';
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('usuariTest: no pot crear taules -> OK');
END;
/

------------------------------------------------
-- 3. Validar con usuariDev
-- Ejecutar conectado como usuariDev
------------------------------------------------

-- Intentar crear taula (ha de fallar)
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE prova_dev (id NUMBER)';
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('usuariDev: no pot crear taules -> OK');
END;
/


------------------------------------------------
-- 4. Validar con usuariGestor
-- Ejecutar conectado como usuariGestor
------------------------------------------------

-- Crear i esborrar taula hauria de funcionar
CREATE TABLE prova_gestor (id NUMBER);
DROP TABLE prova_gestor;
