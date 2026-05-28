---
marp: true
theme: flacso
paginate: true
---

<!-- _class: portada -->

<img src="../estilos/logo_flacso.png" class="logo" />

<div class="tag">Sesión 3: ETL con Polars</div>

# ETL con Polars: de la ingesta al análisis

<p>Fausto Jácome Pérez<br>FLACSO Ecuador</p>

<div class="pregunta">
Tenemos cinco tablas dispersas. ¿Cómo las cargamos, limpiamos, combinamos y resumimos para responder una pregunta?
</div>

---

## ¿Dónde estamos?

<div class="cols3">
  <div class="card">
    <div class="num">2</div>
    <div class="lbl">Sesión anterior</div>
    <br>
    Corregimos tipos con <code>cast</code>. Recodificamos con <code>pl.when()</code>. Filtramos y seleccionamos columnas. Hicimos el primer join entre personas y hogar.
  </div>
  <div class="card" style="border-left-color:var(--accent)">
    <div class="num">3</div>
    <div class="lbl">Esta sesión</div>
    <br>
    ETL completo: ingesta desde CSV, Excel y R. Transformaciones con <code>with_columns</code>. Reshaping. Joins múltiples. Agregaciones y window functions.
  </div>
  <div class="card">
    <div class="num">4</div>
    <div class="lbl">Próxima sesión</div>
    <br>
    SQL: las mismas operaciones en otro lenguaje, y por qué conviene conocer los dos.
  </div>
</div>

<div class="box">
El caso de hoy: un registro escolar ficticio con cinco tablas. Al final tendremos una tabla analítica que liga notas, alumnos, profesores y paralelos.
</div>

---

<!-- _class: seccion -->

## Ingesta de datos

<p>Leer desde CSV, Excel y archivos de R</p>

---

## Cargar desde CSV y Excel

<div class="cols">
<div>

**Desde CSV**

```python
import polars as pl

alumnos = pl.read_csv("datos/alumnos.csv")

# Especificar tipos al leer
alumnos = pl.read_csv(
    "datos/alumnos.csv",
    schema_overrides={
        "cod_estudiante": pl.String
    },
)
```

</div>
<div>

**Desde Excel**

```python
# Hoja por nombre
notas = pl.read_excel(
    "datos/escuela.xlsx",
    sheet_name="notas",
)

# Primera hoja (por defecto)
df = pl.read_excel("datos/escuela.xlsx")
```

</div>
</div>

<div class="box">
<code>pl.read_csv()</code> infiere tipos columna por columna. Si una columna mezcla números y texto, la infiere como <code>String</code>. Siempre verificar el schema con <code>.schema</code> después de cargar.
</div>


---

## Cargar desde R

```python
import polars as pl
import pyreadr

# .rds: un solo objeto R
resultado = pyreadr.read_r("datos/f1_personas.rds")
df = pl.from_pandas(resultado[None])

# .RData: puede contener varios objetos; se accede por nombre
resultado = pyreadr.read_r("datos/endi.RData")
df_personas = pl.from_pandas(resultado["f1_personas"])
df_hogar    = pl.from_pandas(resultado["f1_hogar"])
```

<div class="box">
<code>pyreadr</code> convierte el archivo R a un DataFrame de pandas; <code>pl.from_pandas()</code> lo traduce a Polars. 
</div>


---

<!-- _class: seccion -->

## Operaciones básicas

<p>select, drop, rename, inspección y ordenamiento</p>

---

## `.select()` y `.drop()`

<div class="cols">
<div>

**Quedarse con columnas específicas**

```python
df = alumnos.select([
    "cod_estudiante",
    "nombre",
    "ciudad",
    "paralelo",
])
```

Devuelve un DataFrame nuevo solo con esas cuatro columnas. Las demás desaparecen.

</div>
<div>

**Descartar columnas específicas**

```python
df = alumnos.drop([
    "anio_nac",
    "mes_nac",
    "dia_nac",
])
```

