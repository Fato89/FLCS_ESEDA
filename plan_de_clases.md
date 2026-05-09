# Temario Depurado — Sesiones 1 a 8
### Estructura Social y Espacial de los Datos y su Arquitectura: Datos semi estructurados y estructurados

Docente: Fausto Jácome Pérez  
Datasets: [ENDI](https://www.ecuadorencifras.gob.ec/encuesta-nacional-sobre-desnutricion-infantil/) y 

---

## Principios transversales del curso

- **Hilo narrativo -> técnico**: cada sesión parte de una pregunta sobre desnutrición infantil (ENDI) y llega a la herramienta como respuesta generalizable.
- **Piedra Rosetta**: las operaciones se muestran en Python (Polars), R y SQL lado a lado para que el estudiante entienda que los conceptos son independientes de la herramienta.
- **R**: solo se muestran los códigos como referencia; no se corre en clase.
- **Sesiones pares (2, 4, 6, 8)**: tienen tarea para el fin de semana. Las sesiones impares (1, 3, 5, 7) no tienen tarea porque son martes y el jueves es la segunda clase de la semana.
- **Evaluación**: el trabajo final es el EDA completo. Las sesiones 7 y 8 (redes) son módulo autocontenido sin evaluación más allá del trabajo semanal.

---

## Sesión 1 — Ingesta de Datos y Arquitectura de Tablas

**Hilo narrativo:** ¿Qué mide la ENDI y por qué sus datos están estructurados en múltiples tablas?

### Núcleo conceptual
- Qué es una encuesta estructurada y por qué viene separada en tablas (Vivienda, Hogar, Personas)
- Qué es un esquema relacional — la idea, no la implementación
- Ingesta como primer paso del flujo de datos

### Piedra Rosetta — primera aparición
- Carga desde CSV / conversión desde RDS o Excel
- La misma operación en Polars, R y SQL lado a lado
- El estudiante practica solo en Polars hoy

### Exploración inicial
- Variables y sus tipos (numérico, categórico) — concepto primero, luego cómo se ve en Polars y cómo se vería en Postgres
- Nombres de columnas asociados a sus tipos
- Resumen de variables numéricas relevantes (media, mín, máx, distribución básica)
- Categorías de variables categóricas
- Datos perdidos (conteo inicial)

### Lo que no entra hoy
- Configuración real de PostgreSQL -> sesión 3
- Cualquier transformación -> sesión 2

### Tarea
Sin tarea (sesión de martes).

---

## Sesión 2 — Data Wrangling y Pivots

**Hilo narrativo:** Tengo los datos cargados, ¿cómo los preparo para responder una pregunta sobre desnutrición?

### Piedra Rosetta
- Filtros y selección
- Recodificación de variables
- Reshaping — Long vs Wide: concepto primero (¿cuándo necesito cada formato y por qué?), luego implementación en Polars, R y SQL lado a lado

### Práctica en clase
- Ejercicio guiado sobre la ENDI

### Tarea para el fin de semana
- Ejercicio sobre la ENDI aplicando los tres gestos: filtrar, recodificar y reshapear
- *(Consigna específica a definir cuando se diseñen los ejercicios)*

---

## Sesión 3 — Funciones de Ventana

**Hilo narrativo:** Muy breve (~5 minutos) — ¿qué es una función de ventana y en qué se diferencia de un GROUP BY? El problema del doble conteo en encuestas multinivel.

### SQL entra de pleno
- OVER, PARTITION BY, ORDER BY dentro de la ventana
- Piedra Rosetta: el mismo ejercicio en SQL, Polars y R

### Formato de la sesión
- Dominada por ejercicios demostrativos progresivos — el profesor los construye en vivo

### Lo que se difiere
- Cálculo de un indicador real de la ENDI -> sesión 4 (y tarea de fin de semana)

### Tarea
Sin tarea (sesión de martes).

---

## Sesión 4 — Integración y Consultas Complejas

**Hilo narrativo:** Tengo mis datos limpios y transformados, ¿cómo los uno y cómo me aseguro de que mis resultados representen a la población?

### Núcleo conceptual
- Joins multinivel: ¿por qué la ENDI separa Vivienda, Hogar y Personas? — narrativo primero
- Factores de expansión:
  - Qué son y por qué existen
  - Errores comunes: no ponderar los indicadores; ponderar a un nivel geográfico más allá de la representatividad estadística (ej. cantonal cuando el diseño muestral no lo permite)
  - Visualización del diseño muestral con mapa del Ecuador, apoyado en el documento de muestreo de la ENDI

### Piedra Rosetta
- Joins en SQL, Polars y R
- CTEs (Common Table Expressions) como buena práctica de legibilidad — se muestra, no se evalúa

### Tarea para el fin de semana
- Cálculo de un indicador real de la ENDI con función de ventana, correctamente ponderado
- *(Consigna específica a definir cuando se diseñen los ejercicios)*

---

## Sesión 5 — Inferencia y Simulación

**Hilo narrativo:** Tengo mis indicadores calculados, ¿cómo sé si las diferencias que observo son reales o producto del azar?

### Formato: cheatsheet de inferencia
Para cada test: ¿qué mide y cuándo se usa? -> supuestos básicos (sin derivación matemática) -> función en Python y R -> ejemplo guiado con la ENDI.

### Tests
| Test | Ejemplo con la ENDI |
|---|---|
| T-test | Diferencia de talla entre niños y niñas |
| Chi-cuadrado | Asociación entre variables categóricas |
| Mann-Whitney | Alternativa no paramétrica al T-test |
| Kolmogorov-Smirnov | Comparación de distribuciones |
| Bootstrapping | Reproducir el resultado del T-test por remuestreo — intuición de que converge al mismo lugar |

### Lo que no entra
- Derivación matemática de ningún test
- Potencia estadística, errores tipo I/II

### Tarea
Sin tarea (sesión de martes).

---

## Sesión 6 — EDA y Visualización

**Hilo narrativo:** Antes de concluir, ¿entiendo realmente mis datos?

### EDA como proceso completo

1. **Descriptivos** — retomamos sesión 1: resumen numérico, categorías, distribuciones básicas, ahora con intención analítica
2. **Missings** — conteo, patrones, visualización (missingno o similar). ¿Son aleatorios o sistemáticos? Eso importa con encuestas.
3. **Outliers y sesgos** — detección visual y numérica

### Visualización por tipo de dato
Mismo enfoque que inferencia: tipo de dato -> cuándo usar qué -> buenas prácticas -> malas prácticas -> ejemplo con la ENDI en Python.

| Tipo | Gráficos |
|---|---|
| Numérico univariado | Histograma, boxplot, violín |
| Categórico | Barras, treemap |
| Numérico-numérico | Dispersión |
| Numérico-categórico | Boxplot agrupado, violín agrupado |
| Distribuciones comparadas | Density plot |
| Missings | Heatmap de missings |

### Buenas y malas prácticas
- Simplicidad y limpieza visual
- Demasiadas dimensiones en un solo gráfico
- Ejes truncados y escalas engañosas

### Herramientas
- Python: matplotlib / seaborn (se corre en clase)
- R: solo código de referencia, no se corre

### Tarea para el fin de semana
- EDA completo sobre variables relevantes de la ENDI
- *(Consigna específica a definir cuando se diseñen los ejercicios)*

---

## Sesión 7 — Introducción a Redes y Topología

> Módulo autocontenido. Sin evaluación más allá del trabajo semanal. Dataset: Panama Papers.

**Hilo narrativo:** ¿Cómo se esconde dinero y cómo los datos nos permiten verlo?

### Núcleo conceptual
- ¿Qué es un grafo? Nodos, aristas, dirección, peso — intuición primero
- ¿Cuándo un problema es un problema de redes? — casos de uso reales
- **Tabular vs. grafo como representaciones abstractas intercambiables**: el mismo fenómeno puede vivir en una tabla o en un grafo dependiendo de la pregunta. La matriz de adyacencia como puente entre los dos mundos. Conexión con el reshape de la sesión 2.

### Técnico
- Extracción desde Neo4j con Cypher — demostración del profesor, no se espera que el estudiante lo replique
- Construcción de una red en NetworkX con los Panama Papers
- Visualización básica de la red

### Tarea
Sin tarea (sesión de martes).

---

## Sesión 8 — Métricas de Red y Comunidades

> Módulo autocontenido. Sin evaluación más allá del trabajo semanal. Dataset: Panama Papers.

**Hilo narrativo:** En los Panama Papers, ¿quiénes son los actores clave y cómo se agrupan?

### Núcleo conceptual — métricas como preguntas
| Métrica | Pregunta que responde |
|---|---|
| Centralidad de grado | ¿Quién tiene más conexiones? |
| Cercanía | ¿Quién llega más rápido a todos? |
| Intermediación | ¿Quién controla el flujo de información? |
| Detección de comunidades | ¿Qué grupos emergen naturalmente? |

### Técnico
- Implementación en NetworkX
- Visualización de comunidades

### Cierre del curso (tramo Fausto)
- Mirada panorámica de las 8 sesiones — qué aprendimos, cómo se conecta todo

### Tarea para el fin de semana
- *(Por definir — módulo de redes)*

---

## Pendientes

- [ ] Diseñar los ejercicios específicos con la ENDI para cada sesión (requiere cargar los metadatos de la ENDI al chat)
- [ ] Definir la consigna de la tarea de sesión 8 (módulo de redes)
- [ ] Diseñar las presentaciones (estructura: ~1h instrucción + ~1h práctica)
- [ ] Definir las tareas diarias vinculadas al proyecto final
- [ ] Crear la guía para el estudiante en Markdown para GitHub
- [ ] Crear el documento de nivelación (videos, glosario, lecturas previas, visualizadores) para estudiantes sin background cuantitativo