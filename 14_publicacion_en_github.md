# 14. Publicación en GitHub, paso a paso

[← `index.qmd` y estilos (13c)](13c_codigo_index_quarto.md) · [Índice](README.md) · [Siguiente: limitaciones →](15_limitaciones_y_extensiones.md)

Este capítulo documenta **cómo se publicó el proyecto, tal como ocurrió**: cada comando, qué hace,
qué respondió y por qué se hizo así. La primera publicación fue el **martes 22 de septiembre de 2026**
([14.3](#143-paso-1-revisar-qué-hay-instalado) a [14.11](#1411-paso-9-segundo-commit-y-la-liga-en-about)); la
**versión final** se entregó el **miércoles 30 de septiembre** ([14.12](#1412-la-versión-final-30-sep-2026)). Las horas
son del centro de México. Al final hay las equivalencias con lo visto en clase (RStudio, `gitcreds`, flujo de R), una
tabla de errores frecuentes y las preguntas que pueden hacer.

> **Versión que se explica:** la entregada (rama `main`, commit `e3bd43f`, 30-sep-2026). Las secciones 14.3 a 14.11
> cuentan lo que pasó el 22-sep, con los datos de entonces (por ejemplo, "15 cifras" y "13 gráficas"); el archivo del flujo
> ([14.9](#149-paso-7-github-actions-construye-y-publica-el-tablero)) se revisó el 3-oct-2026 contra el del repositorio
> entregado, y la sección 14.12 cuenta la versión final. Para este capítulo no se ejecutó nada: sólo se leyó el historial
> con `git log`.

## 14.1 Las cuatro piezas

La frase de la clase de GitHub Actions lo resume:

> **Git** guarda el historial del código, **GitHub** aloja el repositorio, **GitHub Actions**
> ejecuta el código y **GitHub Pages** publica el HTML generado.

```text
Tu computadora                    GitHub (la nube)
─────────────────                 ───────────────────────────────────────────────
06_proyecto/                      pitirringo/futbol-apuestas (repositorio público)
  código + datos + tablero          │
  │  git add / commit               │  cada push dispara el flujo (GitHub Actions):
  │  git push ───────────────────►  │  máquina Ubuntu → Python 3.10 + Quarto
  ▼                                 │  → quarto render → _site/index.html
historial local (.git/)             ▼
                                  GitHub Pages → https://pitirringo.github.io/futbol-apuestas/
```

### Vocabulario mínimo

| Término | Qué es | Analogía |
|---|---|---|
| **Repositorio (repo)** | Carpeta cuyo historial controla Git (vive en la subcarpeta oculta `.git/`) | Un expediente con todas sus versiones |
| **Commit** | Una "foto" del proyecto con autor, fecha, mensaje e identificador (*hash*, p. ej. `8b1fc83`) | Una versión guardada |
| **Área de preparación (*staging*)** | Lista de cambios que entrarán en el próximo commit (`git add` los pone ahí) | La caja donde acomodas lo que vas a fotografiar |
| **Rama (*branch*)** | Línea de historial; la principal se llama `main` | Una línea de tiempo |
| **Remoto (`origin`)** | La copia del repositorio en GitHub; `origin` es su apodo convencional | La nube |
| **Push / pull** | Subir commits al remoto / traer los del remoto | Sincronizar |
| **`.gitignore`** | Lista de archivos que Git debe ignorar | Lista de "no empacar" |
| **Workflow (flujo)** | Archivo YAML en `.github/workflows/` con los pasos que GitHub ejecuta solo | Una receta automática |
| **Runner** | La máquina virtual (Ubuntu) donde GitHub ejecuta el flujo | Una computadora prestada |
| **Artifact** | Archivos que un *job* entrega a otro (aquí, la carpeta `_site`) | Un paquete entre estaciones |

## 14.2 Cronología

| Hora | Paso | Resultado |
|---|---|---|
| 19:38 | 1. Revisar herramientas | Git 2.54, Git Credential Manager 2.7.3; la carpeta aún no era repositorio |
| 19:51 | 2. Identidad de Git | Nombre y correo configurados; acentos verificados |
| 19:52 | 3. Qué se sube | `.gitignore` y README; simulacro: 22 archivos entrarían |
| 19:56 | 4. Repositorio local y primer commit | Commit `1e1bb0a`, 22 archivos |
| 20:00 | 5. Repositorio vacío en GitHub + Pages | `pitirringo/futbol-apuestas`, público; Pages con fuente "GitHub Actions" |
| 20:03 | 6. Conectar y subir (`git push -u`) | Inicio de sesión en el navegador; rama `main` publicada |
| 20:03–20:05 | 7. El flujo construye y publica | *build* 1 min 17 s + *deploy* 30 s; sitio en línea |
| 20:06 | 8. Verificación | HTTP 200, 13 gráficas, 15/15 cifras ✓ calculadas en GitHub |
| 20:18 | 9. Segundo commit (URL y botón de GitHub) | Commit `42e80a5`, 5 archivos; liga del tablero en *About* |
| 21:00 | 10. Separar el material de defensa y reescribir el historial | Commit único `8b1fc83` (20 archivos), *force push* |
| 21:03 | 11. Verificación final | 1 solo commit público; 0 menciones a la defensa en el sitio |
| 22-sep | 12. Repositorio de la guía de estudio | `futbol-apuestas-defensa` (hoy en la cuenta `sufrucs`, público) |

Esta cronología es la del **22 de septiembre**. Después, el equipo siguió subiendo cambios a `main` y el flujo siguió
publicando el tablero: lo que pasó hasta la versión final del 30-sep (commit `e3bd43f`) está en
[14.12](#1412-la-versión-final-30-sep-2026).

---

## 14.3 Paso 1: revisar qué hay instalado

Antes de tocar nada se revisó el punto de partida, con comandos que solo leen:

```bash
git --version                        # git version 2.54.0.windows.1
git config --global user.name        # (vacío: faltaba configurar la identidad)
git config --global credential.helper
git config --system credential.helper   # manager  → Git Credential Manager
git credential-manager --version     # 2.7.3
```

**Qué se encontró y qué implicaba:**
- **Git** ya estaba instalado (Git para Windows 2.54).
- **Git Credential Manager (GCM)** viene incluido en Git para Windows y ya estaba activo
  (`credential.helper = manager`). Resuelve el inicio de sesión abriendo el navegador. **En clase se
  usó un Personal Access Token con `gitcreds`**; con GCM el resultado es el mismo (GitHub entrega
  un token que se guarda en Windows), pero nadie tiene que copiar ni pegar el token.
- **No estaba GitHub CLI (`gh`)**, así que el repositorio se crea desde la web.
- La carpeta `06_proyecto` **aún no era un repositorio**.

## 14.4 Paso 2: abrir la terminal y configurar la identidad

### Abrir PowerShell ya ubicada en la carpeta

1. Explorador de archivos (tecla Windows + E) → pegar la ruta
   `C:\Users\Lenovo\Videos\diplomado ciencia de datos\modulo 8\FYI\06_proyecto` en la barra de
   direcciones.
2. Clic otra vez en la barra, borrar la ruta, escribir `powershell` y presionar Enter.
3. La ventana muestra `PS C:\...\06_proyecto>`, lo que confirma que estás en la carpeta correcta.

Otras opciones: menú Inicio → "PowerShell" o "Git Bash" y luego `cd "ruta"` (con comillas, porque
la ruta tiene espacios), o la pestaña **Terminal** de RStudio (Tools → Terminal → New Terminal),
como en clase.

### Identidad (una sola vez por computadora)

```bash
git config --global user.name "César Emiliano Garduño Gutiérrez"
git config --global user.email "cesarsasuke11@gmail.com"
git config --global --list          # comprobar
```

- **Qué es:** el nombre y el correo que Git anota en cada commit. **No es la contraseña ni el
  inicio de sesión.**
- `--global` lo guarda para todos los repositorios de la computadora (en `C:\Users\Lenovo\.gitconfig`).
- **El correo debe ser el de la cuenta de GitHub** para que los commits se liguen al perfil. Como
  el repositorio es público, ese correo queda visible en el historial. Se usó el correo que el perfil
  ya mostraba públicamente. La alternativa es el correo privado de GitHub (Settings → Emails →
  *Keep my email addresses private*), con forma `12345678+usuario@users.noreply.github.com`.
- PowerShell a veces muestra `CÃ©sar` en vez de `César`: es solo la forma de mostrarlo. Se revisaron
  los bytes guardados y el nombre quedó bien en UTF-8.

## 14.5 Paso 3: decidir qué se sube

### `.gitignore` (raíz del repositorio)

```gitignore
# Instrucciones del curso (no son trabajo del equipo)
ProyectoModulo8.pdf

# Archivos generados: se reconstruyen al ejecutar el código o al renderizar el tablero
__pycache__/
*.pyc
.ipynb_checkpoints/
.quarto/
Dashboard-o-pagina/_site/

# Archivos del sistema operativo
.DS_Store
._*
Thumbs.db
desktop.ini
```

| Qué se excluye | Por qué |
|---|---|
| `ProyectoModulo8.pdf` | Son las instrucciones del curso, no trabajo del equipo; no nos corresponde publicarlas |
| `Dashboard-o-pagina/_site/` | El HTML generado (≈ 10 MB). **GitHub Actions lo vuelve a construir en cada push**, igual que en clase ("no queremos almacenar `_site`") |
| `__pycache__/`, `*.pyc`, `.quarto/`, `.ipynb_checkpoints/` | Archivos temporales de Python, Quarto y Jupyter |
| `.DS_Store`, `._*`, `Thumbs.db`, `desktop.ini` | Basura del sistema operativo (los `._*` vienen de las carpetas `__MACOSX`) |

**Qué sí se sube, y por qué:** el código del equipo **con sus dos CSV** (1.3 MB y 1.0 MB). El
servidor de GitHub necesita los datos para recalcular el tablero, y además cualquiera puede
reproducir el análisis. GitHub rechaza archivos de más de 100 MB; los nuestros están muy lejos de
ese límite.

La carpeta del tablero tiene además su propio `.gitignore` (`_site/`, `.quarto/`, `index.html`,
`index_files/`…), por si se usa como proyecto independiente.

### Simulacro antes de hacerlo de verdad

Para saber exactamente qué entraría, se ensayó en una **copia temporal** de la carpeta:

```bash
git add --dry-run .                  # (o -n) lista lo que se agregaría, sin agregar nada
git status --ignored --porcelain     # lista lo que se ignora (líneas con !!)
```

Resultado: **22 archivos** entrarían, y quedaban fuera `ProyectoModulo8.pdf`, `_site/`,
`.quarto/` y los `__pycache__/`. Así se comprueba el `.gitignore` sin arriesgar nada.

## 14.6 Paso 4: repositorio local y primer commit

Todo esto pasa **solo en la computadora**; todavía no se sube nada.

```bash
git init -b main
```

- Convierte la carpeta en repositorio: crea la carpeta oculta `.git/`, donde vive todo el historial.
  **Nunca se edita a mano.**
- `-b main` nombra `main` a la rama principal. En esta computadora Git trae la configuración
  `init.defaultBranch = master`, así que sin `-b main` la rama se habría llamado `master`. **Es lo
  mismo que hace `git branch -M main` en la guía de clase**, solo que desde el inicio.
- Respuesta: `Initialized empty Git repository in C:/Users/.../06_proyecto/.git/`.

```bash
git add .
```

- Pasa al área de preparación **todo lo de la carpeta y sus subcarpetas, excepto lo ignorado**.
- Avisos como `LF will be replaced by CRLF` son normales. Windows y Linux marcan el fin de línea de
  forma distinta y Git lo convierte solo; no afecta el contenido.

```bash
git status
```

- Revisión antes de guardar: bajo `Changes to be committed` aparecen, en verde, los 22 archivos; no
  aparecen ni el PDF ni `_site`.

```bash
git commit -m "Primer commit: codigo del equipo y dashboard del Modulo 8"
```

- Guarda la foto con autor, fecha y mensaje. El mensaje va **sin acentos a propósito**, para evitar
  problemas de codificación en PowerShell.
- Resultado: commit **`1e1bb0a`**, `22 files changed`, autor
  `César Emiliano Garduño Gutiérrez <cesarsasuke11@gmail.com>`.

**Las tres zonas de Git** (útil para cualquier pregunta sobre Git):

```text
carpeta de trabajo ──git add──► área de preparación ──git commit──► historial local ──git push──► GitHub
 (lo que editas)                 (lo que entrará)                    (.git/)                        (origin)
```

## 14.7 Paso 5: crear el repositorio vacío en GitHub y activar Pages (en Chrome)

1. github.com → botón verde **New**.
2. **Repository name:** `futbol-apuestas`. El nombre importa porque define la URL del tablero:
   `https://<usuario>.github.io/<repositorio>/` → `https://pitirringo.github.io/futbol-apuestas/`.
   Es corto, sin acentos ni espacios.
3. **Description:** "Proyecto Módulo 8: ¿anticipan las estadísticas el resultado de la Premier League
   mejor que el mercado de apuestas?"
4. **Visibility: Public.** Hay dos razones: las instrucciones piden una visualización "accesible
   mediante URL", y **en cuentas gratuitas GitHub Pages solo funciona con repositorios públicos**.
5. **No** agregar README, **no** agregar `.gitignore`, **no** elegir licencia. Ya existían en la
   computadora. Si GitHub crea un commit propio, los dos historiales no coinciden y el primer push
   se rechaza (`rejected … fetch first`). La guía de clase da la misma indicación.
6. **Create repository.** GitHub muestra una página "Quick setup" con comandos sugeridos. **No se
   usaron**, porque ya teníamos repositorio y commit.

**Activar Pages desde el principio:** en el repositorio, **Settings → Pages → Build and
deployment → Source → GitHub Actions**. Así el primer push publica el tablero a la primera. Sin
esto, el flujo falla en el paso de Pages.

## 14.8 Paso 6: conectar la carpeta con GitHub y subir

```bash
git remote add origin https://github.com/pitirringo/futbol-apuestas.git
git remote -v            # comprobar: dos líneas (fetch y push) con esa dirección
```

- Registra la dirección del repositorio de GitHub con el apodo `origin`. No sube nada todavía.

```bash
git push -u origin main
```

- Sube la rama `main` al remoto `origin`.
- `-u` (*upstream*) liga la rama local con la remota. Desde entonces basta con escribir `git push`
  o `git pull`, sin nada más.
- **Inicio de sesión (primera vez):** se abrió la ventana de **Git Credential Manager** → *Sign in
  with your browser* → en Chrome, autorizar a Git Credential Manager con la cuenta `pitirringo` →
  la subida continuó sola. El token queda guardado en el **Administrador de credenciales de
  Windows** (entrada `git:https://github.com`) y no se vuelve a pedir.
- **Nunca se escribe la contraseña de GitHub en la terminal.** GitHub dejó de aceptarla para Git en
  2021. Si la terminal pide usuario y contraseña en texto, el sistema de credenciales no está
  funcionando.

Respuesta:

```text
To https://github.com/pitirringo/futbol-apuestas.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

## 14.9 Paso 7: GitHub Actions construye y publica el tablero

En cuanto llegó el push, GitHub encontró `.github/workflows/publicar-dashboard.yml` y lo ejecutó
solo. **Este archivo se basa en el `deploy.yml` de la clase**, con Python y Quarto en lugar de R y
R Markdown.

### El archivo, bloque por bloque

> **Revisado contra el archivo vigente.** Lo que sigue es **copia fiel** de `.github/workflows/publicar-dashboard.yml`
> tal como está en el commit entregado (`e3bd43f`): 68 líneas, sin cambios desde el 22-sep (`git log` sobre ese archivo
> sólo muestra el commit `8b1fc83`). Las versiones de las acciones coinciden con las de la tabla de más abajo. La versión
> anterior de este capítulo omitía los comentarios del encabezado y las marcas `RUTA`; aquí aparecen.

**Bloque 1: el encabezado (comentarios).**

```yaml
# Construye el dashboard (Quarto + Python) y lo publica en GitHub Pages.
# Basado en los flujos vistos en clase (04_githubactions y plantillas de Quarto de la clase 8),
# con Python en lugar de R porque el análisis del equipo está en Python.
#
# Supone que la raíz del repositorio es la carpeta 06_proyecto:
#   Codigo/proyecto_mod_8/   (wc_predictor.py y los CSV del equipo)
#   Dashboard-o-pagina/      (el tablero)
# Si la estructura cambia, ajustar las rutas marcadas con "RUTA".
```

- Las líneas con `#` son comentarios: GitHub las ignora. Aquí dicen de dónde viene el flujo y **qué supone**: que la raíz
  del repositorio es la carpeta `06_proyecto`, así que las rutas empiezan en `Dashboard-o-pagina/` y no en
  `06_proyecto/Dashboard-o-pagina/`.
- Son **cuatro** las líneas con la marca `# RUTA`: la caché de `pip`, la instalación de paquetes, el `quarto render` y la
  carpeta que se sube. Si alguien reorganiza las carpetas, sólo hay que tocar esas cuatro.

**Bloque 2: nombre y disparadores.**

```yaml
name: Publicar dashboard en GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:        # permite ejecutarlo a mano desde la pestaña Actions
```

- `name` es el nombre que aparece en la pestaña **Actions**.
- `on:` dice **cuándo** corre: en cada `push` a la rama `main`, y a mano con `workflow_dispatch` (botón *Run workflow*).
- A diferencia del flujo de clase, **no se ejecuta en `pull_request`**, porque un *pull request* no debe publicar el
  sitio; y sólo `main` dispara la publicación: lo que se suba a otra rama no cambia la página.

**Bloque 3: permisos.**

```yaml
permissions:
  contents: read            # leer el repositorio
  pages: write              # publicar en GitHub Pages
  id-token: write           # identificación para el despliegue
```

- Es el **principio de mínimo privilegio**: el *token* que GitHub le da a la ejecución sólo puede **leer** el
  repositorio, **escribir en Pages** y pedir un **token de identidad** (`id-token`), que `deploy-pages` usa para
  demostrar que el despliegue viene de este flujo y de este repositorio. No puede, por ejemplo, modificar el código.

**Bloque 4: `concurrency` (una publicación a la vez).**

```yaml
concurrency:
  group: "pages"
  cancel-in-progress: false
```

- `concurrency` le dice a GitHub que de un mismo **grupo** corra **una sola ejecución a la vez**. `group: "pages"` es sólo
  una etiqueta (la misma que traen las plantillas de GitHub para publicar en Pages): todas las ejecuciones de este flujo
  la comparten, así que **hacen fila en lugar de correr en paralelo**. Sin esto, dos *push* seguidos lanzarían dos
  despliegues a la vez, y el más lento podría terminar **después** del más reciente y dejar publicada la versión vieja.
- `cancel-in-progress: false` significa que la ejecución que **ya está corriendo no se cancela**: un despliegue a
  medias no se interrumpe y termina su trabajo.
- **El detalle que sorprende:** en cada grupo sólo cabe **una** ejecución en espera. Si mientras una corre llegan dos
  *push* más, la que esperaba se **cancela** y queda en espera la más reciente: se saltan los intermedios y sólo se
  publica la última versión. En la pestaña Actions esas ejecuciones aparecen como **canceladas**, no como fallidas; el
  mensaje de GitHub suele decir, en inglés, que se cancelan porque existe una solicitud en espera de mayor prioridad
  para el grupo `pages`. **No son errores.** Pasó tres veces el 30-sep ([14.12](#1412-la-versión-final-30-sep-2026)).
- Con `cancel-in-progress: true` pasaría otra cosa: un *push* nuevo cancelaría **también la ejecución en curso**. Sirve
  para pruebas rápidas, pero en un despliegue puede dejarlo a medias.

> **Decisión:** `concurrency` con `group: "pages"` y `cancel-in-progress: false`.
> **Alternativas:** (a) **sin `concurrency`**: a favor, nada que configurar; en contra, dos despliegues simultáneos
> podrían pisarse y quedaría publicado el que termine último, no el más reciente; (b) **`cancel-in-progress: true`**: a
> favor, la ejecución más reciente empieza de inmediato; en contra, puede interrumpir un despliegue a medias; (c) **un
> grupo por rama** (por ejemplo `pages-${{ github.ref }}`): no aporta nada aquí, porque sólo `main` dispara el flujo.
> **Ninguna se probó.**
> **Por qué ésta:** el sitio siempre corresponde al último *commit* y nunca se interrumpe un despliegue en curso; es la
> configuración habitual para publicar en Pages.
> **Evidencia en el proyecto:** 23 ejecuciones desde el *push* de `9f84684`; 3 se cancelaron (eran las que esperaban cuando
> llegó un *push* más nuevo) y la del último commit, `e3bd43f`, terminó con éxito y publicó la versión final.
> **Si preguntan:** "Es para que no se publiquen dos versiones a la vez: una ejecución corre, sólo una espera y, si llega
> otra, reemplaza a la que esperaba. Por eso hubo ejecuciones canceladas; no son errores y la última siempre publica."

**Bloque 5: el trabajo `build` (construir el sitio).**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Clonar repositorio
        uses: actions/checkout@v6

      - name: Instalar Quarto (misma versión con la que se desarrolló)
        uses: quarto-dev/quarto-actions/setup@v2
        with:
          version: 1.8.25

      - name: Instalar Python 3.10 (misma versión del equipo)
        uses: actions/setup-python@v5
        with:
          python-version: "3.10"
          cache: pip
          cache-dependency-path: Dashboard-o-pagina/requirements.txt   # RUTA

      - name: Instalar paquetes de Python
        run: pip install -r Dashboard-o-pagina/requirements.txt       # RUTA

      - name: Renderizar dashboard (recalcula todo desde los datos del equipo)
        run: quarto render Dashboard-o-pagina                         # RUTA

      - name: Configurar GitHub Pages
        uses: actions/configure-pages@v5

      - name: Subir el sitio generado
        uses: actions/upload-pages-artifact@v4
        with:
          path: Dashboard-o-pagina/_site                              # RUTA
```

Dos palabras bastan para leer cualquier flujo: `uses:` ejecuta una **acción** ya hecha por alguien más (formato
`autor/nombre@versión`) y `run:` ejecuta un comando en la terminal del *runner*. Paso por paso:

| Paso | Qué hace | Por qué así |
|---|---|---|
| `runs-on: ubuntu-latest` | Pide una máquina virtual Ubuntu (el *runner*) | Es gratis y estándar; el aviso del cambio a Ubuntu 26 está más abajo |
| `actions/checkout@v6` | Descarga el repositorio en el *runner* (un clon superficial, sólo el commit que disparó la ejecución) | El *runner* nace vacío: sin esto no hay código ni datos |
| `quarto-dev/quarto-actions/setup@v2` con `version: 1.8.25` | Instala Quarto | La misma versión con la que se desarrolló: el mismo resultado |
| `actions/setup-python@v5` con `python-version: "3.10"` | Instala Python 3.10. El valor va **entre comillas** porque YAML leería `3.10` como el número 3.1. `cache: pip` guarda los paquetes descargados entre ejecuciones (la clave de la caché depende del contenido de `requirements.txt`) | La misma versión del equipo; y las ejecuciones siguientes son más rápidas |
| `pip install -r …/requirements.txt` | Instala las versiones fijas de las librerías | Reproducibilidad (D48): las cifras no dependen de qué versión salga ese día |
| `quarto render Dashboard-o-pagina` | Ejecuta los chunks de `index.qmd` (es decir, todo `datos_dashboard.py` y `graficas.py`) y escribe `Dashboard-o-pagina/_site/` | **Es la prueba de reproducibilidad**: recalcula todo desde los datos del repositorio. Si el código falla, el paso falla y el trabajo se detiene |
| `actions/configure-pages@v5` | Prepara y comprueba la configuración de Pages | Por eso Pages debe estar activado con fuente "GitHub Actions"; si no, falla aquí |
| `actions/upload-pages-artifact@v4` con `path` | Empaqueta `_site/` como un *artifact* llamado `github-pages` | Es el paquete que recibe el siguiente trabajo |

**Bloque 6: el trabajo `deploy` (publicar).**

```yaml
  deploy:
    needs: build            # sólo publica si el render terminó bien
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Desplegar en GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- `needs: build` hace que `deploy` **sólo corra si `build` terminó bien**. Si el render falla, no se publica nada y el
  sitio sigue mostrando la última versión buena. (Ojo: esto protege de que el *render* falle; si el render termina y la
  tabla de verificación marca ✗, **sí se publica**: el tablero avisa pero no bloquea,
  [13.6.2](13_dashboard.md#1362-la-verificación-de-17-cifras).)
- `environment: github-pages` es el entorno que exige Pages: GitHub guarda ahí el historial de despliegues. `url: ${{ … }}`
  lee la salida `page_url` del paso con `id: deployment` y pone la dirección publicada en el resumen de la ejecución.
- `actions/deploy-pages@v4` descarga el *artifact* `github-pages` y lo publica.
- ¿Por qué dos trabajos y no uno? Porque así el despliegue depende explícitamente de que la construcción termine bien, y en
  la pestaña Actions se ve por separado cuánto tardó cada parte.

### Comparación con el flujo de la clase

| Paso en clase (flexdashboard, R) | Paso en el proyecto (Quarto, Python) | Por qué cambia |
|---|---|---|
| `actions/checkout@v6` | `actions/checkout@v6` | Igual |
| `r-lib/actions/setup-r@v2` | `actions/setup-python@v5` (3.10) | El análisis está en Python |
| `r-lib/actions/setup-pandoc@v2` | `quarto-dev/quarto-actions/setup@v2` (1.8.25) | Quarto ya incluye Pandoc |
| `install.packages(c(...))` con `shell: Rscript {0}` | `pip install -r requirements.txt` | Versiones fijas en un archivo |
| `rmarkdown::render("...Rmd", output_file = "index.html", output_dir = "_site")` | `quarto render Dashboard-o-pagina` | `_quarto.yml` ya define la salida en `_site` |
| `configure-pages@v5` → `upload-pages-artifact@v4` → `deploy-pages@v4` | Igual | Igual |
| Se ejecuta también en `pull_request` | Solo en `push` y a mano | Un *pull request* no debe publicar |
| — | `concurrency: pages` con `cancel-in-progress: false` | Evita dos despliegues simultáneos y no interrumpe el que está en curso; si llegan varios *push* seguidos, sólo queda en espera el más reciente y los intermedios salen "cancelados" ([14.12](#1412-la-versión-final-30-sep-2026)) |

### Lo que tardó (primera ejecución, #35808804918)

| Job | Inicio → fin | Duración | Pasos (todos ✓) |
|---|---|---|---|
| **build** | 20:03:12 → 20:04:29 | 1 min 17 s | Clonar repositorio · Instalar Quarto · Instalar Python 3.10 · Instalar paquetes · **Renderizar dashboard** · Configurar Pages · Subir el sitio |
| **deploy** | 20:04:33 → 20:05:03 | 30 s | Desplegar en GitHub Pages |

**Unos 2 minutos del push al sitio publicado** (GitHub reporta *Total duration* 1 min 56 s). El
*artifact* `github-pages`, con el sitio empaquetado, pesó 2.98 MB. Para verlo: pestaña **Actions**
del repositorio → clic en la ejecución → cada *job* muestra sus pasos con ✓ y el tiempo de cada uno.

La ejecución muestra además cuatro **anotaciones**, que no son errores:
- ⚠ *Node.js 20 is deprecated…* (una en cada *job*): `configure-pages@v5`, `setup-python@v5`,
  `deploy-pages@v4` y la `upload-artifact` que usa internamente `upload-pages-artifact@v4` se
  programaron para una versión de Node.js que GitHub está retirando. GitHub ya las corre con
  Node.js 24 y funcionan. Se resuelve subiendo cada acción a su siguiente versión mayor cuando esté
  disponible.
- ℹ *The ubuntu-latest label will migrate to Ubuntu 26 beginning October 19, 2026*: aviso de que la
  máquina virtual cambiará de versión, después de la exposición. Si algún día fallara por eso, se
  fija la versión con `runs-on: ubuntu-24.04`.

## 14.10 Paso 8: verificar

| Qué se revisó | Cómo | Resultado |
|---|---|---|
| Local y GitHub sincronizados | `git status -sb` | `## main...origin/main` (sin commits pendientes) |
| El flujo | Pestaña Actions (o la API pública de GitHub) | `completed · success` |
| El sitio | Abrir la URL | HTTP 200, ≈ 5 MB, título correcto, **13 gráficas** |
| **Las cifras** | Pestaña *Datos y método → Reproducibilidad* del tablero | **15 de 15 ✓** |

La última fila es la prueba de reproducibilidad más fuerte del proyecto. **El tablero se construyó
en una computadora de GitHub que nunca había visto el proyecto**: descargó el código y los datos,
instaló las versiones fijadas, recalculó todo, y las 15 cifras de control (10 LogLoss a 6 decimales
y el ejemplo Arsenal–Man City) coinciden con el notebook y el reporte técnico. La guía de clase lo
dice así: GitHub Actions "nos obliga a comprobar que el proyecto es reproducible".

> **Con la versión final:** la tabla de verificación compara hoy **17 cifras** (12 LogLoss y el ejemplo Arsenal–Man
> City), ya no 15, y no contra cifras copiadas a mano sino contra las **salidas guardadas** del notebook; la página publicada
> tras `e3bd43f` muestra **17 de 17 ✓** ([14.12](#1412-la-versión-final-30-sep-2026) y
> [13.6.2](13_dashboard.md#1362-la-verificación-de-17-cifras)). Las "13 gráficas" son las que se contaron el 22-sep; la
> versión entregada tiene 11 gráficas de Plotly más el mapa de marcadores del simulador.

## 14.11 Paso 9: segundo commit y la liga en *About*

Con la URL ya conocida, se agregó al README y al tablero (botón de GitHub en la barra, con
`nav-buttons` en el YAML de `index.qmd`). Antes de subir, se renderizó localmente para confirmar que
nada se rompía. Luego:

```bash
git add .
git commit -m "Agregar URL del dashboard y enlace al repositorio"     # 42e80a5 · 5 files changed
git push                                                               # ya sin -u ni login
```

El flujo se relanzó solo (#35809813982, ✓). Después, en Chrome, **igual que en clase**: página del
repositorio → **About → engrane ⚙ → Use your GitHub Pages website → Save changes**. La casilla está
justo debajo del campo *Website*; si la ventana es angosta, *About* aparece debajo de la lista de
archivos. Si la casilla no aparece, se escribe la URL a mano en *Website*.



### Verificación final (22-sep)

| Qué | Resultado |
|---|---|
| Commits en `main` ese día (consultado en la API de GitHub) | **1**: `8b1fc83` (después el equipo siguió subiendo cambios: [14.12](#1412-la-versión-final-30-sep-2026)) |
| Archivos en `Dashboard-o-pagina/` | 9, sin `DECISIONES.md` ni `GUIA_DEFENSA.md` |
| Flujo #35812702955 | ✓ en unos 2 minutos |
| Sitio publicado | HTTP 200; redibujado corregido presente; zoom desactivado en todas las gráficas; **0 menciones** a DECISIONES o GUIA_DEFENSA |



## 14.12 La versión final (30-sep-2026)

La publicación del 22-sep dejó el repositorio con **un solo commit** (`8b1fc83`). Del 22 al 30 de septiembre el equipo
siguió trabajando **sobre el mismo `main`**: antes de la actualización del tablero (30-sep, 19:14) el historial ya tenía
**58 commits**. Muchos se hicieron desde el navegador, y se nota por los mensajes que GitHub pone por omisión al editar,
subir o borrar archivos (*Update …*, *Add files via upload*, *Delete …*). Esta sección cuenta lo que pasó **ese día**,
hasta la versión que se entrega: el commit `e3bd43f` (30-sep, 23:38).

**Las cifras de la publicación final** (del historial de Git y de la pestaña Actions):

| Qué | Cifra |
|---|---|
| Commits entre `9f84684` y `e3bd43f` (sin contar esos dos) | 21 |
| Ejecuciones de Actions desde el *push* de `9f84684` | 23 |
| Ejecuciones de Actions en total en el repositorio | 81 |
| De las 40 más recientes | 37 con éxito y **3 canceladas** (ninguna fallida) |
| La ejecución del último commit (`e3bd43f`) | con éxito |
| La tabla de verificación de la página publicada | **17 de 17 ✓** |

(Una ejecución nace por cada *push*, no por cada commit: un mismo `git push` puede subir varios commits, y un *push*
forzado, como el del final, genera otra ejecución. Por eso el número de ejecuciones no tiene que coincidir con el de
commits.)

El historial de ese día, tal como lo muestra Git (el más reciente arriba; horas del centro de México):

```bash
git log --format="%h %ad %an | %s" --date=format:"%Y-%m-%d %H:%M" 9f84684~1..e3bd43f
```

```text
e3bd43f 2026-09-30 23:38 César Emiliano Garduño Gutiérrez | Correcciones finales
4f63a32 2026-09-30 22:24 César Emiliano Garduño Gutiérrez | Update README.md
17a603a 2026-09-30 22:17 Maximiliano Gomez | Delete Codigo/Documentacion directory
d667fcf 2026-09-30 22:10 César Emiliano Garduño Gutiérrez | Update README.md
254fb2d 2026-09-30 22:08 Maximiliano Gomez | Add files via upload
988b5f4 2026-09-30 22:08 Maximiliano Gomez | Delete README.md
3bfe66f 2026-09-30 21:56 Maximiliano Gomez | Add files via upload
9b52404 2026-09-30 21:56 Maximiliano Gomez | Delete ProyectoFinal_Módulo8_Reporte.pdf
f714d19 2026-09-30 21:55 Maximiliano Gomez | Add files via upload
bb104d6 2026-09-30 21:52 Maximiliano Gomez | Delete REPRODUCIBILIDAD.txt
c3447aa 2026-09-30 21:52 Maximiliano Gomez | Add files via upload
cbcc037 2026-09-30 21:46 Maximiliano Gomez | Remove reproducibility section from README
c781da0 2026-09-30 21:46 Maximiliano Gomez | Update README.md
fc340c5 2026-09-30 21:46 Maximiliano Gomez | Revise README for project setup and workflow clarity
ee12a39 2026-09-30 21:41 Maximiliano Gomez | Add files via upload
34f7bbd 2026-09-30 21:38 César Emiliano Garduño Gutiérrez | Update index.qmd
16c9e4b 2026-09-30 21:12 César Emiliano Garduño Gutiérrez | Update index.qmd
0c372d0 2026-09-30 20:51 César Emiliano Garduño Gutiérrez | Update index.qmd
a0f731f 2026-09-30 20:29 César Emiliano Garduño Gutiérrez | Update index.qmd
9bf266f 2026-09-30 20:02 DanielCastilloRdz | Add files via upload
d5eca5c 2026-09-30 19:34 DanielCastilloRdz | Add files via upload
5c70f73 2026-09-30 19:33 César Emiliano Garduño Gutiérrez | Update index.qmd
9f84684 2026-09-30 19:14 César Emiliano Garduño Gutiérrez | Tablero: K = 15 y k = 0, cifras tomadas del código
```

`A..B` significa "los commits que están en `B` y no en `A`"; `9f84684~1` es el padre de `9f84684`, así que el rango empieza
justo en `9f84684`. Agrupado por quién hizo qué:

| Quién | Commits | Qué hizo |
|---|---|---|
| César | `9f84684` (19:14) | Actualizó el tablero a K = 15 y k = 0 desde su computadora ([14.12.1](#14121-actualizar-el-tablero-a-k--15-y-k--0-commit-9f84684-1914)) |
| César | `5c70f73`, `a0f731f`, `0c372d0`, `16c9e4b`, `34f7bbd` (19:33 a 21:38) | Cinco ediciones de `index.qmd` desde el editor web ([14.12.2](#14122-las-ediciones-web-de-césar-en-indexqmd)) |
| Daniel | `d5eca5c` (19:34), `9bf266f` (20:02) | Subió dos veces `Analisis.ipynb`: M3 en la prueba y una nota sobre las 4 observaciones excluidas ([14.12.3](#14123-los-cambios-de-daniel-m3-en-la-prueba-y-la-verificación-que-pasó-a-17)) |
| Max | 12 commits, de `ee12a39` (21:41) a `17a603a` (22:17) | README nuevo, `Reporte.pdf`, `REPRODUCIBILIDAD.txt` (subido y borrado) y borró `Codigo/Documentacion/` ([14.12.4](#14124-los-cambios-de-max-readme-reporte-y-limpieza)) |
| César | `d667fcf` (22:10), `4f63a32` (22:24) | Ajustes al README |
| César | `e3bd43f` (23:38) | Correcciones finales; commit rehecho con `--amend` ([14.12.6](#14126-e3bd43f-el-último-commit-y-cómo-se-rehízo)) |

### 14.12.1 Actualizar el tablero a K = 15 y k = 0 (commit `9f84684`, 19:14)

**La situación.** Daniel había cambiado el modelo (K = 15, k = 0 y la limpieza nueva) y el equipo ya lo había subido a
`main`: el último commit era `0be322f`, de Daniel, a las 18:47. César tenía en su computadora, **sin commit**, la
actualización del tablero: `datos_dashboard.py` e `index.qmd`, para que usaran esos valores y tomaran las cifras del
código, y el `README.md`, sin cifras escritas a mano. Había dos riesgos: su copia estaba **atrasada** respecto de GitHub
(los compañeros habían subido cosas desde la web) y un `git push` desde una copia atrasada se rechaza
(`! [rejected] … (fetch first)`, [14.14](#1414-errores-frecuentes-y-cómo-resolverlos)).

```bash
git fetch                                   # 1
git stash                                   # 2
git merge --ff-only                         # 3
git stash pop                               # 4
quarto render Dashboard-o-pagina            # 5   y revisar la tabla de verificación: 16 de 16
git add Dashboard-o-pagina/datos_dashboard.py Dashboard-o-pagina/index.qmd README.md   # 6
git commit -m "Tablero: K = 15 y k = 0, cifras tomadas del código"                      # 7   nace 9f84684
                                            # 8   comprobar que nadie subió nada mientras tanto
git push                                    # 9
```

| # | Comando | Qué hace | Por qué se usó aquí |
|---|---|---|---|
| 1 | `git fetch` | Descarga los commits nuevos de GitHub **sin tocar** tus archivos | Para ver qué subió el equipo antes de mezclar nada |
| 2 | `git stash` | Guarda los cambios sin commit en un "cajón" y deja la carpeta como en el último commit | Para poder avanzar a lo nuevo sin conflictos y sin perder el trabajo propio |
| 3 | `git merge --ff-only` | Mueve `main` hasta el último commit de GitHub (`origin/main`, la rama que sigue gracias al `-u` de [14.8](#148-paso-6-conectar-la-carpeta-con-github-y-subir)) **sólo si basta con avanzar en línea recta** (*fast-forward*) | Si los historiales hubieran divergido, **falla** en lugar de inventar un commit de fusión que nadie pidió |
| 4 | `git stash pop` | Saca los cambios del cajón y los aplica encima de lo nuevo | Para recuperar el trabajo propio sobre la versión más reciente; si el equipo hubiera tocado las mismas líneas, aquí saldría un conflicto |
| 5 | `quarto render Dashboard-o-pagina` | Reconstruye el sitio con el código y los datos nuevos | Para comprobar **antes de subir** que el tablero funciona y que la verificación da **16 de 16** |
| 6 | `git add <archivos>` | Pasa al área de preparación sólo los archivos nombrados | Sólo los **tres** revisados; un `git add .` podría arrastrar algo que no se revisó |
| 7 | `git commit -m "…"` | Guarda la foto: nace `9f84684` | Mensaje de una línea, en español |
| 8 | (comprobación) | Verificar que nadie subió nada mientras tanto; por ejemplo, un segundo `git fetch` y `git status -sb` | Si alguien hubiera subido, el `push` se rechazaría; mejor enterarse antes |
| 9 | `git push` | Sube `9f84684` a `main` y dispara el flujo | Ya no hacen falta `-u` ni el inicio de sesión: quedaron configurados el 22-sep |

**Resultado:** `9f84684` quedó **encima** de `0be322f` (su padre es el último commit del equipo): historial en línea recta,
sin commits de fusión, y el `push` no se rechazó. El flujo lo publicó solo.

> **Decisión:** traer el trabajo del equipo con `git fetch` + `git stash` + `git merge --ff-only` + `git stash pop`, y subir
> sólo los archivos revisados.
> **Alternativas:** (a) **`git pull` a secas** (es `fetch` + `merge`): a favor, un solo comando; en contra, puede crear un
> commit de fusión que nadie pidió, y se niega a actuar si los cambios locales chocan con los nuevos; (b) **`git pull
> --rebase --autostash`**: a favor, hace el cajón y la reaplicación por ti; en contra, un solo paso que oculta lo que
> ocurre, y reescribe los commits locales si los hubiera; (c) **copiar los archivos a otro lado, `git reset --hard
> origin/main` y pegarlos de vuelta**: a favor, muy simple; en contra, destructivo y fácil de hacer mal; (d) **editar sólo
> desde la web**, como hicieron los demás: a favor, sin problemas de sincronía; en contra, no se puede renderizar ni
> verificar antes de publicar; (e) **una rama y un *pull request***: a favor, revisión antes de mezclar; en contra, más
> trámite en la última semana. **Ninguna se probó.**
> **Por qué ésta:** cada paso se ve y se puede detener; `--ff-only` falla en vez de improvisar; el cajón no pierde nada; y
> permite renderizar y verificar (16 de 16) antes de subir.
> **Evidencia en el proyecto:** el historial es lineal (`9f84684` sobre `0be322f`, sin commits de fusión) y el *push* no se
> rechazó.
> **Si preguntan:** "Antes de subir mi cambio traje lo que los compañeros habían subido (`fetch` y `merge --ff-only`),
> guardando mi trabajo en un `stash`; así mi commit quedó encima del último del equipo, sin commits de fusión y sin pisar
> nada."

### 14.12.2 Las ediciones web de César en `index.qmd`

Entre las 19:33 y las 21:38, César hizo **cinco ediciones de `index.qmd` desde el editor web de GitHub** (`5c70f73`,
`a0f731f`, `0c372d0`, `16c9e4b` y `34f7bbd`, todas con el mensaje por omisión *Update index.qmd*). Eran cambios de texto
para simplificar: subtítulos más cortos; la hipótesis, que ahora dice que el mercado "tiene información ventajosa"; la
tarjeta "No es una derrota..."; se quitó el "recorrido sugerido"; y la lectura del *bootstrap* ya no repite los
intervalos que están en la tabla. Cada guardado fue un commit, y cada commit, un *push* que **republicó el tablero**
(unos 2 minutos, como en [14.9](#149-paso-7-github-actions-construye-y-publica-el-tablero)).

- **Ventaja:** se corrige un texto sin abrir RStudio ni Python, y se publica en minutos.
- **Riesgo:** no se renderiza antes de publicar. Si un error rompe un chunk, el `build` falla y el sitio sigue con la
  última versión buena; el error se ve en la pestaña Actions.
- **Consecuencia:** la copia que se tiene en la computadora queda **atrasada**. Antes de seguir trabajando en local hay
  que repetir `git fetch` y `git merge --ff-only`, como en [14.12.1](#14121-actualizar-el-tablero-a-k--15-y-k--0-commit-9f84684-1914).

### 14.12.3 Los cambios de Daniel: M3 en la prueba y la verificación que pasó a 17

Daniel subió `Analisis.ipynb` dos veces desde la web (`d5eca5c`, 19:34, y `9bf266f`, 20:02; ambas *Add files via upload*).
El notebook quedó con 26 celdas y dos cambios ([capítulo 11](11_codigo_analisis_notebook.md)):

- Una **nota** (celda Markdown) y una celda de código sobre las **4 observaciones sin historial previo** que se excluyen
  de la base (el primer partido de Brentford, Nott'm Forest, Luton y Coventry). La razón que documenta: mantener la misma
  muestra para M0–M4, de modo que la comparación sea homogénea, aunque M0 no necesite los tiros.
- **M3 entró a la evaluación en prueba**: ahora se evalúan las cinco especificaciones. LogLoss de prueba: M0 1.033076 ·
  M1 1.034699 · M2 1.037331 · **M3 1.033868** · M4 1.036739 (M3 tiene, además, el menor MAE medio, 0.894173).

**Efecto en el tablero: ninguno que hubiera que programar.** La tabla de verificación lee las **salidas guardadas** del
notebook ([13.6.2](13_dashboard.md#1362-la-verificación-de-17-cifras)): cuando M3 apareció en la prueba, la tabla lo
incorporó **sola** y pasó de **16 a 17 cifras**, sin tocar `datos_dashboard.py` ni `index.qmd`. Es la evidencia de que la
verificación no es una lista copiada a mano. La página publicada tras `e3bd43f` muestra **17 de 17 ✓**.

### 14.12.4 Los cambios de Max: README, reporte y limpieza

Entre las 21:41 y las 22:17, Max hizo **12 commits** (casi todos con los mensajes por omisión de la web de GitHub), y
César ajustó el README a las 22:10 y a las 22:24:

- **README nuevo** (411 líneas en el archivo entregado). Sus secciones: *Equipo*; *Estructura* (con "Cómo se conectan las
  partes", la cadena de archivos); *Reproducibilidad*, paso a paso (qué instalar, preparar el entorno, reproducir el
  análisis y el tablero, y reconstruir `E0_consolidado.csv` desde los datos crudos); y *Uso de herramientas de IA*. Trae las
  **huellas SHA-256** de los dos CSV, las versiones de Python y de Quarto, cómo repetir la rejilla de K y k, y cómo activar
  la publicación si alguien trabaja en un *fork*. Se rehízo varias veces (`fc340c5`, `c781da0`, `cbcc037`, `c3447aa`) y
  al final se borró y se volvió a subir completo (`988b5f4` y `254fb2d`, los dos a las 22:08).
- **`REPRODUCIBILIDAD.txt`** se subió (`ee12a39`, 21:41) y se borró (`bb104d6`, 21:52): su contenido pasó al README.
- **`Reporte.pdf`** (reporte técnico, 21 páginas). Se subió primero como `ProyectoFinal_Módulo8_Reporte.pdf` (`f714d19`,
  21:55), se borró (`9b52404`, 21:56) y se volvió a subir con el nombre final (`3bfe66f`, 21:56): un cambio de nombre
  hecho como "borrar y subir de nuevo", por eso el historial muestra esos pares.
- **Se borró `Codigo/Documentacion/`** (`17a603a`, 22:17), que tenía tres archivos: `main.tex`, `Modulo_8.pdf` y
  `Modulo_8.zip`. Ya no existe en el repositorio.

Cada uno de esos commits fue un *push* y por lo tanto intentó lanzar el flujo. Como llegaron muy seguidos, algunas
ejecuciones se cancelaron: [14.12.5](#14125-tres-ejecuciones-canceladas-por-concurrency).

### 14.12.5 Tres ejecuciones canceladas por `concurrency`

En la pestaña Actions aparecen **tres ejecuciones canceladas** (no fallidas), todas del 30-sep entre las 21:46 y las
22:08, durante las ediciones seguidas de Max:

| Commit de la ejecución | Hora | Mensaje | Los commits vecinos (por la hora) |
|---|---|---|---|
| `c781da0` | 21:46 | Update README.md | `fc340c5`, `c781da0` y `cbcc037`, los tres en el mismo minuto |
| `9b52404` | 21:56 | Delete ProyectoFinal_Módulo8_Reporte.pdf | `f714d19` (21:55), `9b52404` y `3bfe66f` (21:56) |
| `254fb2d` | 22:08 | Add files via upload (el README) | `988b5f4` (22:08), `254fb2d` y `d667fcf` (22:10) |

**Por qué no son errores.** El flujo tiene `concurrency: group: "pages"` con `cancel-in-progress: false`
([Bloque 4 de 14.9](#149-paso-7-github-actions-construye-y-publica-el-tablero)): la ejecución en curso no se interrumpe, pero
en el grupo sólo cabe **una** ejecución en espera. Si llega otro *push* mientras hay una corriendo y otra esperando, la que
esperaba se cancela y queda en espera la más reciente. Las horas de los commits encajan con esa explicación: cada
ejecución cancelada era la "del medio" de tres *push* casi simultáneos.

**Qué se perdió: nada.** Las ejecuciones canceladas eran de versiones intermedias; la última de cada tanda construyó y
publicó el contenido más reciente del repositorio. De las 40 ejecuciones más recientes, 37 terminaron con éxito y 3 se
cancelaron; ninguna falló. Cómo revisarlo: pestaña **Actions** del repositorio → la lista de ejecuciones (las canceladas
llevan el estado *Cancelled*) → abrir una para ver el mensaje.

### 14.12.6 `e3bd43f`: el último commit y cómo se rehízo

**Qué cambió.** "Correcciones finales" tocó cuatro archivos: `datos_dashboard.py` e `index.qmd` (la función
`sensibilidad_sin_publico()` devuelve ahora también las fechas `inicio` y `fin` del periodo sin público, del 17-jun-2020 al
23-may-2021, y el texto del tablero las muestra), `README.md` y `Reporte.pdf`.

**Por qué se rehízo.** El mensaje original del commit tenía más de una línea. La preferencia es dejar los mensajes de
**una línea**, sin descripción adicional, así que se reescribió el último commit:

| Comando | Qué hace | Por qué se usó aquí |
|---|---|---|
| `git commit --amend` | Reemplaza el **último** commit por uno nuevo con el mismo contenido y otro mensaje; cambia su identificador | Para dejar el mensaje en una línea: `e3bd43f Correcciones finales` |
| `git push --force-with-lease` | Sube el commit rehecho aunque el historial remoto "ya no coincide" (el commit viejo ya estaba en GitHub), **pero sólo si** la rama remota sigue como la última vez que se descargó | Un `git push` normal se rechazaría; `--force` a secas sobrescribiría sin mirar y, si alguien hubiera subido algo en ese momento, se perdería |

El contenido era el mismo, así que el sitio no cambió: sólo cambió el identificador del commit (y se lanzó otra ejecución,
que terminó con éxito).

> **Decisión:** rehacer el último commit con `git commit --amend` y subirlo con `git push --force-with-lease`.
> **Alternativas:** (a) **`git push --force`**: a favor, igual de simple; en contra, sobrescribe la rama remota sin revisar,
> y si alguien hubiera subido algo en ese momento, se perdería; (b) **no reescribir el historial** y dejar el mensaje largo: a
> favor, lo más seguro; en contra, un historial menos uniforme; (c) **`git rebase -i`** para reescribir el mensaje: a favor,
> sirve también con commits que no son el último; en contra, es más complejo y aquí sobraba, porque era el último.
> **Ninguna se probó.**
> **Por qué ésta:** reescribir historial ya publicado es delicado (rompe las copias de quien ya descargó el commit viejo),
> así que se hizo **una sola vez, sobre el último commit y con la opción segura**: `--force-with-lease` se niega a
> sobrescribir si el remoto tiene algo que no se había visto.
> **Evidencia en el proyecto:** el `git log` del entregable termina en `e3bd43f Correcciones finales` y la ejecución de ese
> commit terminó con éxito.
> **Si preguntan:** "Corregimos el mensaje del último commit con `--amend` y lo subimos con `--force-with-lease`, que se
> niega a sobrescribir si alguien más subió cambios; así el historial queda con mensajes de una línea sin arriesgar el
> trabajo de nadie."

(Es la decisión [D50](19_decisiones_y_alternativas.md#d50-repositorios-separados-e-historial-limpio--razonada) del capítulo 19.)

### 14.12.7 El estado final del repositorio y lo aprendido

```text
futbol-apuestas  (rama main · commit e3bd43f · 30-sep-2026)
├── .github/workflows/publicar-dashboard.yml     el flujo (14.9); sin cambios desde el 22-sep
├── .gitignore
├── README.md                                    411 líneas: estructura, reproducibilidad con huellas SHA-256, uso de IA
├── Reporte.pdf                                  reporte técnico, 21 páginas
├── Codigo/proyecto_mod_8/
│   ├── Limpieza de datos.ipynb · E0_consolidado.csv · wc_predictor.py
│   └── Analisis.ipynb · premier_training_data.csv
└── Dashboard-o-pagina/                          _quarto.yml · index.qmd · datos_dashboard.py · graficas.py · estilos.scss ·
                                                 redibujar.html · requirements.txt · README.md · .gitignore
```

Ya **no existen** `Codigo/Documentacion/` (la borró Max el 30-sep) ni `REPRODUCIBILIDAD.txt` (su contenido pasó al README).
`ProyectoModulo8.pdf`, las instrucciones del curso, sigue fuera del repositorio por el `.gitignore` ([14.5](#145-paso-3-decidir-qué-se-sube)).
Lo que se **publica** en la página no es el repositorio entero, sino sólo `Dashboard-o-pagina/_site/`.

**Lo que enseña ese día:**

1. **Si otros editan en la web, trae sus cambios antes de trabajar en local:** `git fetch` y `git merge --ff-only`
   (con `git stash` si tienes cambios sin guardar).
2. **Sube sólo lo que revisaste:** `git add` con los nombres de los archivos, no `git add .`.
3. **Las ejecuciones "canceladas" no son errores:** `concurrency` deja en espera sólo la más reciente y la última siempre
   publica.
4. **Reescribe historial sólo si hace falta, sólo el último commit y con `--force-with-lease`.**
5. **La prueba final está en la propia página:** la pestaña *Reproducibilidad* muestra **17 de 17 ✓**, calculados en la
   máquina limpia de GitHub.



## 14.13 Equivalencias con RStudio y con lo visto en clase

| Lo que hicimos (terminal) | En RStudio (botones) | Con paquetes de R |
|---|---|---|
| `git config --global user.name/email` | — | `usethis::use_git_config(user.name = "…", user.email = "…")` |
| Iniciar sesión con Git Credential Manager | — | `usethis::create_github_token()` + `gitcreds::gitcreds_set()` (lo visto en clase, con PAT) |
| `git init -b main` | Tools → Project Options → Git/SVN → Version control: Git | `usethis::use_git()` |
| Crear el repo en github.com y `git remote add origin` | — | `usethis::use_github()` (crea el repo en GitHub y lo conecta) |
| `git add` + `git commit` | Panel **Git** → marcar *Staged* → **Commit** → escribir mensaje | — |
| `git push` / `git pull` | Botones **Push** (flecha verde ↑) / **Pull** (flecha azul ↓) | — |
| `git status` | Panel **Git** (M = modificado, A = agregado, D = borrado, ? = nuevo) | — |
| Escribir `.gitignore` | Se crea solo con el proyecto de RStudio | `usethis::use_git_ignore("_site/")` |
| Workflow en `.github/workflows/` | Crear el archivo, o desde Actions → *set up a workflow yourself* | `usethis::use_github_action()` (plantillas de r-lib/actions) |
| `quarto render Dashboard-o-pagina` | Botón **Render** | `quarto::quarto_render()` (paquete no instalado aquí) o `rmarkdown::render()` para `.Rmd` |
| `git fetch` ([14.12.1](#14121-actualizar-el-tablero-a-k--15-y-k--0-commit-9f84684-1914)) | No tiene botón propio: **Pull** hace `fetch` y luego `merge` | `gert::git_fetch()` |
| `git stash` y `git stash pop` | No tienen botón: se usan desde la pestaña **Terminal** | `gert::git_stash_save()` y `gert::git_stash_pop()` |
| `git merge --ff-only` | **Pull** (con una historia lineal hace lo mismo, pero no deja exigir *fast-forward*) | `gert::git_branch_fast_forward()` (avanza la rama sólo en línea recta) |
| `git commit --amend` ([14.12.6](#14126-e3bd43f-el-último-commit-y-cómo-se-rehízo)) | En la ventana de commit, la casilla **Amend previous commit** | — (se hace en la terminal) |
| `git push --force-with-lease` | No hay botón (**Push** nunca fuerza): se usa la **Terminal** | `gert::git_push(force = TRUE)`, que equivale a `--force`: **sin** la protección del *lease* |
| `git log --format=… A..B` ([14.12](#1412-la-versión-final-30-sep-2026)) | Panel **Git** → **History** (el reloj) | `gert::git_log()` |

Las seis últimas filas, y en particular las funciones de `gert` (el paquete de R para Git que usa `usethis` por debajo) y
los botones de RStudio que se mencionan, son **ilustrativas**: no se ejecutaron. Lo que sí conviene recordar es que RStudio
cubre lo cotidiano (*Stage*, *Commit*, *Pull*, *Push*) y que `stash`, `--ff-only` y `--force-with-lease` se hacen en la
terminal.

Si el tablero se hubiera hecho en **Flexdashboard**, el flujo sería prácticamente el `deploy.yml` de
la clase: `setup-r`, `setup-pandoc`, `install.packages(...)` y
`rmarkdown::render("dashboard.Rmd", output_file = "index.html", output_dir = "_site")`, con los
mismos tres pasos finales de Pages.

## 14.14 Errores frecuentes y cómo resolverlos

| Mensaje o síntoma | Causa | Solución |
|---|---|---|
| `fatal: not a git repository` | La terminal no está en la carpeta del repositorio | `cd "ruta"` (con comillas) |
| `error: remote origin already exists` | Ya se había agregado el remoto | `git remote set-url origin https://…` (no volver a hacer `add`) |
| `error: src refspec main does not match any` | Aún no hay commits, o la rama se llama `master` | Hacer el commit primero, o `git branch -M main` |
| `! [rejected] main -> main (fetch first)` | El remoto tiene commits que no tienes (p. ej., se creó con README) | `git pull` y luego `git push`; en un repo nuevo, crearlo vacío |
| `Support for password authentication was removed` | Se escribió la contraseña de GitHub | Usar Git Credential Manager (navegador) o un token (PAT) |
| `Permission denied` o `403` | La cuenta con la que inició sesión no tiene permiso | Aceptar la invitación de colaborador; revisar la cuenta guardada en el Administrador de credenciales de Windows |
| Falla el paso de Pages en Actions | Pages no está activado con fuente "GitHub Actions" | Settings → Pages → Source → GitHub Actions, y **Re-run jobs** |
| `ModuleNotFoundError` en Actions | Falta un paquete en `requirements.txt` | Agregarlo y volver a subir (en R: agregarlo a `install.packages`) |
| Funciona local pero falla en Actions | Ruta absoluta, archivo que no se subió, paquete no declarado | Rutas relativas; revisar `git ls-files`; declarar paquetes |
| La página da 404 justo después del despliegue | Tarda uno o dos minutos en propagarse, o el navegador muestra una versión guardada | Esperar y recargar con Ctrl + F5 |
| Anotación amarilla *Node.js 20 is deprecated* | Acciones programadas para una versión de Node.js que GitHub retira | No es un error: el flujo termina bien. Actualizar la versión mayor de cada acción cuando exista |
| En la ejecución, el menú ⋯ no tiene *Delete workflow run* | Esa opción está en la **lista** de ejecuciones, no dentro de la ejecución | Volver a Actions y usar el ⋯ al final de la fila |
| `LF will be replaced by CRLF` | Diferente fin de línea entre Windows y Linux | Es solo un aviso; no hay que hacer nada |
| `CÃ©sar` en lugar de `César` | PowerShell muestra mal los acentos | Solo afecta la vista; lo guardado está bien |
| La carpeta `.github` no aparece con `ls` | Es una carpeta que empieza con punto | `ls -Force` (PowerShell) o `ls -a` (Git Bash) |
| `error: Your local changes to the following files would be overwritten by merge` | Tienes cambios sin guardar en archivos que también cambiaron en GitHub | `git stash`, luego `git merge --ff-only`, luego `git stash pop` ([14.12.1](#14121-actualizar-el-tablero-a-k--15-y-k--0-commit-9f84684-1914)) |
| `fatal: Not possible to fast-forward, aborting.` | Con `--ff-only`: tu copia y GitHub tienen commits distintos (el historial divergió) | Revisa con `git log` qué hay en cada lado; si tus commits locales sí deben conservarse, `git pull --rebase`; si no, pide ayuda antes de forzar nada |
| `! [rejected] main -> main (stale info)` | Con `--force-with-lease`: alguien subió algo a GitHub desde la última vez que descargaste | `git fetch`, revisar lo nuevo y repetir; no lo resuelvas con `--force` a secas |
| `git status -sb` dice `behind 3` | Tu copia está atrasada (por ejemplo, tras ediciones desde la web) | `git fetch` y `git merge --ff-only` |
| En Actions, ejecuciones con estado *Cancelled* | `concurrency` dejó en espera sólo el *push* más reciente | No es un error: la última ejecución publica ([14.12.5](#14125-tres-ejecuciones-canceladas-por-concurrency)) |

## 14.15 Preguntas que pueden hacer sobre la publicación

<details><summary><b>¿Cómo se publicó el tablero?</b></summary>

El código y los datos están en un repositorio público de GitHub. Cada vez que se sube un cambio,
GitHub Actions levanta una máquina Ubuntu, instala Python 3.10 y Quarto 1.8.25 con versiones fijas,
ejecuta el tablero (que recalcula todo desde los datos) y publica el HTML en GitHub Pages. Es el
mismo esquema de la clase, con Python en lugar de R.
</details>

<details><summary><b>¿Por qué no subieron el HTML directamente?</b></summary>

Porque así se garantiza que lo publicado sale del código y los datos que están en el repositorio.
Si el HTML se generara a mano, podría no corresponder al código. Además, cada publicación demuestra
que el proyecto se puede reproducir en otra computadora.
</details>

<details><summary><b>¿Cómo sabemos que es reproducible?</b></summary>

El tablero se construye en un servidor de GitHub que solo tiene lo que está en el repositorio. Aun
así, las 17 cifras de control coinciden con las que el notebook dejó guardadas (pestaña *Reproducibilidad*: 17 de 17 ✓).
Las versiones de Python, Quarto y cada paquete están fijadas.
</details>

<details><summary><b>¿Qué es un commit y qué hace <code>git push</code>?</b></summary>

Un commit es una versión guardada del proyecto, con autor, fecha y mensaje. `git push` sube los
commits locales al repositorio de GitHub. En nuestro caso, además, dispara el flujo que republica el
tablero.
</details>

<details><summary><b>¿Qué pasa si alguien sube un cambio que rompe el tablero?</b></summary>

Si el *render* falla, el job `build` falla y, como `deploy` tiene `needs: build`, **no se publica nada**: el sitio sigue
mostrando la última versión buena. El error aparece en rojo en la pestaña Actions, con el paso que
falló. Ojo: si el *render* termina bien pero la tabla de verificación marca ✗, el tablero **sí se publica** (avisa con
"HAY DIFERENCIAS", pero no bloquea).
</details>

<details><summary><b>¿Por qué el historial del repositorio empieza con un solo commit?</b></summary>

El 22-sep el historial se reescribió a propósito para separar el entregable del material de preparación del
equipo, que vive en otro repositorio (el de esta guía). Ese primer commit (`8b1fc83`) declara la coautoría de la IA
por transparencia. Desde entonces el repositorio **ya no tiene un solo commit**: el equipo siguió subiendo cambios (58
commits antes del 30-sep a las 19:14, y 23 más desde `9f84684` hasta `e3bd43f`, [14.12](#1412-la-versión-final-30-sep-2026)).
</details>

<details><summary><b>¿Por qué hay ejecuciones "canceladas" en la pestaña Actions?</b></summary>

No son errores. El flujo tiene `concurrency` con `cancel-in-progress: false`: la ejecución en curso no se interrumpe,
pero en el grupo sólo cabe una en espera, y si llega otro *push* reemplaza a la que esperaba. El 30-sep, con las
ediciones seguidas de Max, tres ejecuciones se cancelaron; la última siempre publica (de las 40 más recientes, 37
terminaron con éxito y 3 se cancelaron, ninguna falló).
</details>

<details><summary><b>¿Cómo actualizaron el tablero sin pisar el trabajo de los demás?</b></summary>

Antes de subir su cambio, César trajo lo que el equipo había subido: `git fetch`, guardó su trabajo con `git stash`,
avanzó con `git merge --ff-only` (que falla en lugar de crear commits de fusión) y recuperó su trabajo con
`git stash pop`. Luego renderizó el tablero y comprobó que la verificación daba 16 de 16, subió sólo los archivos
revisados y, tras comprobar que nadie había subido nada, hizo `git push`. Su commit (`9f84684`) quedó encima del último
del equipo.
</details>

<details><summary><b>¿Por qué se reescribió el último commit?</b></summary>

Su mensaje tenía más de una línea y se quería dejar de una: `e3bd43f Correcciones finales`. Se hizo con
`git commit --amend` y `git push --force-with-lease`, que sólo sobrescribe si nadie más subió nada desde la última vez
que se descargó. Se hizo una sola vez y sólo con el último commit.
</details>
