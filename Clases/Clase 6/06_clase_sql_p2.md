---
marp: true
theme: flacso
paginate: true
---

<!-- _class: portada -->

<img src="../estilos/logo_flacso.png" class="logo" />

<div class="tag">Sesión 6: SQL — DDL y DML</div>

# Crear, modificar y poblar tablas

<p>Fausto Jácome Pérez<br>FLACSO Ecuador</p>

<div class="pregunta">
Ya sabemos consultar datos. ¿Cómo creamos las estructuras que los contienen y cómo los modificamos?
</div>

---

## ¿Dónde estamos?

<div class="cols3">
  <div class="card">
    <div class="num">3-4</div>
    <div class="lbl">Sesiones anteriores</div>
    <br>
    ETL con Polars: ingesta, limpieza, joins, reshaping, agrupaciones y window functions sobre archivos locales.
  </div>
  <div class="card">
    <div class="num">5</div>
    <div class="lbl">Sesión anterior</div>
    <br>
    SQL de lectura: SELECT, WHERE, JOIN, GROUP BY, HAVING y window functions sobre PostgreSQL. Solo lectura sobre <code>public</code>.
  </div>
  <div class="card" style="border-left-color:var(--accent)">
    <div class="num">6</div>
    <div class="lbl">Esta sesión</div>
    <br>
    DDL: crear, modificar y eliminar tablas. DML: insertar, actualizar y borrar filas. Cada quien en su propio schema.
  </div>
</div>

<div class="box">
Las tablas son las mismas del registro escolar ficticio. Ahora cada alumno tiene un schema personal con permisos completos de escritura.
</div>

---

## Las familias de comandos SQL

![](tipos_operaciones.png)


<div class="box warn">
En la sesión 5 trabajamos solo con DQL. Hoy agregamos DDL y DML. DCL y TCL los veremos de forma aplicada al final.
</div>

---

<!-- _class: seccion -->

## Schemas y permisos

<p>Por qué cada quien tiene su propio espacio de trabajo</p>

---

## Schemas: espacios de nombres en PostgreSQL

Un schema es un contenedor de objetos dentro de una base de datos. Permite que distintos usuarios tengan tablas con el mismo nombre sin conflicto.

<div class="cols">
<div>

**Schema `public`**

- Compartido por todos
- Solo lectura para los alumnos
- Contiene las tablas de referencia: `alumnos`, `notas`, `viaje`, etc.

</div>
<div>

**Schema personal `<tu_esquema>`**

- Exclusivo de cada alumno
- Permisos completos: `CREATE`, `INSERT`, `UPDATE`, `DELETE`
- Aislado del resto: lo que creas aquí no afecta a nadie más

</div>
</div>

<div class="box warn">
Intentar escribir sobre <code>public</code> produce un error de permisos. El ejercicio 0 lo comprueba directamente.
</div>

---

## SET search_path

Sin `search_path` hay que calificar cada nombre de tabla con el schema:

```sql
SELECT * FROM <tu_esquema>.alumnos;
ALTER TABLE <tu_esquema>.alumnos ADD COLUMN email TEXT;
```

Con `SET search_path` el motor busca primero en el schema indicado:

```sql
SET search_path TO <tu_esquema>;

-- A partir de aquí solo el nombre de la tabla
SELECT * FROM alumnos;
ALTER TABLE alumnos ADD COLUMN email TEXT;
```

<div class="box">
<code>SET search_path</code> aplica solo a la sesión activa. Al reconectar hay que ejecutarlo de nuevo. En Colab se hace con <code>sql(f"SET search_path TO {TU_ESQUEMA};")</code> justo después de conectar.
</div>

---

<!-- _class: seccion -->

## DDL: definir estructuras

<p>CREATE TABLE, ALTER TABLE, DROP TABLE</p>

---

## Llaves primarias y foráneas

Antes de crear tablas, dos conceptos que gobiernan la integridad relacional:

<div class="cols">
<div>

**Llave primaria (PRIMARY KEY)**

- Identifica de forma única cada fila
- No puede ser `NULL` ni duplicada
- Una tabla tiene como máximo una PK
- Puede ser una columna o una combinación

```sql
cod_estudiante INTEGER PRIMARY KEY
```

</div>
<div>

**Llave foránea (FOREIGN KEY)**

- Referencia la PK de otra tabla
- Garantiza que el valor exista en la tabla referenciada
- Puede ser `NULL` (relación opcional)
- Una tabla puede tener múltiples FK

```sql
cod_estudiante INTEGER
    REFERENCES alumnos (cod_estudiante)
```

</div>
</div>

