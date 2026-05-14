---
marp: true
theme: flacso
paginate: true
---

<!-- _class: portada -->

<img src="../estilos/logo_flacso.png" class="logo" />

<div class="tag">Sesión 2: Data Wrangling y Pivots</div>

# Data Wrangling y Pivots

<p>Fausto Jácome Pérez<br>FLACSO Ecuador</p>

<div class="pregunta">
Tengo los datos en memoria. ¿Cómo los preparo para responder una pregunta sobre desnutrición infantil?
</div>

---

## ¿Dónde estamos?

<div class="cols3">
  <div class="card">
    <div class="num">1</div>
    <div class="lbl">Sesión anterior</div>
    <br>
    Cargamos <code>f1_personas</code>. Vimos el schema, los tipos inferidos, los missings. Terminamos con una pregunta pendiente: ¿por qué <code>area</code> es <code>Float64</code>?
  </div>
  <div class="card" style="border-left-color:var(--flacso)">
    <div class="num">2</div>
    <div class="lbl">Esta sesión</div>
    <br>
    Corregir tipos. Filtrar. Recodificar. Reshapear. Todas las operaciones que ocurren antes de calcular cualquier indicador.
  </div>
  <div class="card">
    <div class="num">3</div>
    <div class="lbl">Próxima sesión</div>
    <br>
    Funciones de ventana: calcular indicadores dentro de grupos sin perder filas.
  </div>
</div>

<div class="box">
El objetivo de hoy: dejar <code>f1_personas</code> lista para calcular prevalencia de desnutrición crónica. Y entender por qué la vacunación de rotavirus <em>obliga</em> a reshapear.
</div>

---

<!-- _class: seccion -->

## Paso 0: corregir tipos

<p>Antes de filtrar o calcular, los tipos tienen que ser los correctos</p>

---

## El problema de los tipos mal inferidos

Cuando Polars lee un CSV, infiere los tipos columna por columna. Lo hace bien para `fexp` (es genuinamente `Float64`). Pero se equivoca con columnas que tienen *códigos numéricos*:

| Variable | Tipo inferido | Tipo correcto | Por qué importa |
|---|---|---|---|
| `area` | `Float64` | `Categorical` | Urbano=1, Rural=2 no son magnitudes |
| `region` | `Float64` | `Categorical` | Costa=1, Sierra=2, Amazonia=3 |
| `prov` | `Float64` o `Int64` | `String` | Código de provincia, no número |
| `estrato` | `String` | `Categorical` | Ya es string pero conviene categorizar |
| `id_upm` | `Int64` | `String` | Es un identificador, no una cantidad |
| `f1_s1_2` | `Int64` | `Categorical` | Sexo: 1=Hombre, 2=Mujer |

<div class="box warn">
Un <code>Float64</code> donde debería haber una categoría no genera error - simplemente devuelve resultados sin sentido. Promediar <code>area</code> da 1.38. Nadie lo advierte.
</div>

---

## Cast con `.with_columns()` - por nombre explícito

La forma más clara para estudiantes: una sola llamada `.with_columns()` con una lista de expresiones `cast`:

```python
import polars as pl

df = df.with_columns([
    # Variables geográficas y de diseño muestral
    pl.col("area").cast(pl.Categorical),
    pl.col("region").cast(pl.Categorical),
    pl.col("estrato").cast(pl.Categorical),
    pl.col("parr_pri").cast(pl.Categorical),

    # Identificadores: son códigos, no cantidades
    pl.col("id_upm").cast(pl.String),
    pl.col("id_viv").cast(pl.String),
    pl.col("id_hogar").cast(pl.String),
    pl.col("id_per").cast(pl.String),

    # Variables sociodemográficas
    pl.col("f1_s1_2").cast(pl.Categorical),   # sexo
    pl.col("prov").cast(pl.String),            # código provincia
])
```

---

## Cast - forma alternativa con **selectores**

Polars también tiene selectores (`cs`) para operar sobre grupos de columnas por tipo. Es más compacto cuando el grupo es homogéneo:

