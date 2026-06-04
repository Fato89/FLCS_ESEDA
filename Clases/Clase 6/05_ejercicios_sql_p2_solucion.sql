-- ============================================================
-- Sesión 5 - Ejercicios SQL
-- FLACSO ESEDA 2026
-- Para usar en DBeaver o pgAdmin
-- Conexión:
--   Host:     aws-1-sa-east-1.pooler.supabase.com
--   Puerto:   6543
--   Base:     postgres
--   Usuario:  <tu_usuario>.jcgopqiutpioycndzkdg (ver usuarios_sql.csv)
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
FROM   alumnos
LIMIT  5;


SELECT *
FROM   notas
LIMIT  5;


SELECT *
FROM   asistencia
LIMIT  5;


SELECT *
FROM   profesores
LIMIT  5;


SELECT *
FROM   asigna_clase
LIMIT  5;


-- Ejercicio 2 - Selección de columnas y CAST
--
-- Equivalente al ejercicio 2 de Polars: cambiar el tipo de una columna.
-- En Polars usamos .cast(pl.Categorical). En SQL usamos CAST o el operador ::.
--
-- Consulta la tabla alumnos mostrando solo cod_estudiante, nombre y sexo.
-- Convierte cod_estudiante a tipo TEXT usando CAST y muestra los valores únicos de sexo.

-- Seleccionar columnas y castear cod_estudiante a TEXT
SELECT CAST(cod_estudiante AS TEXT) AS cod_estudiante,
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


SELECT cod_estudiante,
       nombre,
       a_19950501, a_19950502, a_19950503,
       a_19950504, a_19950505, a_19950508,
       a_19950509, a_19950510, a_19950511,
       a_19950512, a_19950515, a_19950516,
       a_19950517, a_19950518, a_19950519,
       a_19950522, a_19950523, a_19950524,
       a_19950525, a_19950526, a_19950529,
       a_19950530, a_19950531
FROM   asistencia
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
       ROUND(altura / 100.0, 2) AS altura_m
FROM   alumnos
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
SELECT DISTINCT LOWER(TRIM(materia)) AS materia_norm
FROM   notas
ORDER  BY materia_norm;


-- Valores únicos de materia en profesores después de normalizar
SELECT DISTINCT LOWER(TRIM(materia)) AS materia_norm
FROM   profesores
ORDER  BY materia_norm;


-- Después de normalizar con LOWER y TRIM todavía no coinciden porque notas tiene tildes
-- removidas y profesores las tiene. En SQL estándar no hay una función nativa para remover tildes;
-- en PostgreSQL se puede usar unaccent si está instalada la extensión.
-- Por ahora resolvemos el join con ILIKE o normalizando con REPLACE como hicimos en Polars.

-- Normalizar removiendo tildes con REPLACE encadenado
SELECT DISTINCT
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
           LOWER(TRIM(materia)),
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
       ROUND(AVG(edad), 2) AS edad_media,
       COUNT(*)            AS n_alumnos
FROM   alumnos
GROUP  BY sexo
ORDER  BY sexo;


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
LEFT JOIN alumnos a USING (cod_estudiante)
LIMIT  10;


-- Luego: agregar por paralelo
SELECT a.paralelo,
       ROUND(AVG(n.nota), 2) AS nota_media,
       COUNT(n.nota)         AS n_notas
FROM   notas n
LEFT JOIN alumnos a USING (cod_estudiante)
GROUP  BY a.paralelo
ORDER  BY a.paralelo;

-- Ejercicio 8 - CASE WHEN y agregación de asistencia
--
-- Equivalente al ejercicio 8 de Polars: recodificar X a 1 y nulo a 0, calcular tasa de asistencia
-- y variable booleana por alumno.
--
-- En Polars usamos unpivot() para pasar de wide a long. En SQL usamos directamente
-- las columnas de días en el SELECT con CASE WHEN, sin necesidad de reshape.
--
-- Calcula la tasa de asistencia por alumno como el promedio de los días asistidos.
-- Agrega una columna asistencia_ok que sea TRUE si la tasa supera el 80%.

-- Paso intermedio: ver la lógica de CASE WHEN para un día
SELECT cod_estudiante,
       nombre,
       a_19950501,
       CASE WHEN a_19950501 = 'X' THEN 1 ELSE 0 END AS asistio_01
FROM   asistencia
LIMIT  5;