<div class="box warn">
Sin estas restricciones es posible registrar notas de alumnos que no existen, o tener dos alumnos con el mismo código. La base de datos no puede detectarlo.
</div>

---

## CREATE TABLE

```sql
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
```

<div class="box">
Las restricciones se evalúan en cada <code>INSERT</code> y <code>UPDATE</code>. Si alguna se viola, la operación falla y la fila no se modifica.
</div>

---

## Restricciones (constraints)

| Restricción | ¿Qué garantiza? |
|---|---|
| `PRIMARY KEY` | Unicidad y no nulo en la columna llave |
| `NOT NULL` | La columna no puede quedar vacía |
| `CHECK (condición)` | El valor cumple una expresión lógica |
| `REFERENCES tabla (col)` | El valor existe como PK en otra tabla |
| `UNIQUE` | No hay duplicados en la columna |

<div class="box warn">
<strong>El caso de <code>viaje.cuotas_pagadas</code>:</strong> esa columna no tiene <code>CHECK</code>, por eso encontramos <code>'si'</code>, <code>'SI'</code>, <code>'Sí'</code>, <code>'pagado'</code> para el mismo concepto. Un <code>CHECK (cuotas_pagadas IN ('si', 'no', 'parcial'))</code> al crear la tabla hubiera forzado consistencia desde el origen.
</div>

---

## Restricciones nombradas

Las restricciones pueden definirse al final de la tabla con nombre explícito:

```sql
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
```

<div class="box">
El nombre autogenerado se usa en la versión en la que no nombramos la restricción (ver dos diapositivas antes).
</div>

---

## FOREIGN KEY y ON DELETE CASCADE

```sql
CREATE TABLE notas (
    cod_estudiante  INTEGER         NOT NULL REFERENCES alumnos (cod_estudiante) ON DELETE CASCADE,
    nombre          TEXT,
    materia         TEXT            NOT NULL,
    nota            NUMERIC         CHECK (nota >= 0 AND nota <= 10)
);
```

`ON DELETE CASCADE` define qué pasa con las filas hijas cuando se borra una fila padre:

| Opción | Comportamiento |
|---|---|
| `CASCADE` | Borra las filas hijas automáticamente |
| `SET NULL` | Pone `NULL` en la FK de las hijas |
| `RESTRICT` | Impide borrar si hay hijas (default) |
| `NO ACTION` | Similar a `RESTRICT`, evaluado al final |

---

## ALTER TABLE

Modificar una tabla existente sin recrearla:

```sql
-- Agregar una columna
ALTER TABLE alumnos ADD COLUMN email TEXT;

-- Eliminar una columna
ALTER TABLE alumnos DROP COLUMN email;

-- Renombrar una columna
ALTER TABLE alumnos RENAME COLUMN anio_nac TO year_nac;

-- Renombrar la tabla
ALTER TABLE notas_123 RENAME TO notas;

-- Cambiar el tipo de una columna
ALTER TABLE alumnos ALTER COLUMN altura TYPE FLOAT;
```

---

## DROP TABLE

```sql
-- Eliminar una tabla
DROP TABLE notas;

-- IF EXISTS evita error si la tabla no existe
DROP TABLE IF EXISTS notas;

-- CASCADE elimina también los objetos que dependen de ella
-- (vistas, restricciones de otras tablas que la referencian)
DROP TABLE IF EXISTS alumnos CASCADE;
```

<div class="box warn">
<code>DROP TABLE</code> elimina la estructura <strong>y todos los datos</strong>. No hay deshacer. En producción siempre verificar dos veces antes de ejecutarlo.
</div>


---

<!-- _class: seccion -->

## DML: modificar datos

<p>INSERT, UPDATE, DELETE, TRUNCATE</p>

---

## INSERT

```sql
-- Fila a fila: especificar columnas explícitamente
INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,altura, paralelo, anio_nac, mes_nac, dia_nac)
VALUES (1, 'Ana Torres', 'f', 28, 'Ecuador', 'Quito', 165, 'A', 1996, 3, 12);

-- Insertar desde otra tabla con SELECT
INSERT INTO alumnos (cod_estudiante, nombre, sexo, edad, pais, ciudad,altura, paralelo, anio_nac, mes_nac, dia_nac)
    SELECT cod_estudiante, nombre, sexo, edad, pais, ciudad,altura, paralelo, anio_nac, mes_nac, dia_nac
    FROM   public.alumnos;
```

<div class="box">
Siempre listar las columnas explícitamente en el <code>INSERT</code>. Sin lista de columnas, PostgreSQL asigna los valores por posición: si la tabla cambia de estructura con un <code>ALTER TABLE</code>, los valores pueden quedar en las columnas equivocadas sin ningún error.

