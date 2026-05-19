---
marp: true
theme: flacso
paginate: true
---

<!-- _class: portada -->

<img src="../estilos/logo_flacso.png" class="logo" />

<div class="tag">Sesión 1 · Mayo 2026</div>

# Estructura Social y Espacial<br>de los Datos y su Arquitectura
### Primer tramo: Datos semiestructurados y estructurados

<p>Fausto Jácome Pérez<br>FLACSO Ecuador</p>
<p>Laboratorio de Cómputo 301 - Martes y jueves, 07:00–09:00</p>

---

## Quién está frente a ustedes



<div class="cols">
<div>

**Formación**
- Economía - PUCE
- Maestría en Economía del Desarrollo - FLACSO
- Maestría en Ciencia de Datos - ITBA

**Herramientas**
<span class="chip">Python</span><span class="chip">R</span><span class="chip">SQL</span><span class="chip">PostgreSQL</span><span class="chip">PostGIS</span>

</div>
<div>

**Experiencia relevante para este curso**
- INEC - estadísticas sociales y diseño de indicadores
- BID / STECSDI - sistemas de seguimiento nominal, ETLs, datos de desnutrición infantil
- Banco Central del Ecuador - ETL geoespacial con PostgreSQL, R y Python

La materia que vamos a ver no es abstracta: es lo que se usa a diario y ocupa el 80% o más del trabajo.

</div>
</div>

---

## ¿De qué trata este tramo?

<div class="box">
Los datos no vienen listos. Vienen sucios, fragmentados, en múltiples formatos, con estructuras complejas. Este tramo enseña a <strong>tratar esa complejidad</strong>.
</div>

**¿Qué aprenderán en las sesiones 1–8?**

Transitar el ciclo completo del dato estructurado conocido como ETL (extract->transform->load) y un poco más allá:

> **Ingestión → Transformación → Integración → Análisis → Visualización → Redes**

**Dataset central: ENDI** *(Encuesta Nacional de Desnutrición Infantil, Ecuador 2023–24)*

Usamos la ENDI porque es **actual**, tiene la **complejidad estructural** (6 tablas relacionales, factores de expansión, múltiples unidades de análisis) y permite ilustrar todos los conceptos del curso con datos reales y relevantes.

---

## Mapa del tramo: 8 sesiones



| Ses. | Fecha | Tema | Tarea |
|:---:|---|---|:---:|
| 1 | 19 may | **Ingesta y arquitectura de tablas** | <span class="notarea">-</span> |
| 2 | 21 may | **Data wrangling y pivots** | <span class="tarea">✓</span> |
| 3 | 26 may | **Funciones de ventana** | <span class="notarea">-</span> |
| 4 | 28 may | **Integración y consultas complejas** | <span class="tarea">✓</span> |
| 5 | 02 jun | **Inferencia y simulación** | <span class="notarea">-</span> |
| 6 | 09 jun | **EDA y visualización** | <span class="tarea">✓</span> |
| 7 | 04 jun | **Introducción a redes** | <span class="notarea">-</span> |
| 8 | 09 jun | **Métricas de red y comunidades** | <span class="tarea">✓*</span> |

<div class="box warn">
Las tareas siempre son de <strong>jueves para el fin de semana</strong>. El producto final del tramo es un <strong>Análisis Exploratorio de Datos (EDA) completo</strong>.
</div>

<small>\* se entrega el trabajo práctico de las sesiones 1-6</small>

---

## Cómo se evalúa el tramo

<div class="cols3">

<div class="card accent">
<div class="num or">20%</div>
<div class="lbl">Evaluación diaria</div>
<br>
5 minutos al inicio de cada clase. Una persona seleccionada <strong>al azar</strong> responde preguntas sobre la sesión anterior. El puntaje representa a toda la clase.

*Compartido con el tramo del Prof. Vic Morales.*
</div>

<div class="card accent">
<div class="num or">40%</div>
<div class="lbl">Trabajo práctico</div>
<br>
Informe en <strong>Jupyter Notebook</strong> que demuestra el manejo de datos del tramo 1 (sesiones 1–8). Se entrega al finalizar este tramo.

*Exclusivo de este tramo.*
</div>

<div class="card">
<div class="num">40%</div>
<div class="lbl">Proyecto final</div>
<br>
Corresponde al tramo del Prof. Víctor Morales (Ciencia de Datos Espacial, sesiones 9–16).

*No aplica en este tramo.*
</div>

</div>

<div class="box" style="margin-top:20px; font-size:17px;">
La <strong>evaluación diaria es colectiva</strong>: si decide no dar la evaluación, puede renunciar a su nota y pasar a un compañero la responsabilidad.
</div>

---

## Herramientas del tramo

<div class="cols">
<div>

**Lo que correremos en clase**

<span class="chip">Python 3.x</span><span class="chip">Polars</span><span class="chip">Jupyter Notebook</span>

Polars es la librería principal de manipulación de datos. Es moderna, rápida y tiene una sintaxis declarativa (dice qué hacer, no como hacerlo). La aprenderemos desde cero.

**Lo que se muestra como referencia**

<span class="chip">R + dplyr/tidyr</span><span class="chip">SQL</span>

No se corre en clase, pero verán el código equivalente. El objetivo es entender que los conceptos son independientes de la herramienta (**Piedra Rosetta**).

</div>
<div>

**Lo que llega en sesiones 3–4**

<span class="chip">PostgreSQL</span>

Una vez que tengan el contexto de Polars, pasamos a entornos relacionales reales.

**Lo que necesitan tener instalado hoy**

- Python 3.10+
- `pip install polars jupyter`
- Un editor: VSCode o JupyterLab

<div class="box warn" style="font-size:17px; margin-top:16px;">
Si tienen problemas de instalación, avisen <strong>antes del jueves</strong>.
</div>

</div>
</div>