Devuelve todas las columnas excepto las listadas. Útil cuando hay muchas columnas y solo se quieren eliminar unas pocas.

</div>
</div>

---

## `.rename()`

Cambia el nombre de una o más columnas usando un diccionario. Las columnas no listadas conservan su nombre original.

```python
df = alumnos.rename({
    "cod_estudiante": "id",
    "altura":        "altura_cm",
    "nombre":        "alumno",
})
```

<div class="box">
<code>.rename()</code> no reordena columnas ni cambia su contenido. Es una operación de etiquetas puras: solo afecta los nombres.
</div>

<div class="box warn">
El diccionario va en el sentido <code>"nombre_viejo": "nombre_nuevo"</code>. Si se invierte el orden, Polars lanza un error cuando el nombre viejo no existe en el DataFrame.
</div>

---

## `.head()`, `.slice()` y `.tail()`

Herramientas de inspección rápida para ver una porción del DataFrame:

```python
alumnos.head(3)     # primeras 3 filas

alumnos.tail(3)     # últimas 3 filas

# slice(offset, length): desde la posición 4, tomar 3 filas
alumnos.slice(4, 3)
```

<div class="box">
<code>.head(n)</code> es equivalente a <code>.slice(0, n)</code>. El índice de <code>.slice()</code> empieza en 0: <code>.slice(4, 3)</code> devuelve las filas 4, 5 y 6.
</div>


---

## `.sort()`

```python
# Ascendente (por defecto)
alumnos.sort("edad")

# Descendente
alumnos.sort("edad", descending=True)

# Múltiples columnas: primero por paralelo, luego por nombre dentro de cada paralelo
alumnos.sort(["paralelo", "nombre"])

# Nulls al final en lugar de al inicio (comportamiento por defecto)
notas.sort("nota", nulls_last=True)
```

<div class="box warn">
Polars coloca los valores <code>null</code> al inicio por defecto al ordenar de forma ascendente. 
</div>



---

<!-- _class: seccion -->

## `with_columns`

<p>Añadir y transformar columnas sin reemplazar el DataFrame</p>

---

## Concepto: `with_columns`

`.with_columns()` recibe una lista de expresiones y **agrega** columnas al DataFrame. Si el alias coincide con una columna existente, la reemplaza en ese lugar. El DataFrame original no se modifica.

```python
# Agregar una columna nueva: el resultado tiene todas las columnas originales + edad_meses
df = alumnos.with_columns([
    (pl.col("edad") * 12).alias("edad_meses"),
])

# Reemplazar una columna existente: mismas columnas, pero edad ahora es Int16
df = alumnos.with_columns([
    pl.col("edad").cast(pl.Int16).alias("edad"),
])

# Varias columnas en un solo llamado: más eficiente que encadenar varios with_columns
df = alumnos.with_columns([
    (pl.col("edad") * 12).alias("edad_meses"),
    pl.col("sexo").cast(pl.Categorical).alias("sexo"),
])
```

---

## `with_columns` + `cast`

Cambiar el tipo de una o más columnas en un solo paso:

```python
df = alumnos.with_columns([
    pl.col("cod_estudiante").cast(pl.String),
    pl.col("sexo").cast(pl.Categorical),
    pl.col("edad").cast(pl.Int16),
    pl.col("altura").cast(pl.Float32),
])
```

<div class="box warn">
Por defecto, <code>cast</code> falla en silencio si el valor no cabe en el tipo destino y devuelve <code>null</code>. Para detectar errores, usar <code>strict=True</code>:

```python
pl.col("edad").cast(pl.Int8, strict=True)  # lanza error si hay overflow
```
</div>

---

## `with_columns` + operaciones de cadenas

El namespace `.str` contiene todas las operaciones sobre texto. Estas mismas operaciones se aplican antes del join para normalizar la columna `materia`:

```python
df = alumnos.with_columns([
    # Quitar espacios al inicio y al final
    pl.col("nombre").str.strip_chars().alias("nombre"),
    # Reemplazar guión por espacio en nombres compuestos (San-Jose -> San Jose)
    pl.col("nombre").str.replace_all("-", " ").alias("nombre"),
    # Pasar a mayúsculas
    pl.col("ciudad").str.to_uppercase().alias("ciudad"),
    # Eliminar tildes para normalizar texto antes de joins
    pl.col("nombre")
      .str.replace_all("á", "a")
      .str.replace_all("é", "e")
      .str.replace_all("í", "i")
      .str.replace_all("ó", "o")
      .str.replace_all("ú", "u")
      .alias("nombre_norm"),
])
```

---

## `with_columns` + variables temporales

Los datos de nacimiento llegan en tres columnas separadas. `pl.date()` las combina en una fecha real que admite aritmética temporal:

```python
df = alumnos.with_columns(
    pl.date(pl.col("anio_nac"),pl.col("mes_nac"),pl.col("dia_nac"),).alias("fecha_nac")
)

# Extraer componentes o calcular diferencias
df = df.with_columns([
    pl.col("fecha_nac").dt.year().alias("anio_nac_check"),
    pl.col("fecha_nac").dt.weekday().alias("dia_semana_nac"),
    (pl.date(2026, 1, 1) - pl.col("fecha_nac"))
      .dt.total_days()
      .alias("edad_dias"),
])
```

<div class="box">
<code>pl.date()</code> acepta expresiones de columna como argumentos. El resultado es de tipo <code>Date</code>, que permite restar fechas directamente y obtener una duración en días con <code>.dt.total_days()</code>.
</div>



---

## `with_columns` + variables numéricas

Transformaciones aritméticas directas.
```python
df = alumnos.with_columns([
    # Convertir altura de centímetros a metros
    (pl.col("altura") / 100)
      .round(2)
      .alias("altura_m"),

    # Estandarizar manualmente: (valor - media) / desviación estándar
    (
        (pl.col("altura") - pl.col("altura").mean()) /
         pl.col("altura").std()
    ).round(2).alias("altura_z"),
])
```

<div class="box">
Dentro de <code>with_columns</code>, <code>.mean()</code> y <code>.std()</code> calculan el escalar para toda la columna y lo asignan a cada fila. En la próxima sección veremos cómo calcular esas medidas por grupo con <code>.over()</code>.
</div>


---

<!-- _class: seccion -->

## Reshaping

<p>Cambiar la forma de la tabla: wide y long</p>

---

## Pivot wide: de long a wide

La tabla `notas` tiene una fila por alumno por materia (formato **long**). `.pivot()` la convierte a **wide** para tener una columna por materia:

```python
notas_wide = notas.pivot(
    on="materia",                         # columna cuyos valores se vuelven encabezados
    index=["cod_estudiante", "nombre"],   # columnas que identifican cada fila
    values="nota",                        # columna que rellena las celdas
    aggregate_function="first",
)
```
<br> <br/>


| cod_estudiante | nombre | CASTELLANO | EDUCACION FISICA | MATEMATICAS | TEATRO |
|---|---|---|---|---|---|
| 1 | Raul Martos | 0.0 | 10.0 | 3.73 | 1.86 |
| 2 | Lazaro Herrera | 6.89 | 9.47 | 0.38 | 10.0 |

---

## Pivot long: de wide a long

La tabla `asistencia` tiene una columna por día (formato **wide**). `.unpivot()` la convierte a **long** para tener una fila por alumno por día:

```python

asist_long = asistencia.unpivot(
    on=pl.selectors.starts_with("a_"), # columnas que se convierten en filas
    index=["cod_estudiante", "nombre"], # columnas que se repiten en cada fila
    variable_name="fecha",
    value_name="asistio",
)
```

El resultado pasa de **20 filas x 23 columnas** a **460 filas x 4 columnas**: una fila por alumno por día.

