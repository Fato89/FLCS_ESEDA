---
marp: true
theme: flacso
paginate: true
---

<!-- _class: portada -->

<img src="../estilos/logo_flacso.png" class="logo" />

<div class="tag">Sesión 7: Inferencia estadística con la ENDI</div>

# Pruebas de hipótesis y bootstrapping

<p>Fausto Jácome Pérez<br>FLACSO Ecuador</p>


---

## ¿Dónde estamos?

<div class="cols3">
  <div class="card">
    <div class="num">6</div>
    <div class="lbl">Tarea anterior</div>
    <br>
    Calculamos indicadores oficiales de la ENDI con Polars: desnutrición crónica, puntaje Z y matriz de confusión.
  </div>
  <div class="card" style="border-left-color:var(--accent)">
    <div class="num">7</div>
    <div class="lbl">Esta sesión</div>
    <br>
    Pruebas de hipótesis con y sin diseño muestral. Chi-cuadrado, t-test y bootstrapping con <code>scipy</code> y <code>svy</code>.
  </div>
  <div class="card">
    <div class="num">8</div>
    <div class="lbl">Próxima sesión</div>
    <br>
    Gráficos
  </div>
</div>

<div class="box">
Hoy no solo calculamos: aprendemos a distinguir entre lo que es ruido aleatorio y lo que es evidencia estadística real.
</div>

---

<!-- _class: seccion -->

## Parte 1: El diseño muestral de la ENDI

<p>Por qué no todas las observaciones valen lo mismo</p>

---

## La ENDI no es una muestra simple

La ENDI usa un diseño **bietápico estratificado por conglomerados**. No selecciona personas al azar del padrón nacional: selecciona primero sectores geográficos y luego viviendas dentro de esos sectores.

<div class="cols">
<div>

**Etapa 1: selección de UPM**

Se divide el territorio en **Unidades Primarias de Muestreo** (UPM): conjuntos de manzanas o sectores dispersos con un mínimo de viviendas ocupadas.

Se seleccionan UPM con **probabilidad proporcional al tamaño** dentro de cada estrato.

</div>
<div>

**Etapa 2: selección de viviendas**

Dentro de cada UPM seleccionada se enlistan todas las viviendas y se seleccionan **8 viviendas con niños menores de 5 años** de forma sistemática aleatoria.

</div>
</div>

<div class="box">
En total: 2.836 UPM enlistadas, 22.250 viviendas investigadas, 23.187 niños menores de 5 años encuestados.
</div>

---

## UPM: viviendas y sectores en el territorio


![bg center 45%](sectores_viviendas.png)

---

## Estratificación

El territorio se divide en **estratos** antes de seleccionar las UPM. Cada UPM pertenece a exactamente un estrato.

<div class="cols">
<div>

**Criterios de estratificación**

- Provincia y área (urbano / rural)
- Parroquias principales: Quito, Guayaquil, Cuenca, Ambato y Machala reciben tratamiento propio
- Dentro de cada división geográfica, las UPM se clasifican en hasta 3 grupos según características socioeconómicas

</div>
<div>

**Para qué sirve**

- Garantizar representatividad en cada dominio de diseño
- Reducir la varianza de los estimadores al agrupar UPM similares
- Permitir desagregación a nivel provincial con los 12 meses de levantamiento acumulados

</div>
</div>

<div class="box warn">
La ENDI tiene 147 estratos efectivos en los datos. El manual técnico describe 153 teóricos; la diferencia se debe a que algunos estratos muy pequeños se fusionaron.
</div>

---

## El factor de expansión

Cada persona en la muestra **representa a un número distinto de personas** en la población. Ese número es el **factor de expansión** (`fexp`).

<div class="cols">
<div>

**Cómo se construye**

$$d_n = f_n \cdot d_3$$

donde $d_3$ acumula los inversos de las probabilidades de selección en ambas etapas, más ajustes por:

- UPM no investigadas
- Viviendas con elegibilidad desconocida
- No respuesta

$f_n$ es el factor de normalización que hace que los pesos sumen el tamaño de muestra.

</div>
<div>

**Qué implica**

- Una persona con `fexp = 8` representa 8 veces más que una con `fexp = 1`
- La suma de todos los `fexp` es el tamaño de muestra (22.331), no la población
- Los `fexp` se usan para estimar **proporciones y medias**, no totales directamente

</div>
</div>

---

## Por qué importa en la inferencia

Si ignoramos el diseño y tratamos cada observación como si tuviera el mismo peso:

<div class="cols">
<div>