```python
import polars.selectors as cs

# Ver cuáles son Float64 actualmente
print(df.select(cs.by_dtype(pl.Float64)).columns)

# Cambiar a String todas las que son identificadores
id_cols = ["id_upm", "id_viv", "id_hogar", "id_per", "id_mef"]
df = df.with_columns(
    cs.by_name(*id_cols).cast(pl.String))
```

<div class="box">
<strong>Regla práctica:</strong> usar <code>cs.by_dtype()</code> cuando todas las columnas de ese tipo necesitan el mismo cast.
</div>

<div class="box warn">
No todas las <code>Float64</code> deben convertirse a <code>Categorical</code>. <code>fexp</code>, <code>talla</code>, <code>peso</code> son genuinamente numéricas y deben quedarse como están.
</div>

---

<!-- _class: seccion -->

## Filtros y seleccion

<p>.filter(), .select(), .drop() y selectores</p>

---

## `.filter()` - filas que cumplen una condición

La sintaxis básica es siempre `pl.col("nombre") operador valor`:

```python
# Menores de 5 años (< 1826 días) - población objetivo de desnutrición crónica
menores5 = df.filter(pl.col("edaddias") < 1826)

# Menores de 2 años (< 730 días) - grupo objetivo del Decreto Presidencial 1211
menores2 = df.filter(pl.col("edaddias") < 730)

# Solo área urbana (código 1)
urbanos = df.filter(pl.col("area") == pl.lit("1"))

# Condiciones múltiples con & (and) y | (or)
urbanos_menores5 = df.filter(
    (pl.col("area") == pl.lit("1")) &
    (pl.col("edaddias") < 1826)
)
```

<div class="box warn">
Con <code>Categorical</code>, comparar contra strings requiere <code>pl.lit()</code>. Sin él, Polars puede lanzar un error de tipos o comparar de forma inesperada.
</div>

---

## `.select()` y `.drop()` - columnas que necesito

`.select()` elige columnas. `.drop()` descarta. Ambas admiten selectores:

```python
import polars.selectors as cs

# Seleccion manual: las columnas clave para desnutricion
df_trabajo = df.select([
    "id_per", "id_hogar",
    "area", "region", "prov",
    "fexp", "estrato",
    "f1_s1_2",        # sexo
    "edaddias",       # calculada en sesion 1
    "dcronica",       # indicador precalculado
])

# Con selectores: quedarme con IDs + categoricas + floats
df_trabajo = df.select(
    cs.by_name("id_per", "id_hogar", "fexp", "estrato") |
    cs.categorical() |
    cs.by_name("edaddias", "dcronica")
)
```

---

## Piedra Rosetta - Cast y Filtros

<div class="rosetta">
  <div class="r-py">Python · Polars</div>
  <div class="r-r">R · dplyr</div>
  <div class="r-sql">SQL · PostgreSQL</div>
</div>

<div class="cols3" style="gap:8px;">

```python
# Cast
df = df.with_columns([
  pl.col("area")
    .cast(pl.Categorical),
  pl.col("region")
    .cast(pl.Categorical),
])

# Filtro
menores5 = df.filter(
  pl.col("edaddias") < 1826
)
```

```r
library(dplyr)

# Cast
df <- df %>%
  mutate(
    area = as.factor(area),
    region = as.factor(region)
  )

# Filtro
menores5 <- df %>%
  filter(edaddias < 1826)
```

```sql
-- Cast (al crear la tabla)
ALTER TABLE personas
  ALTER COLUMN area
  TYPE VARCHAR;

-- Filtro
SELECT *
FROM personas
WHERE edaddias < 1826;
```

</div>

---

<!-- _class: seccion -->

## Ejercicio 1

<p>Identificar y corregir los tipos de las variables restantes</p>

---

## Ejercicio 1 - Cast de variables pendientes

<div class="box verde">
<strong>Objetivo:</strong> corregir los tipos de las variables que dejamos pendientes en la sesión 1.
</div>

Usando el diccionario de la ENDI (`Diccionario_variables_ENDI_R2.xlsx`, hoja `f1_personas`):

