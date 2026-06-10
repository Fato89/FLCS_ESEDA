-- ============================================================
-- Sesión 6 - Ejercicios SQL: DDL y DML
-- FLACSO ESEDA 2026
-- Para usar en DBeaver o pgAdmin
-- Conexión:
--   Host:     aws-1-sa-east-1.pooler.supabase.com
--   Puerto:   6543
--   Base:     postgres
--   Usuario:  <tu_usuario>.jcgopqiutpioycndzkdg (ver usuarios_sql.csv)
--   Password: flacso_eseda
-- ============================================================


-- ============================================================
-- Ejercicio 0 - Intro: permisos y schemas
--
-- En la sesión anterior tuvimos acceso de solo lectura sobre
-- el schema public. En esta sesión cada quien tiene su propio
-- schema con permisos completos para crear y modificar objetos.
--
-- Primero comprobamos qué pasa cuando intentamos escribir
-- sobre public.
-- ============================================================

-- Intentar insertar una fila en public.alumnos
-- Resultado esperado: ERROR de permisos
INSERT INTO public.alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,
                            altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (999, 'Prueba Permiso', 'M', 25, 'Ecuador', 'Quito', 170, 'A', 1999, 1, 1);


-- Verificar cuál es nuestro schema personal
-- Cada schema lleva el nombre de usuario asignado
SELECT schema_name
FROM   information_schema.schemata
WHERE  schema_name NOT IN ('public', 'pg_catalog', 'information_schema',
                           'pg_toast', 'pg_temp_1', 'pg_toast_temp_1')
  AND  schema_name NOT LIKE 'pg_%'
ORDER  BY schema_name;


-- ============================================================
-- Ejercicio 1 - DDL: CREATE TABLE, ALTER TABLE, DROP TABLE
--              y SET search_path
--
-- Creamos tablas en nuestro schema personal, inspeccionamos
-- los objetos creados con information_schema, y simplificamos
-- el trabajo con SET search_path.
-- ============================================================

-- Reemplaza <tu_esquema> con tu nombre de schema en todas
-- las consultas de este ejercicio.


-- Crear una tabla de prueba con nombre temporal
CREATE TABLE <tu_esquema>.notas_123 (
    cod_estudiante  INTEGER,
    nombre          TEXT,
    materia         TEXT,
    nota            NUMERIC
);


-- Verificar que la tabla existe en nuestro schema
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = '<tu_esquema>'
ORDER  BY table_name;


-- Renombrar la tabla a su nombre definitivo
ALTER TABLE <tu_esquema>.notas_123 RENAME TO notas;


-- Verificar el cambio de nombre
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = '<tu_esquema>'
ORDER  BY table_name;


-- Crear la tabla alumnos con PRIMARY KEY y CHECK
CREATE TABLE <tu_esquema>.alumnos (
    cod_estudiante  INTEGER       PRIMARY KEY,
    nombre          TEXT          NOT NULL,
    sexo            TEXT          NOT NULL CHECK (sexo IN ('m', 'f')),
    edad            INTEGER       CHECK (edad >= 0 AND edad <= 120),
    pais            TEXT,
    ciudad          TEXT,
    altura          NUMERIC,
    paralelo        TEXT,
    anio_nac        INTEGER,
    mes_nac         INTEGER,
    dia_nac         INTEGER
);


-- Verificar columnas y restricciones de la tabla creada
SELECT column_name,
       data_type,
       is_nullable
FROM   information_schema.columns
WHERE  table_schema = '<tu_esquema>'
  AND  table_name   = 'alumnos'
ORDER  BY ordinal_position;


-- Ver las restricciones (constraints) definidas en la tabla
SELECT constraint_name,
       constraint_type
FROM   information_schema.table_constraints
WHERE  table_schema = '<tu_esquema>'
  AND  table_name   = 'alumnos'
ORDER  BY constraint_type;


-- Agregar una columna nueva con ALTER TABLE
ALTER TABLE <tu_esquema>.alumnos
    ADD COLUMN email TEXT;


