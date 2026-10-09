# fedora-setup

Mi entorno de desarrollo en **Fedora Workstation** con un solo comando.

Equipo: ASUS TUF F15 · Intel i5 12va gen · NVIDIA RTX 3050 · 32 GB RAM

## Qué instala `setup.sh`

| Área | Qué hace |
|---|---|
| Sistema | `dnf update`, activa **RPM Fusion** (free + nonfree) y **Flathub** completo |
| GPU | Driver NVIDIA (`akmod-nvidia` + `nvidia-smi`), firmado para **Secure Boot** |
| Base | Git, Git LFS, GitHub CLI (`gh`), Curl, Wget |
| Contenedores | **Docker** + **Docker Compose**, usable sin `sudo` |
| Apps | **VS Code**, **Google Chrome**, **Spotify** (Flatpak) |
| GNOME | **GNOME Tweaks** y **Extension Manager** (Flatpak) |
| Lenguajes | Node.js + npm, Python 3 + pip + pipx, Java 21 + Maven |
| DevOps | kubectl, AWS CLI, Terraform |
| Restauración | Mis extensiones de VS Code y paquetes globales de npm (desde `listas/`) |

## 1. Antes de formatear Windows

> Formatear borra todo lo que **no** esté en GitHub o en un disco externo.

1. **Sube tu trabajo pendiente.** En cada repo con cambios, **primero revisa** qué se va a subir:
   ```bash
   git status
   ```
   Si aparece `.env`, `credentials.json`, `*.pem` o `node_modules/`, agrégalos a su `.gitignore`
   antes de seguir. Lo que llega a GitHub queda en el historial aunque lo borres después. Luego:
   ```bash
   git add .
   git commit -m "Respaldo antes de migrar a Fedora"
   git push
   ```
   Los repos sin remoto se suben con `gh repo create <nombre> --private --source=. --push`.

2. **Ejecuta el respaldo** (en PowerShell, desde esta carpeta). Muestra lo que no está en GitHub,
   regenera `listas/` y copia secretos (`.env`, llaves) y proyectos a un disco externo:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows\respaldo.ps1 -Destino "E:\respaldo-windows"
   ```

3. **Haz commit y push de este repo** si las listas cambiaron.

4. **Prueba Fedora en modo Live USB** antes de borrar nada: Wi-Fi, touchpad, brillo,
   audio, cámara y suspensión.

### Auditoría manual

Los comandos que usa el script, por si quieres verlos tú mismo:

```powershell
npm ls -g --depth=0                    # paquetes globales de Node.js
python -m pip list --not-required      # paquetes de Python instalados por ti
code --list-extensions                 # extensiones de VS Code
git config --global --list             # configuración de Git
```

## 2. Instalación en Fedora

> Todos los comandos, en orden y listos para copiar: **[COMANDOS-FEDORA.md](COMANDOS-FEDORA.md)**

En una instalación limpia, abre la Terminal y ejecuta:

```bash
sudo dnf install -y git gh
gh auth login
gh auth setup-git
gh repo clone Basty66/fedora-setup
cd fedora-setup
chmod +x setup.sh
./setup.sh
```

- Ejecútalo con tu usuario normal, **no** con `sudo`. Pide la contraseña una sola vez.
- Tarda entre 20 y 40 minutos según tu internet.
- Si **Secure Boot** está activo, te pedirá una **contraseña temporal** para registrar la llave
  del driver NVIDIA. Usa solo números (ej. `12345678`).
- Si algo falla, el mensaje indica la línea y el log (`setup-FECHA.log`). Corrige y vuelve a
  ejecutar `./setup.sh`: es seguro repetirlo.

## 3. Después de reiniciar

1. **Pantalla azul "MOK management"** (solo con Secure Boot). Tienes ~10 segundos:
   presiona una tecla → **Enroll MOK** → **Continue** → **Yes** → contraseña temporal → **Reboot**.

2. **Comprueba que todo funciona:**
   ```bash
   nvidia-smi
   docker run --rm hello-world
   ```

3. **Recupera todos tus proyectos** en `~/Proyectos`:
   ```bash
   chmod +x clonar-proyectos.sh
   ./clonar-proyectos.sh
   ```
   Luego copia los `.env` de cada proyecto desde `RESPALDO-SECRETOS.zip`. Los repos que tenían
   trabajo sin subir lo tienen en ramas `respaldo/pre-fedora` (revisa con `git branch -r`).

4. **Python:** no instales paquetes globales. Cada proyecto usa su propio entorno virtual:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
   `listas/pip-packages.txt` queda solo como referencia de lo que tenías en Windows.

## Personalizar

- **Paquetes y apps:** edita `PAQUETES_DNF` y `FLATPAKS` al inicio de `setup.sh`.
- **Git:** cambia `GIT_USER_NAME` y `GIT_USER_EMAIL` en `setup.sh`.
- **Extensiones / npm:** edita `listas/vscode-extensions.txt` y `listas/npm-global.txt`
  (una por línea; `#` para comentarios).

## Problemas comunes

| Problema | Solución |
|---|---|
| `permission denied ... docker.sock` | El grupo `docker` se activa al reiniciar. Mientras tanto: `newgrp docker` |
| `nvidia-smi` falla | Revisa `mokutil --sb-state`. Si la llave no se registró: `sudo mokutil --import /etc/pki/akmods/certs/public_key.der`, reinicia y completa la pantalla azul |
| Pantalla negra tras instalar NVIDIA | En el menú de GRUB elige el kernel anterior y ejecuta `sudo akmods --force` |
| Falla el repo de Docker o Terraform | Pasa en un Fedora recién lanzado. El script usa los paquetes de Fedora como alternativa |
| Una extensión de VS Code falla | Puede haber sido retirada del Marketplace. Bórrala de la lista |

## Extras para la ASUS TUF (opcional)

El proyecto [asus-linux.org](https://asus-linux.org) da control de ventiladores, límite de carga
de batería y modo de GPU:

```bash
sudo dnf copr enable lukenukem/asus-linux
sudo dnf install asusctl supergfxctl
sudo systemctl enable --now supergfxd
asusctl -c 80   # carga máxima al 80 %, alarga la vida de la batería
```

## Estructura

```
fedora-setup/
├── COMANDOS-FEDORA.md       # todos los comandos para Fedora, en orden
├── setup.sh                 # instalador para Fedora
├── clonar-proyectos.sh      # clona todos mis repos en ~/Proyectos
├── STACK.md                 # mis librerías y dependencias habituales
├── servicios/
│   └── docker-compose.yml   # MySQL, PostgreSQL y RabbitMQ locales
├── listas/
│   ├── vscode-extensions.txt
│   ├── npm-global.txt
│   └── pip-packages.txt     # solo referencia
└── windows/
    └── respaldo.ps1         # auditoría y respaldo antes de formatear
```