1. Identifiquen 3 variables adicionales que tienen tipo incorrecto (distintas a las que ya corregimos)
2. Para cada una, digan cuál debería ser el tipo correcto y por qué
3. Apliquen el cast con `.with_columns()`
4. Verifiquen el resultado con `df.schema`

**Pistas:** miren las variables de la Sección 1 del formulario (información del miembro del hogar) y la Sección 2 (actividades económicas). ¿Tiene sentido que `f1_s1_3` (relación de parentesco) sea `Int64`?

<div class="box warn">
No toquen <code>fexp</code>, <code>fexp_lm</code>, <code>fexp_di</code> - esos <code>Float64</code> son correctos.
</div>

---

<!-- _class: seccion -->

## Recodificación

<p>.with_columns(), pl.when().then().otherwise() y mapeo de etiquetas</p>

---

## ¿Qué es recodificar?

Recodificar es transformar los valores de una columna existente en algo más útil para el análisis. Hay tres casos típicos:

<div class="cols3">
<div class="card">

**Mapear etiquetas**

Pasar de código numérico a texto legible.

`1` → `"Urbana"`
`2` → `"Rural"`

Necesario porque la ENDI entrega códigos, no etiquetas.

</div>
<div class="card accent">

**Crear variables derivadas**

Construir una variable nueva a partir de otras.

`edaddias` → grupos de edad: `"0-23 meses"`, `"24-59 meses"`

Necesario para desagregaciones analíticas.

</div>
<div class="card green">

**Corregir o limpiar**

Reemplazar códigos de no respuesta por `null`.

`88`, `99`, `9999` → `null`

Necesario antes de cualquier cálculo.

</div>
</div>

<div class="box" style="margin-top:16px;">
En Polars, todas estas operaciones usan <code>pl.when().then().otherwise()</code> dentro de <code>.with_columns()</code>.
</div>

---

## Mapeo de etiquetas con `pl.when().then().otherwise()`

Caso concreto: `area` (1 = Urbana, 2 = Rural) y `region`:

```python
df = df.with_columns([

    # Etiqueta de area
    pl.when(pl.col("area") == pl.lit("1")).then(pl.lit("Urbana"))
      .when(pl.col("area") == pl.lit("2")).then(pl.lit("Rural"))
      .otherwise(pl.lit(None))
      .alias("area_etiq"),

    # Etiqueta de region (Costa=1, Sierra=2, Amazonia=3)
    pl.when(pl.col("region") == pl.lit("1")).then(pl.lit("Costa"))
      .when(pl.col("region") == pl.lit("2")).then(pl.lit("Sierra"))
      .when(pl.col("region") == pl.lit("3")).then(pl.lit("Amazonia"))
      .otherwise(pl.lit(None))
      .alias("region_etiq"),

])
```

<div class="box">
<code>.alias("nombre")</code> crea la columna con ese nombre. Sin alias, Polars usa el nombre de la columna original y <strong>sobreescribe</strong> la columna.
</div>

---

## Crear variables derivadas - grupos de edad

Para el indicador de desnutricion cronica, el INEC trabaja con dos grupos: menores de 2 anos y menores de 5. Construimos la variable de grupo:

```python
df = df.with_columns(
    pl.when(
        (pl.col("edaddias") >= 0) & (pl.col("edaddias") < 730)
    ).then(pl.lit("0-23 meses"))
     .when(
        (pl.col("edaddias") >= 730) & (pl.col("edaddias") < 1826)
     ).then(pl.lit("24-59 meses"))
     .otherwise(pl.lit(None))
     .alias("grupo_edad")
)

# Verificar
df.filter(
    pl.col("edaddias").is_not_null()
)["grupo_edad"].value_counts()
```

<div class="box warn">
730 dias = 365.25 * 2. 1826 dias = 365.25 * 5. El decimal importa cuando las edades se calculan en dias exactos - es la metodologia del Manual WHO Anthro.
</div>

---

## Piedra Rosetta - Recodificacion

