# 14. Publicación en GitHub, paso a paso

[← El dashboard](13_dashboard.md) · [Índice](README.md) · [Siguiente: limitaciones →](15_limitaciones_y_extensiones.md)

Este capítulo documenta **cómo se publicó el proyecto, tal como ocurrió**: cada comando, qué hace,
qué respondió y por qué se hizo así. Todo pasó el **martes 22 de septiembre de 2026** (horas del
centro de México). Al final hay una tabla de errores frecuentes y la equivalencia con lo visto en
clase (RStudio, `gitcreds`, flujo de R).

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
| (pendiente) | 12. Repositorio privado del equipo | `pitirringo/futbol-apuestas-defensa` |

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

```yaml
name: Publicar dashboard en GitHub Pages     # nombre que aparece en la pestaña Actions

on:
  push:
    branches: [main]          # se ejecuta en cada push a main
  workflow_dispatch:          # y también a mano (botón "Run workflow" en Actions)
```

A diferencia del flujo de clase, **no se ejecuta en `pull_request`**, porque un *pull request* no
debe publicar el sitio.

```yaml
permissions:
  contents: read              # leer el repositorio
  pages: write                # publicar en Pages
  id-token: write             # token de identidad que exige deploy-pages

concurrency:
  group: "pages"
  cancel-in-progress: false   # si hay dos pushes seguidos, no se interrumpe un despliegue a medias
```

```yaml
jobs:
  build:
    runs-on: ubuntu-latest    # la máquina virtual (runner)
    steps:
      - name: Clonar repositorio
        uses: actions/checkout@v6               # descarga el repo en el runner

      - name: Instalar Quarto (misma versión con la que se desarrolló)
        uses: quarto-dev/quarto-actions/setup@v2
        with:
          version: 1.8.25                       # la misma versión local: mismo resultado

      - name: Instalar Python 3.10 (misma versión del equipo)
        uses: actions/setup-python@v5
        with:
          python-version: "3.10"
          cache: pip                            # guarda los paquetes entre ejecuciones
          cache-dependency-path: Dashboard-o-pagina/requirements.txt

      - name: Instalar paquetes de Python
        run: pip install -r Dashboard-o-pagina/requirements.txt   # versiones fijas

      - name: Renderizar dashboard (recalcula todo desde los datos del equipo)
        run: quarto render Dashboard-o-pagina   # ejecuta el código y genera _site/

      - name: Configurar GitHub Pages
        uses: actions/configure-pages@v5

      - name: Subir el sitio generado
        uses: actions/upload-pages-artifact@v4  # empaqueta _site como artifact
        with:
          path: Dashboard-o-pagina/_site

  deploy:
    needs: build                                # solo si build terminó bien
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}   # la URL aparece en el resumen del flujo
    steps:
      - name: Desplegar en GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4           # publica el artifact
```

- `uses:` ejecuta una **acción** ya hecha por alguien más (formato `autor/nombre@versión`).
- `run:` ejecuta un comando en la terminal del runner.
- `needs: build` hace que un tablero roto nunca se publique.

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
| — | `concurrency: pages` | Evita dos despliegues simultáneos |

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



### Verificación final

| Qué | Resultado |
|---|---|
| Commits en `main` (consultado en la API de GitHub) | **1**: `8b1fc83` |
| Archivos en `Dashboard-o-pagina/` | 9, sin `DECISIONES.md` ni `GUIA_DEFENSA.md` |
| Flujo #35812702955 | ✓ en unos 2 minutos |
| Sitio publicado | HTTP 200; redibujado corregido presente; zoom desactivado en todas las gráficas; **0 menciones** a DECISIONES o GUIA_DEFENSA |



## 14.12 Equivalencias con RStudio y con lo visto en clase

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

Si el tablero se hubiera hecho en **Flexdashboard**, el flujo sería prácticamente el `deploy.yml` de
la clase: `setup-r`, `setup-pandoc`, `install.packages(...)` y
`rmarkdown::render("dashboard.Rmd", output_file = "index.html", output_dir = "_site")`, con los
mismos tres pasos finales de Pages.

## 14.16 Errores frecuentes y cómo resolverlos

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

## 14.17 Preguntas que pueden hacer sobre la publicación

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
así, las 15 cifras de control coinciden con el notebook y el reporte (pestaña *Reproducibilidad*).
Las versiones de Python, Quarto y cada paquete están fijadas.
</details>

<details><summary><b>¿Qué es un commit y qué hace <code>git push</code>?</b></summary>

Un commit es una versión guardada del proyecto, con autor, fecha y mensaje. `git push` sube los
commits locales al repositorio de GitHub. En nuestro caso, además, dispara el flujo que republica el
tablero.
</details>

<details><summary><b>¿Qué pasa si alguien sube un cambio que rompe el tablero?</b></summary>

El job `build` falla y, como `deploy` tiene `needs: build`, **no se publica nada**: el sitio sigue
mostrando la última versión buena. El error aparece en rojo en la pestaña Actions, con el paso que
falló.
</details>

<details><summary><b>¿Por qué el repositorio tiene un solo commit?</b></summary>

El historial se reescribió a propósito para separar el entregable público del material interno de
preparación del equipo, que vive en un repositorio privado. El commit declara la coautoría de la IA
por transparencia.
</details>