-- Verificar que la columna fue agregada
SELECT column_name, data_type
FROM   information_schema.columns
WHERE  table_schema = '<tu_esquema>'
  AND  table_name   = 'alumnos'
ORDER  BY ordinal_position;


-- Eliminar la columna recién agregada
ALTER TABLE <tu_esquema>.alumnos
    DROP COLUMN email;


-- Crear una tabla temporal solo para practicar DROP
CREATE TABLE <tu_esquema>.tabla_de_prueba (id INTEGER);

-- Eliminar la tabla (IF EXISTS evita error si no existe)
DROP TABLE IF EXISTS <tu_esquema>.tabla_de_prueba;

-- Verificar que ya no existe
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = '<tu_esquema>'
ORDER  BY table_name;


-- Hasta aqui escribimos <tu_esquema> en cada consulta.
-- Con SET search_path el motor busca primero en nuestro schema
-- y no hace falta calificar cada nombre de tabla.

SET search_path TO <tu_esquema>;

-- A partir de aqui podemos escribir solo el nombre de la tabla
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = '<tu_esquema>'
ORDER  BY table_name;


-- ============================================================
-- Ejercicio 2 - DDL: FOREIGN KEY, CHECK y restricciones
--
-- Creamos la tabla notas con una llave foranea que referencia
-- a alumnos. Esto garantiza integridad referencial: no puede
-- existir una nota de un alumno que no este en alumnos.
--
-- ON DELETE CASCADE significa que si se borra un alumno,
-- sus notas se borran automaticamente.
--
-- Nota sobre cuotas_pagadas en public.viaje:
--   Esa columna acepta texto libre. Por eso encontramos valores
--   como 'si', 'SI', 'Si', 'pagado', etc. Un CHECK al momento
--   de crear la tabla hubiera forzado un conjunto fijo de valores
--   y evitado ese problema desde el origen.
-- ============================================================

-- Recrear notas con estructura completa, FK y CHECK
-- Primero eliminamos la version sin restricciones del ejercicio 1
DROP TABLE IF EXISTS notas;

CREATE TABLE notas (
    cod_estudiante  INTEGER NOT NULL REFERENCES alumnos (cod_estudiante) ON DELETE CASCADE,
    nombre          TEXT,
    materia         TEXT    NOT NULL,
    nota            NUMERIC CHECK (nota >= 0 AND nota <= 10)
);
/*
CREATE TABLE notas (
    cod_estudiante  INTEGER,
    nombre          TEXT,
    materia         TEXT,
    nota            NUMERIC,

    CONSTRAINT notas_cod_estudiante_fk FOREIGN KEY (cod_estudiante) REFERENCES alumnos (cod_estudiante) ON DELETE CASCADE,
    CONSTRAINT notas_cod_estudiante_not_null CHECK (cod_estudiante IS NOT NULL),
    CONSTRAINT notas_materia_not_null CHECK (materia IS NOT NULL),
    CONSTRAINT notas_nota_rango CHECK (nota >= 0 AND nota <= 10)
);
*/

-- Verificar restricciones de notas
SELECT constraint_name,
       constraint_type
FROM   information_schema.table_constraints
WHERE  table_schema = '<tu_esquema>'
  AND  table_name   = 'notas'
ORDER  BY constraint_type;



-- ============================================================
-- Ejercicio 3 - DML: INSERT, UPDATE, DELETE
--
-- Trabajamos sobre las tablas creadas en los ejercicios
-- anteriores. Primero insertamos filas una a una, luego
-- copiamos datos desde public.alumnos con INSERT ... SELECT.
-- Practicamos UPDATE y DELETE con y sin WHERE, y verificamos
-- el comportamiento del CASCADE al borrar un alumno.
-- ============================================================

-- INSERT fila a fila en alumnos
INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,
                     altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (1, 'Ana Torres', 'f', 28, 'Ecuador', 'Quito', 165, 'A', 1996, 3, 12);

INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,
                     altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (2, 'Luis Parra', 'm', 31, 'Colombia', 'Bogotá', 178, 'B', 1993, 7, 4);

INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,
                     altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (3, 'María León', 'f', 26, 'Perú', 'Lima', 160, 'A', 1998, 11, 22);


-- Verificar las filas insertadas
SELECT * FROM alumnos;


-- Intentar violar el CHECK de sexo
-- Resultado esperado: ERROR de restriccion
INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,
                     altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (4, 'Prueba Check', 'X', 25, 'Ecuador', 'Guayaquil', 170, 'A', 1999, 1, 1);


-- INSERT fila a fila en notas
INSERT INTO notas (cod_estudiante, nombre, materia, nota)
VALUES (1, 'Ana Torres', 'matematicas', 8.5);

INSERT INTO notas (cod_estudiante, nombre, materia, nota)
VALUES (1, 'Ana Torres', 'castellano', 7.0);

INSERT INTO notas (cod_estudiante, nombre, materia, nota)
VALUES (2, 'Luis Parra', 'matematicas', 6.5);


-- Intentar insertar una nota de un alumno que no existe en alumnos
-- Resultado esperado: ERROR de integridad referencial
INSERT INTO notas (cod_estudiante, nombre, materia, nota)
VALUES (999, 'Fantasma', 'matematicas', 5.0);


-- TRUNCATE: elimina todas las filas de la tabla de forma rápida
-- A diferencia de DELETE, no recorre fila a fila: vacía la tabla entera
-- Como notas tiene FK que referencia a alumnos, hay que truncar ambas
-- o usar CASCADE para que lo haga automáticamente

-- Truncar la tabla alumnos con cascade y verificar que ambas tengan cero filas

TRUNCATE TABLE alumnos CASCADE;

-- Verificar que ambas tablas quedaron vacías
SELECT * FROM alumnos;
SELECT * FROM notas;


-- INSERT desde SELECT: copiar el resto de alumnos desde public
-- Solo insertamos los que no insertamos manualmente (cod > 3)
INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,altura, paralelo, anio_nac, mes_nac, dia_nac)
SELECT cod_estudiante, nombre, sexo, edad, pais, ciudad,altura, paralelo, anio_nac, mes_nac, dia_nac
FROM   public.alumnos;


-- Verificar cuantos alumnos tenemos ahora
SELECT COUNT(*) AS total FROM alumnos;


-- UPDATE con WHERE: corregir la ciudad de un alumno
UPDATE alumnos
SET    ciudad = 'Cuenca'
WHERE  cod_estudiante = 1;

-- Verificar el cambio
SELECT cod_estudiante, nombre, ciudad FROM alumnos WHERE cod_estudiante = 1;


-- UPDATE sin WHERE: afecta TODAS las filas
-- Descomentar solo si se quiere ver el efecto (y luego revertir)
-- UPDATE alumnos SET paralelo = 'Z';


-- DELETE con WHERE: eliminar una fila especifica
-- Primero insertamos una fila de prueba para borrarla
INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,
                     altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (500, 'Para Borrar', 'M', 20, 'Ecuador', 'Quito', 170, 'A', 2004, 1, 1);

SELECT * FROM alumnos WHERE cod_estudiante = 500;

DELETE FROM alumnos WHERE cod_estudiante = 500;

SELECT * FROM alumnos WHERE cod_estudiante = 500;


-- Demostrar ON DELETE CASCADE
-- Al borrar un alumno, sus notas se eliminan automaticamente

-- Ver notas del alumno 1 antes de borrarlo
SELECT * FROM notas WHERE cod_estudiante = 1;

-- Borrar el alumno
DELETE FROM alumnos WHERE cod_estudiante = 1;

-- Las notas del alumno 1 ya no existen
SELECT * FROM notas WHERE cod_estudiante = 1;

-- Confirmar que el resto de notas sigue intacto
SELECT * FROM notas;


-- DELETE sin WHERE: elimina TODAS las filas de la tabla
-- No ejecutar en produccion sin respaldo
-- DELETE FROM alumnos;
