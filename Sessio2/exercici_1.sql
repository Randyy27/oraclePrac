-- Exercici 1: Creació d’usuaris addicionals per a la pràctica UCI (grup 02)

-- USUARIS PER A LA PRÀCTICA UCI
CREATE USER testUCI IDENTIFIED BY grup02 PROFILE perfil_test;
GRANT rol_test TO testUCI;
ALTER USER testUCI DEFAULT ROLE rol_test;

CREATE USER GestorUCI IDENTIFIED BY grup02 PROFILE perfil_gestor;
GRANT rol_gestor TO GestorUCI;
ALTER USER GestorUCI DEFAULT ROLE rol_gestor;

-- PRIVILEGIS DIRECTES (només si fossin necessaris)
-- *Només s’afegeixen si el notebook no pot crear taules o seqüències.*
-- *Si s’afegeixen, s’han de justificar a l’informe.*

-- TABLESPACE I QUOTA
ALTER USER testUCI DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
ALTER USER GestorUCI DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;

-- Permisos para crear y manejar tablas dentro de su esquema
GRANT CREATE TABLE TO GestorUCI;
GRANT CREATE SEQUENCE TO GestorUCI;