<div class="rosetta2">
  <div class="r-py">Python · Polars</div>
  <div class="r-r">R · dplyr / sjlabelled</div>
</div>

<div class="cols" style="gap:8px;">

```python
# Crear etiqueta de area
df = df.with_columns(
    pl.when(pl.col("area") == pl.lit("1"))
      .then(pl.lit("Urbana"))
      .when(pl.col("area") == pl.lit("2"))
      .then(pl.lit("Rural"))
      .otherwise(pl.lit(None))
      .alias("area_etiq")
)

# Crear grupo de edad
df = df.with_columns(
    pl.when(pl.col("edaddias") < 730)
      .then(pl.lit("0-23 meses"))
      .when(pl.col("edaddias") < 1826)
      .then(pl.lit("24-59 meses"))
      .otherwise(pl.lit(None))
      .alias("grupo_edad")
)
```

```r
library(dplyr)
library(sjlabelled)

# En R, la ENDI ya viene con etiquetas
# as_label() las convierte directamente
df <- df %>%
  mutate(area = as_label(area))

# O con case_when (equivalente manual)
df <- df %>%
  mutate(
    area_etiq = case_when(
      area == 1 ~ "Urbana",
      area == 2 ~ "Rural",
      TRUE      ~ NA_character_
    ),
    grupo_edad = case_when(
      edaddias < 730  ~ "0-23 meses",
      edaddias < 1826 ~ "24-59 meses",
      TRUE            ~ NA_character_
    )
  )
```

</div>

---

<!-- _class: seccion -->

## Ejercicio 2

<p>Construir la etiqueta de region y filtrar menores de 2 anos</p>

---

## Ejercicio 2 - Region y grupo objetivo del decreto

<div class="box verde">
<strong>Objetivo:</strong> construir una variable etiquetada para <code>region</code> y filtrar el grupo objetivo del Decreto Presidencial 1211.
</div>

1. Creen la variable `region_etiq` con las etiquetas: Costa, Sierra, Amazonia
2. Filtren el subconjunto de menores de 2 anos (`edaddias < 730`)
3. Sobre ese subconjunto, cuenten cuántos casos hay por region usando `.group_by("region_etiq").agg(pl.len())`
4. Respondan: ¿en qué region hay mas menores de 2 anos en la muestra?

**Conexion con el indicador:** el Decreto Presidencial 1211 (2020) fijo como meta reducir la desnutricion cronica en menores de 24 meses. Por eso el INEC reporta `dcronica2_5` como variable separada para ese subgrupo.

<div class="box" style="font-size:17px;">
<code>dcronica</code> cubre menores de 5 anos. <code>dcronica2_5</code> cubre menores de 2 anos. Son variables precalculadas en la tabla - no hay que construirlas desde cero en este tramo.
</div>

---

<!-- _class: seccion -->

## Reshaping: Long vs Wide

<p>La forma de la tabla determina las preguntas que puedes responder</p>

---

## El problema de la tabla MEF

La tabla `f2_mef` registra informacion de mujeres en edad fertil. Cada mujer puede tener varios hijos. El INEC guardo los datos en formato **wide**: cada hijo es un conjunto de columnas.

**Estructura wide (lo que tiene la tabla):**

| id_mef | f2_s2_235_a_01 | f2_s2_235_b_dia_01 | f2_s2_235_a_02 | f2_s2_235_b_dia_02 | ... |
|---|---|---|---|---|---|
| M001 | 1 (Hombre) | 15 | 2 (Mujer) | 3 | ... |
| M002 | 2 (Mujer) | 22 | null | null | ... |

**El problema:** para calcular la edad de vacunacion de cada hijo, necesito una fila por hijo, no una columna por hijo.

<div class="box warn">
En formato wide no se puede filtrar <em>"todos los hijos menores de 1 ano"</em> con un solo <code>.filter()</code>. Habria que escribir una condicion por cada columna de hijo. Con hasta 10 hijos por mujer, son 10 condiciones.
</div>

---

## Wide a Long - concepto

<div class="cols">
<div>

**Wide:** cada observacion es una fila. Las categorias de una variable se distribuyen en columnas.

