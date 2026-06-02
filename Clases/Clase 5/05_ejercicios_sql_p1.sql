-- ============================================================
-- Sesión 5 - Ejercicios SQL
-- FLACSO ESEDA 2026
-- Para usar en DBeaver o pgAdmin
-- Conexión:
--   Host:     db.jcgopqiutpioycndzkdg.supabase.co
--   Puerto:   5432
--   Base:     postgres
--   Usuario:  tu_usuario (ver usuarios_sql.csv)
--   Password: flacso_eseda
-- ============================================================


-- Exploración inicial
--
-- Antes de empezar con los ejercicios, inspeccionamos las tablas disponibles y sus columnas.
-- En SQL esto se hace consultando el catálogo del sistema: information_schema.

-- Listar todas las tablas del schema public
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = 'public'
ORDER  BY table_name;


-- Listar columnas y tipos de una tabla específica
SELECT column_name,
       data_type
FROM   information_schema.columns
WHERE  table_schema = 'public'
  AND  table_name   = 'alumnos'
ORDER  BY ordinal_position;


-- Ejercicio 1 - Inspección de tablas
--
-- Equivalente al ejercicio 1 de Polars: cargar y ver las primeras filas de cada tabla.
-- En SQL no cargamos nada en memoria: consultamos directamente la base de datos.
--
-- Escribe una consulta SELECT para ver las primeras 5 filas de cada una de estas tablas:
-- alumnos, notas, asistencia, profesores, asigna_clase.

SELECT *
FROM   ________
LIMIT  5;


SELECT *
FROM   notas
LIMIT  ______;


SELECT *
FROM   asistencia
_______  5;


______ *
______   profesores
______ ;


______ *
______   asigna_clase
______ ;


-- Ejercicio 2 - Selección de columnas y CAST
--
-- Equivalente al ejercicio 2 de Polars: cambiar el tipo de una columna.
-- En Polars usamos .cast(pl.Categorical). En SQL usamos CAST o el operador ::
--
-- Consulta la tabla alumnos mostrando solo cod_estudiante, nombre y sexo.
-- Convierte cod_estudiante a tipo TEXT usando CAST y muestra los valores únicos de sexo.

-- Seleccionar columnas y castear cod_estudiante a TEXT
SELECT CAST(_______ AS _____),
       nombre,
       sexo
FROM   alumnos
LIMIT  5;


-- Valores únicos de sexo (equivalente a .unique())
SELECT DISTINCT sexo
FROM   alumnos
ORDER  BY sexo;


-- Ejercicio 3 - Seleccionar columnas y excluir
--
-- Equivalente al ejercicio 3 de Polars: eliminar columnas.
-- En SQL no existe un DROP de columnas en una consulta: simplemente no las listamos en el SELECT.
--
-- La tabla asistencia tiene una columna total. Escribe una consulta que devuelva todas
-- las columnas de asistencia excepto total, mostrando solo las primeras 3 filas.
--
-- Pista: lista explícitamente las columnas que sí quieres.

-- Primero inspeccionamos las columnas disponibles
SELECT column_name
FROM   information_schema.columns
WHERE  table_schema = 'public'
  AND  table_name   = 'asistencia'
ORDER  BY ordinal_position;


SELECT ____________,
       ____________,
       a_19950501, a_19950502, a_19950503,
       a_19950504, a_19950505, a_19950508,
       a_19950509, a_19950510, a_19950511,
       a_19950512, a_19950515, a_19950516,
       a_19950517, a_19950518, a_19950519,
       a_19950522, a_19950523, a_19950524,
       a_19950525, a_19950526, a_19950529,
       a_19950530, a_19950531
FROM   ____________
LIMIT  3;

-- Ejercicio 4 - Transformación numérica
--
-- Equivalente al ejercicio 4 de Polars: calcular altura_m a partir de altura.
-- En Polars: (pl.col("altura") / 100).round(2). En SQL: aritmética directa con ROUND.
--
-- Escribe una consulta que muestre nombre, altura y una columna nueva altura_m
-- con la altura en metros redondeada a 2 decimales. Muestra las primeras 5 filas.

SELECT nombre,
       altura,
       ROUND(__________, 2) __ _________
FROM   __________
LIMIT  5;


-- Ejercicio 5 - Normalizar texto con LOWER y TRIM
--
-- Equivalente al ejercicio 5 de Polars: homologar la columna materia para poder hacer joins.
-- En notas las materias están en mayúsculas sin tildes (MATEMATICAS).
-- En profesores están en minúsculas con tildes (matemáticas).
--
-- Escribe dos consultas que muestren los valores únicos de materia en cada tabla
-- después de aplicar LOWER() y TRIM(). Verifica que los valores coinciden.

-- Valores únicos de materia en notas después de normalizar
SELECT DISTINCT LOWER(TRIM(_______)) AS materia_norm
FROM   notas
ORDER  BY materia_norm;


-- Valores únicos de materia en profesores después de normalizar
SELECT DISTINCT LOWER(TRIM(______)) AS materia_norm
FROM   profesores
ORDER  BY materia_norm;


-- Después de normalizar con LOWER y TRIM todavía no coinciden porque notas tiene tildes
-- removidas y profesores las tiene. En SQL estándar no hay una función nativa para remover tildes;
-- en PostgreSQL se puede usar unaccent si está instalada la extensión.
-- Por ahora resolvemos el join con ILIKE o normalizando con REPLACE como hicimos en Polars.

-- Normalizar removiendo tildes con REPLACE encadenado
SELECT DISTINCT
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
           LOWER(TRIM(_______)),
       'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u') AS materia_norm
FROM   profesores
ORDER  BY materia_norm;


-- Ejercicio 6 - Agregación con GROUP BY
--
-- Equivalente al ejercicio 6 de Polars: group_by().agg().
--
-- Calcula la edad media de los alumnos desagregada por sexo.
-- Incluye el conteo de alumnos por grupo. Ordena por sexo.

SELECT sexo,
       ROUND(AVG(_____), 2) AS edad_media,
       COUNT(*)            AS n_alumnos
FROM   ______
________ ______
ORDER BY sexo;


-- Ejercicio 7 - JOIN y agregación
--
-- Equivalente al ejercicio 7 de Polars: unir notas con alumnos y calcular la nota media por paralelo.
--
-- Une notas con alumnos usando cod_estudiante como llave.
-- Calcula la nota media por paralelo e incluye el número de calificaciones no nulas.
-- Ordena por paralelo.

-- Primero: ver el resultado del join
SELECT a.paralelo,
       n.nombre,
       n.materia,
       n.nota
FROM   notas n
LEFT JOIN alumnos a USING (________)
LIMIT  10;


-- Luego: agregar por paralelo
SELECT a.paralelo,
       ROUND(AVG(n.nota), 2) AS nota_media,
       COUNT(n.nota)         AS n_notas
FROM   notas n
LEFT JOIN alumnos a USING (________)
GROUP  BY a.________
ORDER  BY a.________;