<div class="box warn">
En formato wide, filtrar "todos los días en que asistió Andreea" requeriría 23 condiciones. En formato long basta con <code>.filter(pl.col("nombre") == "Andreea Centeno")</code>.
</div>


---

<!-- _class: seccion -->

## Joins

<p>Combinar tablas por claves comunes</p>

---

## Tipos de join

| Tipo | ¿Qué conserva? | Cuándo usarlo |
|---|---|---|
| `left` | Todas las filas de la tabla izquierda | Agregar columnas sin perder filas base |
| `inner` | Solo filas con coincidencia en ambas tablas | Subconjunto garantizado en las dos tablas |
| `full` | Todas las filas de ambas tablas | Diagnóstico: ver qué falta en cada lado |
| `semi` | Filas izquierda con coincidencia, sin columnas nuevas | Filtrar por existencia en otra tabla |
| `anti` | Filas izquierda sin coincidencia | Encontrar registros sin pareja |

<div class="box warn">
Antes de cualquier join: verificar que la llave no tiene duplicados en la tabla derecha. Un duplicado convierte un left join en una multiplicación silenciosa de filas.
</div>

---

## Las cinco tablas del registro escolar

<div class="er">
  <div class="er-table">
    <div class="er-head">notas</div>
    <div class="er-row pk">cod_estudiante</div>
    <div class="er-row pk">materia</div>
    <div class="er-row">nombre</div>
    <div class="er-row">nota</div>
  </div>
  <div class="er-arrow">→</div>
  <div class="er-table">
    <div class="er-head">alumnos</div>
    <div class="er-row pk">cod_estudiante</div>
    <div class="er-row">nombre</div>
    <div class="er-row fk">paralelo</div>
    <div class="er-row">ciudad, altura...</div>
  </div>
  <div class="er-arrow">→</div>
  <div class="er-table">
    <div class="er-head">asigna_clase</div>
    <div class="er-row fk">cod_profesor</div>
    <div class="er-row pk">paralelo</div>
  </div>
  <div class="er-arrow">→</div>
  <div class="er-table">
    <div class="er-head">profesores</div>
    <div class="er-row pk">cod_profesor</div>
    <div class="er-row">nombre</div>
    <div class="er-row fk">materia</div>
  </div>
  <div class="er-arrow">+</div>
  <div class="er-table">
    <div class="er-head">asistencia</div>
    <div class="er-row fk">cod_estudiante</div>
    <div class="er-row">nombre</div>
    <div class="er-row">a_19950501...</div>
  </div>
</div>

<div class="box warn">
Hay un problema de consistencia: en <code>notas</code> las materias están en mayúsculas sin tildes (<code>MATEMATICAS</code>); en <code>profesores</code> están en minúsculas con tildes (<code>matemáticas</code>). Un join directo no encontraría ninguna coincidencia. Hay que normalizar primero.
</div>

---

## Normalizar antes del join

Definimos una función reutilizable que aplica todas las transformaciones de texto necesarias:

```python
def normalizar_materia(expr: pl.Expr) -> pl.Expr:
    return (
        expr.str.to_lowercase()
            .str.strip_chars()
            .str.replace_all("á", "a")
            .str.replace_all("é", "e")
            .str.replace_all("í", "i")
            .str.replace_all("ó", "o")
            .str.replace_all("ú", "u")
    )

notas_norm = notas.with_columns(
    normalizar_materia(pl.col("materia")).alias("materia")
)
prof_norm = profesores.with_columns(
    normalizar_materia(pl.col("materia")).alias("materia")
)
# Ahora "MATEMATICAS" y "matemáticas" quedan ambas como "matematicas"
```

---

## Join de cuatro tablas