-- Tasa de asistencia por alumno sumando todos los días
SELECT cod_estudiante,
       nombre,
       (CASE WHEN a_19950501='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950502='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950503='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950504='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950505='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950508='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950509='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950510='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950511='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950512='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950515='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950516='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950517='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950518='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950519='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950522='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950523='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950524='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950525='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950526='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950529='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950530='X' THEN 1 ELSE 0 END +
        CASE WHEN a_19950531='X' THEN 1 ELSE 0 END
       )                                            AS dias_asistidos,
       ROUND(
         (CASE WHEN a_19950501='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950502='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950503='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950504='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950505='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950508='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950509='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950510='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950511='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950512='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950515='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950516='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950517='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950518='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950519='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950522='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950523='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950524='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950525='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950526='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950529='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950530='X' THEN 1 ELSE 0 END +
          CASE WHEN a_19950531='X' THEN 1 ELSE 0 END
         ) / 23::numeric
       , 3)                                         AS tasa_asistencia
FROM   asistencia
ORDER  BY tasa_asistencia DESC;


-- Usando CTE para no repetir el cálculo y agregar asistencia_ok
-- Un CTE (Common Table Expression) es un resultado temporal referenciable en un SELECT definida con WITH
WITH dias_largo AS (
    SELECT cod_estudiante,
           nombre,
           valor
    FROM   asistencia a
    CROSS JOIN LATERAL (
        VALUES
            (a_19950501), (a_19950502), (a_19950503),
            (a_19950504), (a_19950505), (a_19950508),
            (a_19950509), (a_19950510), (a_19950511),
            (a_19950512), (a_19950515), (a_19950516),
            (a_19950517), (a_19950518), (a_19950519),
            (a_19950522), (a_19950523), (a_19950524),
            (a_19950525), (a_19950526), (a_19950529),
            (a_19950530), (a_19950531)
    ) AS dias(valor)
),
asistencia_calc AS (
    SELECT cod_estudiante,
           nombre,
           ROUND(AVG((valor = 'X')::int), 3) AS tasa_asistencia
    FROM   dias_largo
    GROUP  BY cod_estudiante, nombre
)
SELECT cod_estudiante,
       nombre,
       tasa_asistencia,
       tasa_asistencia > 0.80 AS asistencia_ok
FROM   asistencia_calc
ORDER  BY tasa_asistencia DESC;


-- PASO A PASO
-- VALUES permite generar una tabla constante, tupla a tupla (tupla 1), (tupla 2)

SELECT * FROM (VALUES ('X'), (NULL), ('X')) AS dias(valor);

-- CORSS JOIN hace un join de todos contra todos (piensen en el peligro en tablas grandes, un producto cartesiano)
-- En este caso repite cada estudiante 3 veces

SELECT a.cod_estudiante,
       a.nombre,
       d.valor
FROM   asistencia a
CROSS JOIN 
	(VALUES ('X'), (NULL), ('X')) AS d(valor)
LIMIT 15;

-- LATERAL permite interactuar con las columnas de la tabla izquierda
-- Así se pueden incluir directamente en VALUES de la derecha referencie columnas de la tabla de la izquierda. 
-- Ahora cada fila de asistencia genera sus propias 23 filas con sus propios valores

SELECT cod_estudiante,
       nombre,
       valor
FROM   asistencia
CROSS JOIN LATERAL (
    VALUES
        (a_19950501), (a_19950502), (a_19950503),
        (a_19950504), (a_19950505), (a_19950508),
        (a_19950509), (a_19950510), (a_19950511),
        (a_19950512), (a_19950515), (a_19950516),
        (a_19950517), (a_19950518), (a_19950519),
        (a_19950522), (a_19950523), (a_19950524),
        (a_19950525), (a_19950526), (a_19950529),
        (a_19950530), (a_19950531)
) AS dias(valor);

-- Bloque 1 - Full join: alumnos originales y nuevos
--
-- Equivalente al bloque 1 de Polars: full join entre los 20 alumnos originales y los 8 nuevos
-- para identificar cuáles son incorporaciones tardías.
--
-- Las tablas alumnos y nuevos_alumnos ya están cargadas en la base de datos con las
-- 28 filas combinadas. Para reproducir el ejercicio original trabajamos directamente
-- con alumnos (20 originales) y nuevos_alumnos (8 nuevos) por separado.
--
-- Nota: nuevos_alumnos tiene columnas en mayúsculas. Para referenciarlas usa comillas dobles:
-- "COD_ESTUDIANTE", "NOMBRE_APELLIDOS", etc.

