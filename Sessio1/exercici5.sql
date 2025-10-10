-- exercici5.sql
-- Crear usuario ESPECTACLES y asignar rol

CREATE USER ESPECTACLES IDENTIFIED BY grup02
PROFILE perfil_dev
DEFAULT TABLESPACE users
QUOTA UNLIMITED ON users;

GRANT rol_dev TO ESPECTACLES;
ALTER USER ESPECTACLES DEFAULT ROLE rol_dev;
GRANT CONNECT, RESOURCE TO ESPECTACLES;

-- Si ya tienes un rol específico como "Gestor" o "Desenvolupador", podrías usar:
-- GRANT Gestor TO ESPECTACLES;

-- Dar permisos de creación de objetos
ALTER USER ESPECTACLES QUOTA UNLIMITED ON USERS;

-- Conectar como el usuario ESPECTACLES
CONNECT ESPECTACLES/grup02;

-- (1) Importar las tablas del script de la base de dades ESPECTACLES
-- Ejecuta aquí el script que te dan en el campus virtual, por ejemplo:
-- @importa_ESPECTACLES.sql
-- (no olvides colocar ese fichero en el mismo directorio)

-- (2) Crear la función PL/SQL
CREATE OR REPLACE FUNCTION llistatEspectacles(p_recinte VARCHAR2)
RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT e.nom_espectacle, e.data_inici, e.data_fi, e.preu
        FROM ESPECTACLES e
        JOIN RECINTES r ON e.id_recinte = r.id_recinte
        WHERE UPPER(r.nom_recinte) = UPPER(p_recinte);
    RETURN v_cursor;
END;
/

-- Dar permisos de ejecución a usuariTest
GRANT EXECUTE ON llistatEspectacles TO usuariTest;