**Lo que asume `scipy`**

- Cada observación fue seleccionada con **igual probabilidad**
- Las observaciones son **independientes** entre sí
- Equivale a asumir muestreo aleatorio simple

</div>
<div>

**Lo que tiene la ENDI**

- Las personas dentro de la misma UPM se parecen más entre sí (correlación intraclúster)
- Las probabilidades de selección varían entre estratos y áreas
- Hay dos etapas de muestreo

</div>
</div>

<div class="box warn">
Ignorar el diseño subestima los errores estándar. Las pruebas se vuelven demasiado optimistas: encontramos diferencias significativas que en realidad no lo son. <code>svy</code> corrige esto con linealización de Taylor.
</div>

---

## Varianza bajo diseño complejo: linealización de Taylor

Para un estimador de total $\hat{Y}$ bajo diseño bietápico estratificado con $L$ estratos:

$$\hat{V}(\hat{Y}) = \sum_{h=1}^{L} (1 - f_h) \frac{n_h}{n_h - 1} \sum_{i=1}^{n_h} (y_{hi} - \bar{y}_h)^2$$

donde:

- $f_h$ = fracción de muestreo en el estrato $h$ (generalmente despreciable en encuestas grandes)
- $n_h$ = número de UPM seleccionadas en el estrato $h$
- $y_{hi}$ = total ponderado de la variable en la UPM $i$ del estrato $h$: $y_{hi} = \sum_{j=1}^{m_{hi}} w_{hij} y_{hij}$
- $\bar{y}_h$ = media de los totales de UPM en el estrato $h$: $\bar{y}_h = \frac{1}{n_h} \sum_{i=1}^{n_h} y_{hi}$

<div class="box">
La varianza depende de cuánto varían los <strong>totales ponderados entre UPM dentro de cada estrato</strong>. Si todas las UPM de un estrato tienen valores similares, la varianza es pequeña. La estratificación reduce la varianza precisamente porque agrupa UPM similares.
</div>

---

## Declarar el diseño en `svy`

```python
import svy

diseno = svy.Design(
    stratum = "estrato",   # estratos de muestreo
    psu     = "id_upm",   # unidad primaria de muestreo
    wgt     = "fexp",     # factor de expansión normalizado
)

muestra = svy.Sample(personas).set_design(diseno)
print(muestra)
```

<div class="box">
Las tres variables clave vienen del documento de diseño muestral del INEC: <code>estrato</code>, <code>id_upm</code> y <code>fexp</code>. Sin declararlas correctamente, cualquier intervalo de confianza o prueba de hipótesis será incorrecto.
</div>

---

<!-- _class: seccion -->

## Parte 2: Pruebas de hipótesis

<p>La lógica general y las pruebas más usadas</p>

---

## La lógica de una prueba de hipótesis

Una prueba de hipótesis responde: *¿es posible que lo que observo sea simplemente ruido aleatorio?*

<div class="cols">
<div>

**Las dos hipótesis**

- **$H_0$ (nula):** no hay diferencia. Lo observado es producto del azar.
- **$H_1$ (alternativa):** sí hay diferencia real en la población.

Calculamos un **estadístico de prueba** y obtenemos el **p-valor**: probabilidad de observar un resultado tan extremo *suponiendo que $H_0$ es cierta*.

</div>
<div>

**Los dos tipos de error**

| | $H_0$ verdadera | $H_0$ falsa |
|---|---|---|
| **Rechazamos $H_0$** | Error tipo I | Correcto |
| **No rechazamos $H_0$** | Correcto | Error tipo II |

$\alpha = 0.05$ fija el límite del error tipo I: aceptamos equivocarnos el 5% de las veces cuando $H_0$ es verdadera.

</div>
</div>

---

## Prueba de normalidad: Shapiro-Wilk

Antes de elegir entre prueba paramétrica y no paramétrica, verificamos si los datos se distribuyen normalmente.

**Shapiro-Wilk** es potente para muestras pequeñas (n < 50):

$$W = \frac{\left(\sum_{i=1}^{n} a_i x_{(i)}\right)^2}{\sum_{i=1}^{n} (x_i - \bar{x})^2}$$

donde $a_i$ son coeficientes precalculados que dependen del tamaño de muestra $n$ y $x_{(i)}$ son los valores ordenados.

- $H_0$: los datos provienen de una distribución normal.
- $H_1$: los datos no provienen de una distribución normal.