-- Inspeccionamos nuevos_alumnos
SELECT * FROM nuevos_alumnos LIMIT  5;


SELECT a.cod_estudiante,
       a.nombre,
       b."COD_ESTUDIANTE"                        <AS cod_nuevo,
       CASE WHEN b."COD_ESTUDIANTE" IS NOT NULL
            THEN TRUE
            ELSE FALSE
       END                                        AS nuevo_estudiante
FROM   alumnos a
FULL JOIN nuevos_alumnos b ON a.cod_estudiante = b."COD_ESTUDIANTE"
ORDER  BY COALESCE(a.cod_estudiante, b."COD_ESTUDIANTE");


-- Conteo por tipo (equivalente al group_by().len() de Polars)
SELECT 
	CASE WHEN b."COD_ESTUDIANTE" IS NOT NULL 
	THEN TRUE 
	ELSE FALSE 
	END AS nuevo_estudiante,
    COUNT(*) AS total
FROM   alumnos a
FULL JOIN nuevos_alumnos b
       ON a.cod_estudiante = b."COD_ESTUDIANTE"
GROUP  BY nuevo_estudiante;


-- Bloque 2 - Tabla base para el ejercicio del viaje
--
-- Preparamos los datos para el bloque 3. Las condiciones para ir al viaje son:
-- - permiso_firmado = TRUE
-- - cuotas pagadas (normalizar con regex)
-- - tasa de asistencia > 80%
-- - nota media > 6.0

-- Ejercicio 2.1 - Inspeccionar la tabla viaje

SELECT * FROM viaje LIMIT  10;


-- Ejercicio 2.2 - Normalizar cuotas_pagadas con regex
--
-- Equivalente al ejercicio 2.2 de Polars: crear la columna booleana cuotas_ok.
-- En Polars usamos str.contains(r"(?i)^[sacp]"). En PostgreSQL usamos ~* para regex
-- insensible a mayúsculas.

-- Ver los valores únicos primero
SELECT cuotas_pagadas,
       COUNT(*) AS n
FROM   viaje
GROUP  BY cuotas_pagadas
ORDER  BY cuotas_pagadas;


SELECT cod_estudiante,
       cuotas_pagadas,
       cuotas_pagadas ~* '^[sacp]' AS cuotas_ok
FROM   viaje
ORDER  BY cuotas_ok, cuotas_pagadas;


-- Ejercicio 2.3 - Nota media por alumno
--
-- Equivalente al ejercicio 2.3 de Polars: group_by().agg() sobre notas.

SELECT cod_estudiante,
       ROUND(AVG(nota), 3) AS nota_media
FROM   notas
GROUP  BY cod_estudiante
ORDER  BY cod_estudiante;


-- Ejercicio 2.4 - Tabla base con CTEs
--
-- Equivalente al ejercicio 2.4 de Polars: unir viaje con la nota media por alumno.
-- Usamos CTEs (WITH) para construir la tabla base en un solo bloque legible,
-- evitando repetir cálculos.

WITH nota_media AS (
    SELECT cod_estudiante,
           ROUND(AVG(nota), 3) AS nota_media
    FROM   notas
    GROUP  BY cod_estudiante
)
SELECT v.cod_estudiante,
       v.permiso_firmado,
       v.cuotas_pagadas,
       v.cuotas_pagadas ~* '^[sacp]' AS cuotas_ok,
       nm.nota_media
FROM   viaje v
LEFT JOIN nota_media nm USING (cod_estudiante)
ORDER  BY cod_estudiante
LIMIT  8;


-- Bloque 3 - Cuatro caminos al mismo resultado
--
-- Pregunta: ¿Qué alumnos pueden ir al viaje?
--
-- Las condiciones son:
-- - permiso_firmado = TRUE
-- - cuotas_pagadas ~* '^[sacp]' (cuotas ok)
-- - tasa de asistencia > 0.80
-- - nota_media > 6.0
--
-- Los cuatro caminos producen el mismo resultado. Al final verificamos que coinciden.

-- Camino A - INNER JOIN
--
-- Lógica: construimos primero la tabla de los que cumplen asistencia y hacemos
-- un INNER JOIN para quedarnos solo con los que aparecen en ambas tablas.