```python
# Tabla auxiliar: qué profesor enseña cada materia en cada paralelo
prof_paralelo = (
    asigna_clase
    .join(prof_norm, on="cod_profesor", how="left")
    .rename({"nombre": "nombre_profesor"})
    .select(["paralelo", "materia", "nombre_profesor"])
)

# Join encadenado: notas -> alumnos -> prof_paralelo
resultado = (
    notas_norm
    .join(
        alumnos.select(["cod_estudiante", "paralelo"]),
        on="cod_estudiante",
        how="left",
    )
    .join(
        prof_paralelo,
        on=["paralelo", "materia"],
        how="left",
    )
)
```


---

<!-- _class: seccion -->

## Agrupaciones

<p>group_by y agg para resumir por grupos</p>

---

## `group_by` por profesor

Promedio de notas que asignó cada profesor en sus materias y paralelos:

```python
por_profesor = (
    resultado
    .group_by("nombre_profesor")
    .agg([
        pl.col("nota").mean().alias("promedio"),
        pl.col("nota").count().alias("n_notas"),
    ])
    .sort("promedio", descending=True)
)
```

<div class="box">
<code>pl.col("nota").count()</code> cuenta solo valores no nulos. <code>pl.len()</code> contaría todas las filas del grupo, incluyendo los nulls. En este caso la diferencia importa porque dos alumnos no tienen calificación en ninguna materia.
</div>


---

## `group_by` por alumno

Promedio general de cada estudiante a lo largo de todas las materias:

```python
por_alumno = (
    resultado
    .group_by(["cod_estudiante", "nombre"])
    .agg([
        pl.col("nota").mean().alias("promedio_general"),
        pl.col("nota").count().alias("materias_evaluadas"),
    ])
    .sort("promedio_general", descending=True)
)
```

<div class="box warn">
Cuando la llave de agrupación tiene más de una columna, todas deben ir en una lista. Aquí incluimos <code>cod_estudiante</code> y <code>nombre</code> porque hay pequeñas inconsistencias en los nombres entre tablas: la llave numérica garantiza la identidad del alumno.
</div>


---

<!-- _class: seccion -->

## Window functions

<p>Calcular agregados por grupo sin reducir las filas</p>

---

## Z-score por materia con `.over()`

`.over()` calcula un agregado particionado por grupo y lo asigna a cada fila. El número de filas no cambia. Es el equivalente de `PARTITION BY` en SQL:

```python
df_zscore = resultado.with_columns([
    pl.col("nota").mean().over("materia").alias("media_materia"),
    pl.col("nota").std().over("materia").alias("std_materia"),
]).with_columns(
    ((pl.col("nota") - pl.col("media_materia")) / pl.col("std_materia"))
    .round(2)
    .alias("z_score")
)
```

<div class="cols">
<div>

**group_by** - reduce filas

materia     | promedio
|---|---|
castellano  | 2.81
matematicas | 6.87


</div>
<div>

**over** - mantiene todas las filas

nombre      | materia    | nota | media | z_score
|---|---|---|---|---|
Raul Martos | castellano | 0.0  | 2.81  | -1.09
Santos Rico | castellano | 2.27 | 2.81  | -0.21


</div>
</div>



---

<!-- _class: cierre -->

## ¿Qué aprendimos hoy?

<div class="cols">
<div>

**Conceptos**
- Ingesta desde CSV, Excel y R como pasos iniciales del ETL
- `with_columns` agrega sin eliminar y opera en bloque
- Normalizar texto antes de un join evita errores silenciosos
- Long es para calcular, wide es para presentar
- `group_by` reduce filas; `.over()` mantiene todas las filas

</div>
<div>

**En Polars**
- `pl.read_csv()`, `pl.read_excel()`, `pl.from_pandas()`
- `.select()`, `.drop()`, `.rename()`
- `.head()`, `.tail()`, `.slice()`, `.sort()`
- `.with_columns()` con `cast`, `str.*`, `dt.*` y aritmética
- `.pivot()`, `.unpivot()`
- `.join()` encadenado sobre múltiples tablas
- `.group_by().agg()`, `.over()`

</div>
</div>

