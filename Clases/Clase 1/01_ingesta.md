---
marp: true
theme: flacso
math: mathjax
paginate: true
---

<!-- _class: portada -->

<img src="../estilos/logo_flacso.png" class="logo" />

<div class="tag">Sesión 1: Ingesta y Arquitectura</div>

# Ingesta de Datos y<br>Arquitectura de Tablas

<p>Fausto Jácome Pérez <br>
FLACSO Ecuador <br></p>

---

## Vamos a trabajar con la Encuesta de Desnutrición Infantil (ENDI)

<div class="cols3" style="margin-bottom:24px;">
  <div class="card">
    <div class="num">22.250</div>
    <div class="lbl">Viviendas visitadas</div>
  </div>
  <div class="card">
    <div class="num">93.242</div>
    <div class="lbl">Personas registradas</div>
  </div>
  <div class="card">
    <div class="num">6</div>
    <div class="lbl">Tablas relacionales</div>
  </div>
</div>

**Población objetivo:** Niñas y niños menores de 5 años

**Cobertura:** Nacional, Regional, Provincial, Urbano–Rural

**Comparabilidad histórica:** ECV 2006/2014, ENSANUT 2012/2018, ENDI 2022–23

<div class="box">
Una encuesta así <strong>no cabe en una sola tabla</strong>. Vamos a entender por qué.
</div>

---

<!-- _class: seccion -->

## Datos estructurados,<br>semiestructurados y no estructurados

<p>¿Dónde entra la ENDI?</p>

---

## Tipos de datos según su formato y reglas esquema

<div class="cols3">
<div class="card">

**Estructurados**
Filas y columnas. Esquema fijo. SQL nativo.

*Ejemplos:* encuesta, registros administrativos, contabilidad, bancarios.

*Formatos*: csv*, xlsx*, parquet, sql

**La ENDI entra aquí**

</div>
<div class="card">

**Semiestructurados**
Tienen estructura, pero flexible. No hay esquema rígido.