<div class="box warn">
Con muestras grandes (n > 5.000) Shapiro-Wilk rechaza H0 casi siempre por desviaciones mínimas sin importancia práctica. Para muestras grandes usar Kolmogorov-Smirnov o apoyarse en el teorema central del límite.
</div>

---

## Prueba de normalidad: Kolmogorov-Smirnov

**Kolmogorov-Smirnov** compara la distribución empírica con la normal teórica de misma media y desviación estándar:

$$D = \sup_x |F_n(x) - F(x)|$$

donde $F_n(x)$ es la distribución empírica acumulada y $F(x)$ es la normal teórica.

- $H_0$: los datos provienen de una distribución normal.
- $H_1$: los datos no provienen de una distribución normal.

```python
stat_ks, p_ks = stats.kstest(
    talla, "norm",
    args=(talla.mean(), talla.std())
)
```

<div class="box">
Con los datos de la ENDI: W = 0.9458 (p = 0.0231) en Shapiro-Wilk y D = 0.0638 (p &lt; 0.0001) en KS. Rechazamos H0 en ambos casos.
</div>

---

## Chi-cuadrado: asociación entre variables categóricas

¿Existe asociación entre el área (urbano/rural) y la desnutrición crónica?

$$\chi^2 = \sum_{i,j} \frac{(O_{ij} - E_{ij})^2}{E_{ij}}$$

donde $E_{ij} = \frac{(\text{total fila}_i)(\text{total columna}_j)}{n}$ son las frecuencias esperadas bajo independencia.

- $H_0$: la proporción de desnutrición crónica es igual en ambas áreas.
- $H_1$: existe asociación entre el área y la desnutrición crónica.

<div class="cols">
<div>

**Sin diseño (`scipy`)**

```python
chi2, p, gl, esperados = stats.chi2_contingency(matriz)
# Chi² = 272.17, p < 0.0001
```

</div>
<div>

**Con diseño (`svy`): test de Wald**

$$t = \frac{\hat{p}_1 - \hat{p}_2}{\sqrt{SE(\hat{p}_1)^2 + SE(\hat{p}_2)^2}}$$

```python
# rural: 21.2%  urbano: 15.4%
# t = 6.34,  p < 0.0001
```

</div>
</div>

---

## T-test: diferencia de medias entre dos grupos

¿La talla media de los niños difiere de la de las niñas?

$$t = \frac{\bar{X}_1 - \bar{X}_2}{\sqrt{\dfrac{s_1^2}{n_1} + \dfrac{s_2^2}{n_2}}}$$

La versión de **Welch** (`equal_var=False`) no asume varianzas iguales.

Con diseño muestral, el estadístico de **Wald** usa los errores estándar corregidos de `svy`:

$$t_{\text{diseño}} = \frac{\hat{\mu}_1 - \hat{\mu}_2}{\sqrt{\widehat{SE}(\hat{\mu}_1)^2 + \widehat{SE}(\hat{\mu}_2)^2}}$$

<div class="box">
El estadístico tiene la misma forma en ambos casos. La diferencia está en cómo se calcula el error estándar: <code>scipy</code> asume muestreo aleatorio simple; <code>svy</code> incorpora estratos y conglomerados.
</div>


---

<!-- _class: seccion -->

## Parte 3: Bootstrapping

<p>Estimar variabilidad sin asumir distribución teórica</p>

---

## ¿Qué es el bootstrapping?

El bootstrapping estima la variabilidad de cualquier estadístico **remuestreando los datos con reemplazo**, sin asumir ninguna distribución teórica.

1. Tienes $n$ observaciones en tu muestra original. Es tu única ventana a la población.
2. Extraes con reemplazo $n$ observaciones. Cada réplica es una muestra alternativa posible.
3. Calculas el estadístico de interés en esa réplica.
4. Repites el proceso $B$ veces.
5. La dispersión de los $B$ estadísticos aproxima la varianza muestral real.

<div class="box">
La varianza bootstrap se calcula como:

$$\widehat{Var}_{boot}(\hat{\theta}) = \frac{1}{B-1} \sum_{b=1}^{B} \left(\hat{\theta}^{(b)} - \bar{\hat{\theta}}\right)^2$$

</div>

---

## Bootstrap para muestras complejas

Con datos de encuestas con diseño complejo, el bootstrap estándar (remuestrear personas) **ignora la estructura de conglomerados** y subestima la varianza.

El bootstrap correcto remuestrea **UPM dentro de cada estrato**:

```python
for b in range(B):
    replicas = []
    for estrato in estratos:
        upms_estrato = datos_boot.filter(
            pl.col("estrato") == estrato
        )["id_upm"].unique().to_list()

        # Remuestrear UPM con reemplazo dentro del estrato
        upms_boot = np.random.choice(upms_estrato, size=len(upms_estrato), replace=True)
        for upm in upms_boot:
            replicas.append(datos_boot.filter(pl.col("id_upm") == upm))

    replica_df = pl.concat(replicas)
    # Prevalencia ponderada en esta réplica
    prev_boot[b] = (replica_df["dcronica"] * replica_df["fexp"]).sum() / replica_df["fexp"].sum()
```

---

## Bootstrap vs. linealización de Taylor

Ambos métodos estiman la misma cantidad: la varianza del estimador bajo el diseño muestral.

<div class="cols">
<div>

**Linealización de Taylor (`svy`)**

- Método analítico: usa las derivadas del estimador
- Rápido, una sola pasada por los datos
- Es el método oficial del INEC para la ENDI
- Funciona bien para proporciones y medias
- Puede ser complicado para estadísticos no estándar

</div>
<div>

**Bootstrap de UPM**

- Método de replicación: no asume forma funcional
- Computacionalmente costoso (B pasadas)
- Funciona para cualquier estadístico, por complejo que sea
- Permite verificar los resultados analíticos
- Preferido cuando el estimador es difícil de linealizar

</div>
</div>

<div class="box verde">
En la práctica ambos dan resultados muy similares para proporciones y medias. La diferencia relativa entre varianzas suele ser menor al 5%.
</div>

---

<!-- _class: seccion -->

## Parte 4: Programación

<p>De la teoría al código con <code>polars</code> y <code>svy</code></p>

---

## Estimaciones con `svy`

```python
# Proporción de desnutrición crónica por área
est_area = muestra.estimation.prop("dcronica", by="area")
print(est_area)

# Estimate: PROP (TAYLOR)
#   area    dcronica     est      se     lci     uci  cv (%)
#   rural   1         0.2119  0.0074  0.1978  0.2267  3.49
#   urbano  1         0.1537  0.0055  0.1433  0.1647  3.55

# Media de talla por sexo
est_sexo = muestra.estimation.mean("talla", by="sexo")
print(est_sexo)
```

<div class="box">
<code>estimation.prop()</code> devuelve la proporción de cada nivel de la variable. <code>estimation.mean()</code> devuelve la media ponderada. Ambos usan linealización de Taylor para el error estándar.
</div>

---

## Test de Wald con `svy`

```python
# Extraer estimaciones por grupo
e = {r.by_level[0]: r for r in est_sexo.estimates}

est_h, se_h = e["hombre"].est, e["hombre"].se
est_m, se_m = e["mujer"].est,  e["mujer"].se

# Estadístico de Wald
diff    = est_h - est_m
se_diff = np.sqrt(se_h**2 + se_m**2)
t_wald  = diff / se_diff

# Grados de libertad: n_strata - 1
gl     = est_sexo.n_strata - 1
p_val  = 2 * stats.t.sf(abs(t_wald), df=gl)

print(f"t = {t_wald:.4f},  p = {p_val:.4f}")
```

<div class="box warn">
Los resultados del Wald y del t-test sin diseño pueden diferir notablemente. El error estándar con diseño es mayor porque incorpora la correlación intraclúster.
</div>

---

## Instalación

**Entorno local**

```
cd <ruta/a carpeta/de trabajo>
.\venv\Scripts\activate
pip install -r requirements.txt
```

Si ya tenías los paquetes anteriores instalados, solo agrega:

```
pip install svy
```

**Google Colab**

```python
!pip install polars pyreadr svy
```

---

<!-- _class: cierre -->

## Resumen de la sesión

<div class="cols">
<div>

**Lo que aprendimos**

- La ENDI tiene diseño bietápico estratificado: ignorarlo produce errores estándar incorrectos
- Las pruebas clásicas de `scipy` asumen muestreo aleatorio simple
- `svy` incorpora estratos, conglomerados y pesos con linealización de Taylor
- El bootstrap de UPM reproduce la varianza analítica para cualquier estadístico

</div>
<div>

**Herramientas usadas**

<span class="chip">polars</span>
<span class="chip">scipy.stats</span>
<span class="chip">svy</span>
<span class="chip">numpy</span>

**Pruebas cubiertas**

- Shapiro-Wilk
- KS
- Chi2
- T-test / Wald
- Bootstrap

</div>
</div>

<div class="box">
La próxima sesión: Gráficos y más gráficos.
</div>