```
id_mef | hijo_01_sexo | hijo_02_sexo
M001   | Hombre       | Mujer
M002   | Mujer        | null
```

Util para: presentacion, tablas cruzadas, cuando los atributos son fijos y pocos.

</div>
<div>

**Long:** cada combinacion (unidad, categoria) es una fila. Una columna identifica la categoria, otra tiene el valor.

```
id_mef | ord_hijo | sexo
M001   | 01       | Hombre
M001   | 02       | Mujer
M002   | 01       | Mujer
```

Util para: analisis, filtros, calculos, graficos. Es la forma **tidy** de los datos.

</div>
</div>

<div class="box">
La mayoria de las operaciones de analisis esperan datos en formato <strong>long</strong>. El formato wide es para leer, el long es para calcular.
</div>

---

## `.unpivot()` - de wide a long en Polars

La sintaxis oficial de Polars para pasar de wide a long es `.unpivot()`:

```python
# Seleccionamos solo las columnas de hijos (sexo y fecha nacimiento)
cols_hijos = [c for c in df_mef.columns
              if c.startswith("f2_s2_235_")]

df_hijos = df_mef.select(["id_mef"] + cols_hijos)

# Wide a long
df_long = df_hijos.unpivot(
    on=cols_hijos,          # columnas que se van a "apilar"
    index=["id_mef"],       # columnas que se mantienen como identificador
    variable_name="campo",  # nombre de la columna que tendra el nombre de la variable
    value_name="valor",     # nombre de la columna que tendra el valor
)
```

<div class="box" style="font-size:17px;">
El resultado tiene <code>n_filas_original × n_columnas_apiladas</code> filas. Si la tabla original tiene 19.846 mefs y 50 columnas de hijos, el resultado tiene ~992.300 filas.
</div>

---

## `.pivot()` - de long a wide en Polars

La operacion inversa: colapsar una columna de categorias en columnas separadas.

```python
# Ejemplo: de long a wide, una columna por tipo de vacuna
df_wide = df_vacunas_long.pivot(
    on="tipo_vacuna",       # columna cuyos valores se convierten en nombres de columna
    index="id_hijo_ord",    # columna(s) que identifican la unidad de analisis
    values="aplicada",      # columna con los valores a distribuir
    aggregate_function="first"  # si hay duplicados, tomar el primero
)
```

<div class="box warn">
<strong>Cuidado con los duplicados:</strong> si hay mas de un valor por combinacion (index, on), Polars aplica la funcion de agregacion. Si no se especifica, lanza un error. Lo mas comun es <code>"first"</code> o <code>"sum"</code>.
</div>

---

## El flujo completo para vacunacion de rotavirus

La ficha metodologica del INEC hace exactamente esto: wide → long → calcular → long → wide

```python
# 1. Seleccionar columnas de hijos de la MEF
cols_hijos = [c for c in df_mef.columns if "f2_s2_235_" in c]
df_hijos = df_mef.select(["id_mef"] + cols_hijos)

# 2. Wide a long (una fila por hijo)
df_hijos_long = df_hijos.unpivot(
    on=cols_hijos, index=["id_mef"],
    variable_name="campo", value_name="valor"
)

# 3. Separar el nombre del campo para extraer orden del hijo
# (esto lo trabajamos en detalle en el ejercicio)

# 4. Calcular edad de vacunacion en dias por cada dosis

# 5. Long a wide (volver a una fila por hijo con columnas por dosis)
df_vacunas_wide = df_vacunas_long.pivot(
    on="dosis", index="id_hijo_ord", values="edad_dias_vac"
)
```

---

## Piedra Rosetta - Reshaping

<div class="rosetta2">
  <div class="r-py">Python · Polars</div>
  <div class="r-r">R · tidyr</div>
</div>

<div class="cols" style="gap:8px;">

```python
# Wide a long
df_long = df_wide.unpivot(
    on=cols_variables,
    index=["id_mef"],
    variable_name="campo",
    value_name="valor"
)

# Long a wide
df_wide2 = df_long.pivot(
    on="campo",
    index=["id_mef"],
    values="valor",
    aggregate_function="first"
)
```