WITH dias_largo AS (
    SELECT cod_estudiante,
           nombre,
           valor
    FROM   asistencia a
    CROSS JOIN LATERAL (
        VALUES
            (a_19950501), (a_19950502), (a_19950503),
            (a_19950504), (a_19950505), (a_19950508),
            (a_19950509), (a_19950510), (a_19950511),
            (a_19950512), (a_19950515), (a_19950516),
            (a_19950517), (a_19950518), (a_19950519),
            (a_19950522), (a_19950523), (a_19950524),
            (a_19950525), (a_19950526), (a_19950529),
            (a_19950530), (a_19950531)
    ) AS dias(valor)
),
asistencia_calc AS (
    SELECT cod_estudiante,
           nombre,
           ROUND(AVG((valor = 'X')::int), 3) AS tasa_asistencia
    FROM   dias_largo
    GROUP  BY cod_estudiante, nombre
),
asistencia_cumple AS (
    SELECT cod_estudiante
    FROM   asistencia_calc
    WHERE  tasa_asistencia > 0.80
),
nota_media AS (
    SELECT cod_estudiante,
           ROUND(AVG(nota), 3) AS nota_media
    FROM   notas
    GROUP  BY cod_estudiante
)
SELECT v.cod_estudiante,
       v.permiso_firmado,
       nm.nota_media
FROM   viaje v
INNER JOIN nota_media nm USING (cod_estudiante)
INNER JOIN asistencia_cumple   USING (cod_estudiante)
WHERE  v.permiso_firmado = TRUE
  AND  v.cuotas_pagadas ~* '^[sacp]'
  AND  nm.nota_media > 6.0
ORDER  BY v.cod_estudiante;


-- Camino B - NOT EXISTS (anti join)
--
-- Lógica: identificamos los que no cumplen asistencia y los excluimos con NOT EXISTS.
-- Equivalente al how="anti" de Polars.

WITH dias_largo AS (
    SELECT cod_estudiante,
           nombre,
           valor
    FROM   asistencia a
    CROSS JOIN LATERAL (
        VALUES
            (a_19950501), (a_19950502), (a_19950503),
            (a_19950504), (a_19950505), (a_19950508),
            (a_19950509), (a_19950510), (a_19950511),
            (a_19950512), (a_19950515), (a_19950516),
            (a_19950517), (a_19950518), (a_19950519),
            (a_19950522), (a_19950523), (a_19950524),
            (a_19950525), (a_19950526), (a_19950529),
            (a_19950530), (a_19950531)
    ) AS dias(valor)
),
asistencia_calc AS (
    SELECT cod_estudiante,
           nombre,
           ROUND(AVG((valor = 'X')::int), 3) AS tasa_asistencia
    FROM   dias_largo
    GROUP  BY cod_estudiante, nombre
),
asistencia_no_cumple AS (
    SELECT cod_estudiante
    FROM   asistencia_calc
    WHERE  tasa_asistencia <= 0.80
),
nota_media AS (
    SELECT cod_estudiante,
           ROUND(AVG(nota), 3) AS nota_media
    FROM   notas
    GROUP  BY cod_estudiante
)
SELECT v.cod_estudiante,
       v.permiso_firmado,
       nm.nota_media
FROM   viaje v
LEFT JOIN nota_media nm USING (cod_estudiante)
WHERE  v.permiso_firmado = TRUE
  AND  v.cuotas_pagadas ~* '^[sacp]'
  AND  nm.nota_media > 6.0
  AND  NOT EXISTS (
           SELECT 1 FROM asistencia_no_cumple anc 
           WHERE  anc.cod_estudiante = v.cod_estudiante
       )
ORDER  BY v.cod_estudiante;


-- Camino C - LEFT JOIN con filtro al final
--
-- Lógica: traemos la tasa de asistencia con un LEFT JOIN y aplicamos todas
-- las condiciones juntas en el WHERE.

WITH dias_largo AS (
    SELECT cod_estudiante,
           nombre,
           valor
    FROM   asistencia a
    CROSS JOIN LATERAL (
        VALUES
            (a_19950501), (a_19950502), (a_19950503),
            (a_19950504), (a_19950505), (a_19950508),
            (a_19950509), (a_19950510), (a_19950511),
            (a_19950512), (a_19950515), (a_19950516),
            (a_19950517), (a_19950518), (a_19950519),
            (a_19950522), (a_19950523), (a_19950524),
            (a_19950525), (a_19950526), (a_19950529),
            (a_19950530), (a_19950531)
    ) AS dias(valor)
),
asistencia_calc AS (
    SELECT cod_estudiante,
           nombre,
           ROUND(AVG((valor = 'X')::int), 3) AS tasa_asistencia
    FROM   dias_largo
    GROUP  BY cod_estudiante, nombre
),
nota_media AS (
    SELECT cod_estudiante,
           ROUND(AVG(nota), 3) AS nota_media
    FROM   notas
    GROUP  BY cod_estudiante
)
SELECT v.cod_estudiante,
       v.permiso_firmado,
       nm.nota_media,
       ac.tasa_asistencia