*Ejemplos:* logs de servidor, respuestas de API [(Clima)](https://api.open-meteo.com/v1/forecast?latitude=-0.1865943&longitude=-78.4305382&current=temperature_2m,wind_speed_10m), Geography Markup Language (GML) [ver mapa] 

*Formatos*: csv*, xlsx*, JSON, XML, YAML

</div>
<div class="card">

**No estructurados**
Sin esquema predefinido. Requieren procesamiento extra.

*Ejemplos:* texto libre, imágenes, audio, video.

</div>
</div>

<div class="box" style="margin-top:20px;">
Este tramo se enfoca en <strong>datos estructurados</strong>. La misma lógica de organización aplica a los otros tipos, pero el punto de partida más común en ciencias sociales es la tabla.
</div>

---

<!-- _class: seccion -->

## ¿Por qué separar en tablas?

<p>Normalización y formas normales</p>

---

## El problema de la tabla única

Imaginemos que guardamos todo en una sola tabla: vivienda, hogar, personas y niños.

**¿Qué problemas aparecen?**

- **Redundancia:** los datos de la vivienda se repiten para cada persona que vive ahí
- **Anomalías de actualización:** si hay que modificar un dato de vivienda, hay que actualizar N filas
- **Anomalías de eliminación:** si se hay que eliminar a una persona en una vivienda unipersonal , perdemos todos los datos de la vivienda
- **Tamaño:** la tabla crece innecesariamente

**La solución es normalización**: Organizar los datos separando la información en tablas según su unidad de análisis.

<div class="box">
Las <strong>formas normales</strong> (1FN, 2FN, 3FN) son las reglas formales de ese proceso. No las derivamos aquí, pero el principio es simple: <em>cada tabla describe una sola cosa</em>. <a href="https://youtu.be/GFQaEYEc8_8?si=PWiSrGIsFx5IzkQm">(ver más detalles)</a> 
</div>

---

## Modelo lógico de la ENDI

**Diagrama entidad-relación simplificado**

<div class="er">
  <div class="er-table">
    <div class="er-head">Hogar</div>
    <div class="er-row pk">🔑 id_hogar</div>
    <div class="er-row">area, prov, region</div>
    <div class="er-row">estrato, parr_pri</div>
  </div>
  <div class="er-arrow">1 → N</div>
  <div class="er-table">
    <div class="er-head">Personas</div>
    <div class="er-row pk">🔑 id_per</div>
    <div class="er-row fk">🔗 id_hogar</div>
    <div class="er-row">edad, sexo, talla</div>
    <div class="er-row">fexp *(expansión)*</div>
  </div>
  <div class="er-arrow">1 → N</div>
  <div class="er-table">
    <div class="er-head">Salud niñez</div>
    <div class="er-row pk">🔑 id_hijo_ord</div>
    <div class="er-row fk">🔗 id_per</div>
    <div class="er-row fk">🔗 id_mef_per</div>
    <div class="er-row">vacunas, enf.</div>
  </div>
</div>

<div class="cols" style="margin-top:4px; font-size:17px;">
<div>

**Llaves primarias** <span style="color:var(--accent)">🔑</span> — identifican de forma única cada fila  
**Llaves foráneas** <span style="color:var(--green)">🔗</span> — conectan tablas entre sí

</div>
<div>

**Modelo lógico** → qué entidades existen y cómo se relacionan  
**Modelo físico** → cómo se implementa en PostgreSQL (sesión 3–4)

</div>
</div>

---

## Las 6 tablas de la ENDI

| Tabla | Unidad de análisis | Filas | Factor de expansión |
|---|---|---|---|
| `f1_personas` | Miembro del hogar | 93 242 | `fexp` |
| `f1_hogar` | Hogar | 20 186 | `fexp` |
| `f2_mef` | Mujer en edad fértil (10–49 años) | 19 846 | `fexp` |
| `f2_lactancia` | Niño/a menor de 3 años | 12 141 | `fexp_lm` |
| `f2_salud_ninez` | Niño/a menor de 5 años | 22 188 | `fexp` |
| `f3_desarrollo_inf` | Niño/a menor de 5 años | 9 836 | `fexp_di` |


<div class="box warn">
⚠ Cada tabla tiene <strong>su propio factor de expansión</strong>. Mezclarlos es uno de los errores más comunes al trabajar con encuestas. Lo profundizamos en sesión 4.
</div>

---

<!-- _class: seccion -->

## El flujo del dato

<p>Desde el archivo en disco hasta el resultado para el análisis</p>

---

## Disco → RAM → CPU

<div class="mem-diagram">
  <div class="mem-block mem-disk">
    <!-- <span class="mem-icon">💾</span> -->
    <div class="mem-title">Disco duro</div>
    <div class="mem-sub">El archivo existe aquí.<br>`.csv`, `.rds`, `.dta`<br><br>No se puede calcular nada hasta que se cargue.</div>
  </div>
  <div class="mem-block mem-ram">
    <!-- <span class="mem-icon">🧠</span> -->
    <div class="mem-title">RAM (memoria)</div>
    <div class="mem-sub">La tabla vive aquí mientras trabajamos.<br><br>Polars / R / Pandas la cargan acá.<br><br>Si la tabla es más grande que la RAM → problema.</div>
  </div>
  <div class="mem-block mem-cpu">
    <!-- <span class="mem-icon">⚙️</span> -->
    <div class="mem-title">CPU</div>
    <div class="mem-sub">Aquí se ejecutan las funciones: filtros, agrupaciones, joins.<br><br>Polars lo paraleliza por columna.</div>
  </div>
</div>

<div class="box" style="font-size:17px;">
Cuando hacemos <code>pl.read_csv("archivo.csv")</code> estamos <strong>moviendo datos del disco a la RAM</strong>. Lo que viene después ocurre en la RAM y el CPU.
</div>

---

## ¿Por qué Polars y no Pandas? ¿Por qué Postgres no explota?

<div class="cols">
<div>

### Pandas vs Polars

**Pandas** carga toda la tabla en RAM de una vez, en formato de filas. Cada operación recorre fila por fila.

**Polars** usa almacenamiento **columnar** (Arrow) y **evaluación perezosa** (*lazy evaluation*):
- Construye un plan de consulta
- Solo lee las columnas necesarias
- Ejecuta en paralelo por columna
- Para datos que no caben en RAM, Polars tiene un modo streaming que procesa en lotes.

**Resultado:** Polars puede ser 5–20× más rápido en operaciones de agregación.

</div>
<div>

### ¿Por qué Postgres no se "cuelga" con millones de filas?

- Los datos viven en **disco** en páginas de 8KB, no en RAM
- Los **índices** evitan el escaneo completo: recorren
  un árbol hasta encontrar la página + slot exacto
  donde vive cada fila (O(log n) en lugar de O(n))
- Sin índice, Postgres hace un *sequential scan* (lee todas las páginas)
- En nuestro caso, las llaves primarias (`id_per`, `id_hogar`) tienen índice automático

<div class="box" style="font-size:16px;">
Postgres puede analizar una tabla de 50M de filas en un servidor
con 8GB de RAM porque nunca necesita cargarla completa.
</div>
</div>
</div>

---

<!-- _class: seccion -->

## Formatos de entrada

<p>Los datos no siempre llegan como uno quisiera</p>

---

## Formatos comunes y sus particularidades

<div class="cols">
<div>

### Texto plano (¿simple?)
**`.csv`** — separado por comas *(¡ojo con el separador!)*
- Puede ser `;` en configuraciones en español
- Puede ser `\t` (TSV)
- **Encoding:** `UTF-8` o `latin-1` / `ISO-8859-1` — crítico para tildes y ñ

<div class="box" style="font-size:15px; margin: 8px 0;">
<strong>¿Qué es el encoding?</strong> Es la tabla que mapea caracteres a números binarios. UTF-8 puede representar cualquier caracter del mundo. Latin-1 solo cubre el alfabeto occidental (default de Windows en español).
</div>

```python
# CSV con separador punto y coma
import polars as pl
pl.read_csv("archivo.csv", separator=";",
            encoding="latin-1")
```

</div>
<div>

### Formatos estadísticos
**`.rds`** — formato nativo de R, preserva tipos
**`.dta`** — formato Stata
**`.sav`** — formato SPSS
**`.xlsx`** — Excel, ojo con hojas múltiples


```python
# Leer .rds directamente desde Python
import pyreadr
import polars as pl

resultado = pyreadr.read_r("tabla.rds")
df = pl.from_pandas(resultado[None]) 
# None porque el rds tiene un solo objeto
```

</div>
</div>

<div class="box warn">
El INEC ofrece la ENDI en <code>.rds</code> y <code>.dta</code>. En clase descargaremos en <code>.rds</code> ya que preserva los tipos de variable automáticamente.
</div>

---

<!-- _class: seccion -->

## Piedra Rosetta #1

<p>Cargar datos: la misma operación en tres herramientas</p>

---

## Piedra Rosetta — Carga desde CSV

<div class="rosetta">
  <div class="r-py">Python - Polars</div>
  <div class="r-r">R</div>
  <div class="r-sql">SQL - PostgreSQL</div>
</div>

<div class="cols3" style="gap:8px;">

<div>

```python
import polars as pl

df = pl.read_csv(
  "BDD_ENDI_R2_f1_personas.csv",
  separator=";",
  encoding="utf-8",
  has_header=True
)
```

</div>
<div>

```r
library(readr)

df <- read_delim(
  "BDD_ENDI_R2_f1_personas.csv",
  delim = ";",
  locale = locale(encoding = "UTF-8"),
  col_names = TRUE
)
```

</div>
<div>

```sql
# Debe existir el DDL previamente (próximas clases)

COPY personas
FROM '/ruta/BDD_f1_personas.csv'
DELIMITER ';'
CSV HEADER
ENCODING 'UTF8';
```

</div>
</div>

<div class="box verde" style="font-size:17px;">
<strong>Piedra Rosetta:</strong> las tres operaciones hacen exactamente lo mismo. El concepto — <em>leer un archivo e inferir su estructura</em> independientemente de la herramienta.
</div>

---
## `read_csv` vs `scan_csv` (lazy)

<div class="cols">
<div>

### `read_csv` — ejecución inmediata

```python
df = pl.read_csv(
  "BDD_ENDI_R2_f1_personas.csv",
  separator=";",
  encoding="utf-8",
  has_header=True
)
```

- Lee el archivo completo al llamar la función
- Las 124 columnas y 93.242 filas entran a RAM de una vez
- El resultado es un `DataFrame` listo para usar

</div>
<div>

### `scan_csv` — ejecución perezosa

```python
df = (
  pl.scan_csv(
    "BDD_ENDI_R2_f1_personas.csv",
    separator=";",
    encoding="utf-8",
    has_header=True
  )
  .filter(pl.col("area") == 1)
  .select(["id_per", "fexp", "area"])
  .collect()
)
```

- `scan_csv` no lee nada todavía — construye un plan
- `.filter()` y `.select()` agregan instrucciones al plan
- `.collect()` ejecuta todo: lee solo las columnas y filas necesarias
- El resultado es el mismo `DataFrame`, pero Polars nunca cargó las 124 columnas completas

</div>
</div>

<div class="box" style="font-size:17px;">
Para exploración inicial usa <code>read_csv</code>. Para producción o archivos grandes, <code>scan_csv</code> con <code>.filter()</code> y <code>.select()</code> antes de <code>.collect()</code> reduce significativamente el uso de RAM.
</div>

---

## Piedra Rosetta — Carga desde RDS

<div class="rosetta2">
  <div class="r-py">Python - Polars</div>
  <div class="r-r">R</div>
</div>

<div class="cols" style="gap:8px;">

<div>

```python
import pyreadr
import polars as pl

df = pl.from_pandas(
  pyreadr.read_r(
    "BDD_ENDI_R2_f1_personas.rds"
  )[None]
)
```

</div>
<div>

```r
df <- readRDS(
  "BDD_ENDI_R2_f1_personas.rds"
)
```

</div>
</div>

<div class="box" style="font-size:17px;">
En R la carga desde <code>.rds</code> es nativa y preserva los tipos de variable. En Python requiere convertir a pandas como paso intermedio.
</div>

</div>
</div>

---

<!-- _class: seccion -->

## Tipos de datos

<p>Más allá de "numérico" y "categórico"</p>

---

## Del concepto al byte

La distinción cuantitativo/cualitativo es analítica. Los tipos de datos en memoria son más específicos:

| Tipo | ¿Qué guarda? | Bytes típicos | Ejemplo en ENDI |
|---|---|---|---|
| `Int8 / Int16 / Int32 / Int64` | Enteros | 1–8 bytes | edad, número de hijos |
| `Float32 / Float64` | Decimales | 4–8 bytes | talla, peso, `fexp` |
| `Utf8 / String` | Texto | Variable | nombre de provincia |
| `Boolean` | Verdadero / Falso | 1 bit | ¿tiene agua potable? |
| `Date / Datetime` | Fechas | 4–8 bytes | fecha de entrevista |
| `Categorical` | Texto con categorías fijas | Comprimido | área (urbano/rural) |

<div class="box warn">
<strong>Precisión importa:</strong> un <code>Float64</code> ocupa el doble que un <code>Float32</code>. En una tabla de 93.000 filas y 124 columnas, usar el tipo correcto puede reducir el uso de RAM a la mitad.
</div>

---

## Bits, memoria y rangos

<div class="box">
Con <strong>N bits</strong> se pueden representar <strong>2^N combinaciones</strong>. Un bit reservado para el signo parte ese espacio en dos: mitad para negativos, mitad para positivos.
</div>

<div class="cols">
<div>

### Enteros

| Tipo | Bits | Rango |
|---|---|---|
| `Int8` | 8 | -128 a 127 |
| `UInt8` | 8 | 0 a 255 |
| `Int16` | 16 | -32.768 a 32.767 |
| `Int32` | 32 | -2.147M a 2.147M |
| `Int64` | 64 | -9.2×10^18 a 9.2×10^18 |
| `Boolean` | 1 | True / False |

</div>
<div>

### Decimales (punto flotante — IEEE 754)

| Tipo | Bits | Signo | Exponente | Mantisa | Precisión |
|---|---|---|---|---|---|
| `Float32` | 32 | 1 | 8 | 23 | ~7 dígitos |
| `Float64` | 64 | 1 | 11 | 52 | ~15 dígitos |

$$
\underbrace{1}_{s} \quad \underbrace{8 \text{ bits}}_{e} \quad \underbrace{23 \text{ bits}}_{m}
$$

$$
a = (-1)^s \cdot 1.m_2 \cdot 2^{e_2 - 127}
$$

<div class="box warn">
<code>fexp</code> en la ENDI es <code>Float64</code> — necesita los 15 dígitos de precisión para no distorsionar las estimaciones ponderadas.
</div>

</div>
</div>

---

## Los tipos en la ENDI — Polars

```python
import polars as pl

df = pl.read_csv("BDD_ENDI_R2_f1_personas.csv", separator=";")

# Ver nombres de columnas y sus tipos
print(df.schema)

# Alternativa: ver tipos como tabla
print(df.dtypes)          # lista de tipos en orden
print(df.columns)         # lista de nombres en orden

# Combinarlos como tabla legible
import pandas as pd       # solo para mostrar bonito
pd.DataFrame({"columna": df.columns, "tipo": df.dtypes})
```

<div class="box" style="font-size:17px;">
Polars infiere los tipos automáticamente al leer el CSV. Pero siempre vale la pena <strong>verificar</strong>: una columna de códigos numéricos (ej. código de provincia) puede ser leída como <code>Int64</code> cuando debería tratarse como <code>String</code> o <code>Categorical</code>.
</div>

---

<!-- _class: seccion -->

## Exploración inicial

<p>Variables, tipos, resumen y missings</p>

---

## Piedra Rosetta #2 — Exploración inicial


<div class="rosetta">
  <div class="r-py">Python · Polars</div>
  <div class="r-r">R · base / dplyr</div>
  <div class="r-sql">SQL · PostgreSQL</div>
</div>

<div class="cols3" style="gap:8px;">

```python
# Forma y primeras filas
df.shape        # (filas, cols)
df.head(5)
df.tail(3)

# Esquema
df.schema

# Resumen estadístico
df.describe()
```

```r
# Forma
dim(df)         # filas, cols
head(df, 5)

# Tipos
str(df)
glimpse(df)     # dplyr

# Resumen
summary(df)
```

```sql
-- Contar filas
SELECT COUNT(*) FROM personas;

-- Ver primeras filas
SELECT * FROM personas
LIMIT 5;

-- Columnas y tipos
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'personas';

\d personas -- en psql
```

</div>

---

## Resumen numérico y categorías

<div class="cols">
<div>

### Variables numéricas

```python
# Resumen completo: media, min, max,
# std, percentiles
df.describe()

# Solo columnas numéricas
df.select(pl.col(pl.NUMERIC_DTYPES)).describe()

# Distribución de una variable
df["p3_2"].value_counts().sort("count",descending=True)
```

`describe()` devuelve: `count`, `null_count`, `mean`, `std`, `min`, `25%`, `50%`, `75%`, `max`

</div>
<div>

### Variables categóricas

```python
# Categorías únicas de una variable
df["area"].unique()

# Conteo de cada categoría
df["area"].value_counts()

# Para varias columnas a la vez
cat_cols = ["area", "region", "parr_pri"]
for col in cat_cols:
    print(f"\n── {col} ──")
    print(df[col].value_counts())
```

</div>
</div>

---

## Datos perdidos — primer conteo



<div class="cols">
<div>

### ¿Cuántos nulos hay?

```python
# Conteo de nulos por columna
df.null_count()

# Proporción de nulos
(df.null_count() / len(df) * 100).transpose(
   include_header=True,
   column_names=["pct_nulo"]
 ).sort("pct_nulo", descending=True)
```

</div>
<div>

### Tipos de ausencia en la ENDI

| Código | Significa |
|---|---|
| `NA` / `.` | Ausente por flujo del formulario |
| `88` | No sabe / No responde |
| `99` / `9999` | Omisión del informante |
| `999` | Limitación logística |

<div class="box warn" style="font-size:16px;">
En la ENDI, los missings <strong>no son aleatorios</strong>. Un 'NA' en la sección de lactancia significa que ese niño tenía más de 3 años. Interpretarlos mal cambia los resultados.
</div>

</div>
</div>

---

<!-- _class: cierre -->

## ¿Qué aprendimos hoy?



<div class="cols">
<div>

**Conceptos**
- Datos estructurados, semiestructurados, no estructurados
- Normalización: por qué una tabla por entidad
- Diagrama ER, modelo lógico vs físico
- El flujo disco → RAM → CPU
- Tipos de datos: `int`, `float`, `string`, `boolean`, precisión

</div>
<div>

**En Polars**
- `pl.read_csv()` con separador y encoding
- `.shape`, `.schema`, `.dtypes`, `.columns`
- `.describe()` para variables numéricas
- `.value_counts()` para categóricas
- `.null_count()` para missings

</div>
</div>

<div class="box verde">
<strong>Próxima sesión:</strong> tenemos los datos cargados - ahora los transformamos. Data wrangling: filtros, recodificación y reshaping (long vs wide).
</div>

---

## Ejercicio práctico



<div class="box verde">
<strong>Tarea de la hora práctica:</strong> exploración inicial de la tabla <code>f1_personas</code> de la ENDI
</div>

**Instrucciones:**

1. Carguen la tabla `BDD_ENDI_R2_f1_personas.rds` y transformen a Polars
2. Impriman la forma de la tabla (filas y columnas)
3. Muestren el schema completo (nombre + tipo de cada columna)
4. Ejecuten `.describe()` y identifiquen 3 variables numéricas de interés
5. Hagan `.value_counts()` sobre las variables `area` y `region`
6. Calculen el porcentaje de nulos por columna — ¿cuáles tienen más missings?

**Pregunten:** ¿qué tipo de dato tiene `fexp`? ¿Tiene sentido ese tipo? ¿Y el código de provincia `prov`?

<div class="box warn">
Sin tarea para el jueves. Sí habrá evaluación diaria.
</div>