```r
library(tidyr)

# Wide a long
df_long <- df_wide %>%
  pivot_longer(
    cols = starts_with("f2_s2_235_"),
    names_to  = "campo",
    values_to = "valor"
  )

# Long a wide
df_wide2 <- df_long %>%
  pivot_wider(
    id_cols    = id_mef,
    names_from  = campo,
    values_from = valor
  )
```

</div>

---

<!-- _class: seccion -->

## Ejercicio 3

<p>Primer paso del indicador de vacunacion de rotavirus</p>

---

## Ejercicio 3 - De wide a long en f2_mef

<div class="box verde">
<strong>Objetivo:</strong> aplicar <code>.unpivot()</code> para obtener una fila por hijo a partir de la tabla <code>f2_mef</code>.
</div>

**Pasos:**

1. Carguen `f2_mef` (ya lo hicieron en la sesion 1 si siguieron el ejercicio)
2. Identifiquen cuántas columnas empiezan con `f2_s2_235_` - esas son los campos de hijos
3. Apliquen `.unpivot()` sobre esas columnas, manteniendo como index: `id_mef`, `id_upm`, `estrato`, `fexp`
4. Filtren las filas donde `valor` no es nulo (esas corresponden a hijos registrados)
5. ¿Cuántas filas tiene el resultado? ¿Tiene sentido comparado con el numero de mefs?

**Pregunta de cierre:** ¿por qué no podriamos calcular la edad de vacunacion de rotavirus directamente sobre la tabla wide sin hacer el unpivot primero?

---

<!-- _class: cierre -->

## ¿Qué aprendimos hoy?

<div class="cols">
<div>

**Conceptos**
- Cast: por que los tipos mal inferidos son errores silenciosos
- Filtros con condiciones multiples (`&`, `|`)
- Selectores (`cs`) para operar por tipo o nombre
- Recodificacion: etiquetas, variables derivadas, limpieza de no respuesta
- Long vs wide: cuando usar cada formato

</div>
<div>

**En Polars**
- `.with_columns([...])` con listas de expresiones
- `.cast(pl.Categorical)`, `.cast(pl.String)`
- `cs.by_name()`, `cs.by_dtype()`, `cs.categorical()`
- `.filter()` con `pl.col()` y `pl.lit()`
- `.select()` y `.drop()` con selectores
- `pl.when().then().otherwise().alias()`
- `.unpivot()` y `.pivot()`

</div>
</div>

<div class="box verde">
<strong>Tarea (para el lunes):</strong> a partir de <code>f1_personas</code>, aplicar los casts necesarios, filtrar menores de 5 anos, recodificar <code>area</code> y <code>region</code>, y calcular la prevalencia de <code>dcronica</code> por area como promedio simple. El resultado debe ser una tabla de dos filas.
</div>

---

## Tarea - Detalle

<div class="box warn">
<strong>Hay tarea para esta sesion.</strong> Se entrega como celda adicional en el notebook de la sesion 2.
</div>

**Pasos requeridos:**

1. Cargar `f1_personas` y aplicar todos los casts de tipos correctos (al menos area, region, prov, identificadores)
2. Filtrar menores de 5 anos (`edaddias < 1826`) y que `dcronica` no sea nula
3. Crear la variable `area_etiq` con etiquetas "Urbana" / "Rural"
4. Calcular la prevalencia de `dcronica` por area:
   `df.group_by("area_etiq").agg(pl.mean("dcronica").alias("prevalencia"))`
5. Interpretar el resultado: ¿en qué area es mayor la desnutricion cronica?

**Lo que NO se pide todavia:** aplicar el factor de expansion `fexp`. El promedio simple es una aproximacion - las cifras oficiales del INEC usan el diseno muestral completo, que veremos en la sesion 4.

<div class="box" style="font-size:17px;">
<strong>Proximamente:</strong> funciones de ventana - calcular indicadores dentro de grupos sin perder las filas originales.
</div>