FROM   viaje v
LEFT JOIN nota_media      nm USING (cod_estudiante)
LEFT JOIN asistencia_calc ac USING (cod_estudiante)
WHERE  v.permiso_firmado = TRUE
  AND  v.cuotas_pagadas ~* '^[sacp]'
  AND  nm.nota_media > 6.0
  AND  ac.tasa_asistencia > 0.80
ORDER  BY v.cod_estudiante;


-- Camino D - EXISTS (semi join)
--
-- Lógica: filtramos los que cumplen asistencia y usamos EXISTS para incluir
-- solo los que aparecen en esa lista. Equivalente al how="semi" de Polars.

WITH dias_largo AS (
    SELECT cod_estudiante,
           nombre,
           valor
    FROM   asistencia a
    CROSS JOIN LATERAL (
        VALUES
            (a_19950501), (a_19950502), (a_19950503),
            (a_19950504), (a_19950505), (a_19950508),
            (a_19950509), (a_19950510), (a_19950511),
            (a_19950512), (a_19950515), (a_19950516),
            (a_19950517), (a_19950518), (a_19950519),
            (a_19950522), (a_19950523), (a_19950524),
            (a_19950525), (a_19950526), (a_19950529),
            (a_19950530), (a_19950531)
    ) AS dias(valor)
),
asistencia_calc AS (
    SELECT cod_estudiante,
           nombre,
           ROUND(AVG((valor = 'X')::int), 3) AS tasa_asistencia
    FROM   dias_largo
    GROUP  BY cod_estudiante, nombre
),
nota_media AS (
    SELECT cod_estudiante,
           ROUND(AVG(nota), 3) AS nota_media
    FROM   notas
    GROUP  BY cod_estudiante
)
SELECT v.cod_estudiante,
       v.permiso_firmado,
       nm.nota_media
FROM   viaje v
LEFT JOIN nota_media nm USING (cod_estudiante)
WHERE  v.permiso_firmado = TRUE
  AND  v.cuotas_pagadas ~* '^[sacp]'
  AND  nm.nota_media > 6.0
  AND  EXISTS (
           SELECT 1
           FROM   asistencia_calc ac
           WHERE  ac.cod_estudiante  = v.cod_estudiante
             AND  ac.tasa_asistencia > 0.80
       )
ORDER  BY v.cod_estudiante;


-- Ejercicio final - Window functions: z-score por materia
--
-- Equivalente al último bloque de Polars: calcular el z-score de cada nota
-- respecto a la media y desviación de su materia.
--
-- En Polars: .over("materia"). En SQL: OVER (PARTITION BY materia).

-- Paso intermedio: ver media y desviación por materia
SELECT materia,
       ROUND(AVG(nota), 2)    AS media_materia,
       ROUND(STDDEV(nota), 2) AS std_materia
FROM   notas
WHERE  nota IS NOT NULL
GROUP  BY materia
ORDER  BY materia;


-- Z-score con OVER (PARTITION BY): sin reducir filas
SELECT nombre,
       materia,
       nota,
       ROUND(AVG(nota)    OVER (PARTITION BY materia), 2) AS media_materia,
       ROUND(STDDEV(nota) OVER (PARTITION BY materia), 2) AS std_materia,
       ROUND((nota - AVG(nota) OVER (PARTITION BY materia)) /
           		NULLIF(STDDEV(nota) OVER (PARTITION BY materia), 0), 2) AS z_score
FROM   notas
WHERE  nota IS NOT NULL
ORDER  BY materia, z_score DESC;


-- Ranking de notas dentro de cada materia con ROW_NUMBER y DENSE_RANK
SELECT nombre,
       materia,
       nota,
       ROW_NUMBER()  OVER (PARTITION BY materia ORDER BY nota DESC) AS fila,
       RANK()  OVER (PARTITION BY materia ORDER BY nota DESC) AS ranking,
       DENSE_RANK()  OVER (PARTITION BY materia ORDER BY nota DESC) AS ranking_denso
FROM   notas
WHERE  nota IS NOT NULL
ORDER  BY materia, ranking;

