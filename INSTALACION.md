# Guía de instalación

Esta guía asume que partes desde cero. Si ya tienes Python y Git instalados,
ve directamente a [Clonar el repositorio](#3-clonar-el-repositorio).

---

## 1. Instalar Python

1. Ve a [python.org/downloads](https://www.python.org/downloads/)
2. Descarga la versión más reciente de Python 3 (3.12 o superior)
3. Ejecuta el instalador
4. **Importante:** en la primera pantalla del instalador marca la casilla
   **"Add Python to PATH"** antes de hacer click en Install

Para verificar que quedó bien instalado, abre una terminal y escribe:

```bash
python --version
```

Deberías ver algo como `Python 3.12.x`.

---

## 2. Instalar Git

Git es el sistema de control de versiones que permite clonar el repositorio.

1. Ve a [git-scm.com/downloads](https://git-scm.com/downloads)
2. Descarga el instalador para tu sistema operativo
3. Ejecuta el instalador con las opciones por defecto

Para verificar:

```bash
git --version
```

Deberías ver algo como `git version 2.x.x`.

---

## 3. Clonar el repositorio

Abre una terminal, **navega a la carpeta donde quieres guardar** el curso y ejecuta:

```bash
git clone https://github.com/Fato89/FLCS_ESEDA.git
cd FLCS_ESEDA
```
---
## 4. Crear un entorno virtual

Un entorno virtual es una instalación de Python aislada para este proyecto.
Esto evita conflictos entre las librerías de este curso y las de otros proyectos
que tengas en tu computador.

Dentro de la carpeta del repositorio ejecuta:

```bash
python -m venv venv
```

Esto crea una carpeta llamada `venv` con una copia limpia de Python.
Ahora actívalo:

**Windows:**
```bash
venv\Scripts\activate
```

**Mac / Linux:**
```bash
source venv/bin/activate
```

Sabrás que está activo porque el nombre `(venv)` aparece al inicio
de la línea en tu terminal:

```bash
(venv) C:\Users\tu_ruta\FLCS_ESEDA>
```

Para desactivarlo cuando termines de trabajar:

```bash
deactivate
```

> Cada vez que abras una terminal nueva para trabajar con el curso, recuerda activar el entorno antes de abrir Jupyter.


---

## 5. Instalar las dependencias de Python

Dentro de la carpeta del repositorio ejecuta:

```bash
pip install -r requirements.txt
```

Este comando instala todas las librerías necesarias para las 8 sesiones del curso.
La instalación puede tomar unos minutos dependiendo de tu conexión.

Para verificar que todo quedó instalado:

```bash
pip list
```

Deberías ver en la lista librerías como `polars`, `pyreadr`, `scipy`,
`matplotlib`, `networkx`, entre otras.

---

## 6. Descargar los datos de la ENDI

Las bases de datos no están en el repositorio por su tamaño. Encuéntralas en:

```
Materiales/Insumos/ENDI/links_descarga.txt
```

Una vez descargadas, coloca los archivos `.rds` en:

```
Materiales/Insumos/ENDI/BDD_ENDI_R2_rds/
```

---

## 7. Abrir Jupyter

Para abrir el entorno de trabajo ejecuta:

```bash
jupyter notebook
```
Se abrirá una ventana en tu navegador. Navega a `Clases/Clase 1/` y abre el notebook de la sesión.

Puedes cargarlo en https://colab.research.google.com/ y utilizar el procesamiento en la nube o cualquier IDE de tu preferencia (por ejemplo: yo uso VSCode)

---

## 7. Verificar que todo funciona

Ejecuta la primera celda del notebook de la sesión 1. Si no hay errores en
la carga de la tabla `personas`, el entorno está listo.

---

## Problemas frecuentes

**`python` no se reconoce como comando**  
Reinstala Python y asegúrate de marcar "Add Python to PATH" durante la instalación.
En Windows también puedes intentar con `py` en lugar de `python`.

**`pip install` falla con errores de permisos**  
Agrega `--user` al comando:

```bash
pip install --user -r requirements.txt
```

**`jupyter notebook` no abre el navegador**  
Copia la URL que aparece en la terminal (empieza con `http://127.0.0.1:8888/`)
y pégala manualmente en tu navegador.