</div>

---

## UPDATE

```sql
-- Con WHERE: afecta solo las filas que cumplen la condición
UPDATE alumnos
SET    ciudad = 'Cuenca'
WHERE  cod_estudiante = 1;

-- Actualizar múltiples columnas a la vez
UPDATE alumnos
SET    ciudad   = 'Cuenca',
       paralelo = 'B'
WHERE  cod_estudiante = 1;
```

<div class="box warn">
Un <code>UPDATE</code> sin <code>WHERE</code> actualiza <strong>todas las filas</strong> de la tabla. Siempre verificar con un <code>SELECT</code> previo que el <code>WHERE</code> selecciona las filas correctas.
</div>

```sql
-- Patrón seguro: verificar antes de actualizar
SELECT * FROM alumnos WHERE cod_estudiante = 1;
-- Si el resultado es el esperado, ejecutar el UPDATE
```

---

## DELETE y TRUNCATE

```sql
-- DELETE con WHERE: elimina filas específicas
DELETE FROM alumnos WHERE cod_estudiante = 500;

-- DELETE sin WHERE: elimina TODAS las filas (con log fila a fila)

-- TRUNCATE: vacía la tabla entera de forma rápida
-- No genera log por fila, no se puede usar con WHERE
TRUNCATE TABLE alumnos;

-- CASCADE necesario si hay FK apuntando a la tabla
TRUNCATE TABLE alumnos CASCADE;
```
<br>

| | `DELETE` | `TRUNCATE` |
|---|---|---|
| Familia | DML | DDL |
| `WHERE` | Sí | No |
| Velocidad en tablas grandes | Lenta | Rápida |
| Se puede revertir con `ROLLBACK` | Sí | En Postgres sí|

---

## Transacciones: BEGIN, COMMIT, ROLLBACK

Las transacciones agrupan operaciones en una unidad atómica: o todas se confirman o ninguna.

```sql
-- Abrir una transacción explícita
BEGIN;

-- Operación riesgosa
UPDATE alumnos SET paralelo = 'Z';

-- Ver el efecto antes de confirmar
SELECT cod_estudiante, nombre, paralelo FROM alumnos;

-- Si el resultado es correcto: confirmar
COMMIT;

-- Si algo está mal: deshacer todo
ROLLBACK;
```

<div class="box">
Mientras no se ejecute <code>COMMIT</code>, los cambios son visibles solo en la sesión activa. <code>ROLLBACK</code> los deshace completamente como si nunca hubieran ocurrido.
</div>

---

## Integridad referencial en acción

Con `ON DELETE CASCADE`, borrar un alumno elimina automáticamente sus notas:

```sql
-- Notas del alumno 1 antes de borrarlo
SELECT * FROM notas WHERE cod_estudiante = 1;
-- resultado: 2 filas (matematicas y castellano)

-- Borrar el alumno
DELETE FROM alumnos WHERE cod_estudiante = 1;

-- Las notas desaparecieron automáticamente
SELECT * FROM notas WHERE cod_estudiante = 1;
-- resultado: 0 filas
```

<div class="box warn">
Sin <code>CASCADE</code>, el <code>DELETE</code> sobre <code>alumnos</code> fallaría con un error de integridad referencial si existen notas asociadas. La base protege la consistencia.
</div>

---

<!-- _class: cierre -->

## ¿Qué aprendimos hoy?

<div class="cols">
<div>

**Conceptos**

- Schemas como espacios de nombres y permisos
- `SET search_path` para simplificar las consultas
- Llave primaria y llave foránea
- Restricciones: `NOT NULL`, `CHECK`, `REFERENCES`, `UNIQUE`
- Restricciones nombradas para mensajes de error legibles
- `ON DELETE CASCADE`, `SET NULL`, `RESTRICT`
- Transacciones: `BEGIN`, `COMMIT`, `ROLLBACK`

</div>
<div>

**En SQL / PostgreSQL**

- `CREATE TABLE` con constraints
- `ALTER TABLE`: `ADD COLUMN`, `DROP COLUMN`, `RENAME`
- `DROP TABLE IF EXISTS`
- `INSERT` fila a fila e `INSERT ... SELECT`
- `UPDATE` con y sin `WHERE`
- `DELETE` con y sin `WHERE`
- `TRUNCATE TABLE ... CASCADE`
- Integridad referencial en acción con `CASCADE`

</div>
</div>

---

## Extra: ya entienden los memes de SQL

<div class="cols">
<div>


![alt text](update_sin_where-1.jpg)

</div>
<div>

![w:350](delet_sin_where1.png)
![w:350](delet_sin_where2.png)

</div>
</div>


