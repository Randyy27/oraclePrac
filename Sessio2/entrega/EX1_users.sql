--------------------------------------------------------
-- EXERCICI 1 - Creació d’usuaris i assignació de rols
-- Pràctica UCI – Grup 02
--------------------------------------------------------

-- Creació dels usuaris
CREATE USER testUCI IDENTIFIED BY grup02 PROFILE perfil_test;
GRANT rol_test TO testUCI;
ALTER USER testUCI DEFAULT ROLE rol_test;

CREATE USER GestorUCI IDENTIFIED BY grup02 PROFILE perfil_gestor;
GRANT rol_gestor TO GestorUCI;
ALTER USER GestorUCI DEFAULT ROLE rol_gestor;

-- Assignació de quota sobre el tablespace
ALTER USER testUCI DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
ALTER USER GestorUCI DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;

-- Privilegis necessaris per a GestorUCI per crear objectes de BD
GRANT CREATE TABLE TO GestorUCI;
GRANT CREATE SEQUENCE TO GestorUCI;

--------------------------------------------------------
-- FINAL EXERCICI 1
--------------------------------------------------------
