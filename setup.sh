#!/usr/bin/env bash
# =============================================================================
#  setup.sh — Instala mi entorno de desarrollo en Fedora Workstation
#  Equipo: ASUS TUF F15 (i5 12va gen, RTX 3050, 32 GB RAM)
#
#  Uso (con tu usuario normal, NO con sudo):
#      ./setup.sh
#
#  Es seguro ejecutarlo varias veces: lo que ya está instalado se salta.
# =============================================================================

set -Eeuo pipefail

# ─── Configuración: edita esto a tu gusto ────────────────────────────────────

GIT_USER_NAME="Basty66"
GIT_USER_EMAIL="cri.cerdaa@duocuc.cl"

# Paquetes de los repositorios de Fedora
PAQUETES_DNF=(
  # Base
  git git-lfs gh curl wget unzip
  # GNOME
  gnome-tweaks
  # Lenguajes (tus proyectos usan Node 22, Python 3 y Java 17/21)
  nodejs npm python3-pip pipx java-21-openjdk-devel maven
  # Lo que necesitan tus librerías (ver STACK.md): compilar módulos nativos de npm/pip,
  # psycopg (libpq), el paquete graphviz de Python y el cliente psql
  gcc gcc-c++ make python3-devel libpq-devel graphviz postgresql
  # DevOps (en Windows tenías kubectl y AWS CLI)
  kubernetes-client awscli2
  # Apps (sus repositorios se agregan en configurar_repositorios)
  code google-chrome-stable
)

# Apps de Flathub
FLATPAKS=(
  com.spotify.Client               # Spotify
  com.mattjakeman.ExtensionManager # Extension Manager (extensiones de GNOME)
)

# ─── Utilidades ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LISTAS="$SCRIPT_DIR/listas"
LOG="$SCRIPT_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
MOK_PENDIENTE=0
AVISOS=()

paso()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m  ✔ %s\033[0m\n' "$*"; }
aviso() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; AVISOS+=("$*"); }
error() { printf '\033[1;31m  ✘ %s\033[0m\n' "$*" >&2; }

al_fallar() {
  error "Falló la línea $1: $2"
  error "Revisa el log: $LOG"
  error "Corrige el problema y vuelve a ejecutar ./setup.sh (es seguro repetirlo)."
}
trap 'al_fallar $LINENO "$BASH_COMMAND"' ERR

# Lee una lista de listas/ ignorando comentarios, líneas vacías y finales de línea de Windows
leer_lista() {
  sed -e 's/^\xEF\xBB\xBF//' -e 's/\r$//' -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" \
    | grep -v '^[[:space:]]*$' || true
}

# ─── Pasos ───────────────────────────────────────────────────────────────────

comprobar_requisitos() {
  if [[ $EUID -eq 0 ]]; then
    error "No ejecutes este script con sudo. Úsalo así: ./setup.sh"
    exit 1
  fi
  # shellcheck source=/dev/null
  . /etc/os-release
  if [[ "${ID:-}" != "fedora" ]]; then
    error "Este script es solo para Fedora (detectado: ${PRETTY_NAME:-desconocido})."
    exit 1
  fi
  if (( ${VERSION_ID:-0} < 41 )); then
    error "Necesitas Fedora 41 o superior (tienes $VERSION_ID)."
    exit 1
  fi
}

mantener_sudo() {
  echo "Se pedirá tu contraseña una sola vez para todo el proceso."
  sudo -v
  # Renueva sudo en segundo plano para que no la vuelva a pedir a mitad del proceso
  while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

actualizar_sistema() {
  paso "Actualizando el sistema (puede tardar varios minutos)"
  sudo dnf update -y
  ok "Sistema actualizado."
}

configurar_repositorios() {
  paso "Repositorios: RPM Fusion, Flathub, VS Code y Google Chrome"

  if rpm -q rpmfusion-free-release rpmfusion-nonfree-release &>/dev/null; then
    ok "RPM Fusion ya estaba activado."
  else
    local version
    version="$(rpm -E %fedora)"
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${version}.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${version}.noarch.rpm"
    ok "RPM Fusion activado (free + nonfree)."
  fi

  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  # Fedora trae Flathub "filtrado" (solo algunas apps); esto lo deja completo
  sudo flatpak remote-modify --enable --no-filter flathub
  ok "Flathub activado."

  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  ok "Repositorio de VS Code agregado."

  sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
enabled=1
EOF
  ok "Repositorio de Google Chrome agregado."
}

registrar_llave_secure_boot() {
  local llave=/etc/pki/akmods/certs/public_key.der
  sudo kmodgenca -a
  if sudo mokutil --test-key "$llave" 2>&1 | grep -qi 'already enrolled'; then
    ok "La llave que firma el driver ya está registrada en Secure Boot."
    return
  fi
  echo
  echo "  Secure Boot está activo: el driver NVIDIA debe ir firmado con una llave registrada."
  echo "  mokutil te pedirá una contraseña TEMPORAL dos veces. Usa solo números, ej: 12345678"
  echo "  (en la pantalla de registro el teclado está en inglés). La usarás UNA vez al reiniciar."
  sudo mokutil --import "$llave" </dev/tty >/dev/tty 2>&1 \
    || aviso "mokutil no registró la llave. Repite a mano: sudo mokutil --import $llave"
  if sudo mokutil --list-new 2>/dev/null | grep -qi 'fingerprint'; then
    MOK_PENDIENTE=1
  fi
}

instalar_nvidia() {
  paso "Drivers NVIDIA (RTX 3050) desde RPM Fusion"
  sudo dnf install -y pciutils akmods kmodtool mokutil openssl
  if ! lspci | grep -qi nvidia; then
    aviso "No se detectó una GPU NVIDIA; salto los drivers."
    return
  fi

  if mokutil --sb-state 2>/dev/null | grep -qi 'SecureBoot enabled'; then
    registrar_llave_secure_boot
  fi

  # akmod-nvidia recompila el driver solo en cada actualización de kernel; -cuda trae nvidia-smi
  sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

  # Compila el módulo para el kernel más nuevo (el que arrancará al reiniciar)
  local kernel
  kernel="$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -n1)"
  echo "  Compilando el módulo NVIDIA para el kernel $kernel (5-10 min, no apagues el equipo)..."
  sudo akmods --force --kernels "$kernel" >>"$LOG" 2>&1 || true
  if modinfo -F version nvidia -k "$kernel" &>/dev/null; then
    ok "Driver NVIDIA $(modinfo -F version nvidia -k "$kernel") listo para el próximo arranque."
  else
    aviso "El módulo NVIDIA aún no está compilado. Tras reiniciar espera 5 min y prueba: nvidia-smi"
  fi
}

instalar_paquetes() {
  paso "Herramientas base, lenguajes, VS Code y Google Chrome"
  # --skip-unavailable: si un paquete cambió de nombre en tu versión de Fedora, sigue con el resto
  sudo dnf install -y --skip-unavailable "${PAQUETES_DNF[@]}"
  if ! rpm -q java-21-openjdk-devel &>/dev/null; then
    aviso "Java 21 no está en este Fedora; instalé la versión más nueva (compila proyectos 17/21 igual)."
    sudo dnf install -y java-latest-openjdk-devel
  fi
  ok "Paquetes instalados."
}

instalar_docker() {
  paso "Docker + Docker Compose"
  if rpm -q docker-ce &>/dev/null || rpm -q moby-engine &>/dev/null; then
    ok "Docker ya estaba instalado."
  elif sudo curl -fsSL -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/fedora/docker-ce.repo \
    && sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    ok "Docker CE instalado desde el repositorio oficial."
  else
    # Cuando sale un Fedora nuevo, Docker tarda unas semanas en publicar su repositorio
    sudo rm -f /etc/yum.repos.d/docker-ce.repo
    aviso "El repo oficial de Docker no está disponible para este Fedora; usé el de Fedora (moby-engine)."
    sudo dnf install -y moby-engine docker-compose
  fi

  sudo systemctl enable --now docker

  # Permite usar docker sin sudo (se activa al cerrar sesión o reiniciar)
  if id -nG "$USER" | grep -qw docker; then
    ok "Tu usuario ya está en el grupo docker."
  else
    sudo usermod -aG docker "$USER"
    ok "Usuario $USER agregado al grupo docker."
  fi
}

instalar_terraform() {
  paso "Terraform (repositorio de HashiCorp)"
  if command -v terraform &>/dev/null; then
    ok "Terraform ya estaba instalado."
  elif sudo curl -fsSL -o /etc/yum.repos.d/hashicorp.repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo \
    && sudo dnf install -y terraform; then
    ok "Terraform instalado."
  else
    sudo rm -f /etc/yum.repos.d/hashicorp.repo
    aviso "No se pudo instalar Terraform (HashiCorp tarda en soportar Fedoras nuevos). Alternativa: sudo dnf install opentofu"
  fi
}

instalar_flatpaks() {
  paso "Apps de Flathub: Spotify y Extension Manager"
  sudo flatpak install -y --noninteractive flathub "${FLATPAKS[@]}"
  ok "Flatpaks instalados."
}

instalar_extensiones_vscode() {
  paso "Extensiones de VS Code (listas/vscode-extensions.txt)"
  local extensiones ext i=0 fallidas=()
  mapfile -t extensiones < <(leer_lista "$LISTAS/vscode-extensions.txt")
  for ext in "${extensiones[@]}"; do
    i=$((i + 1))
    printf '  [%d/%d] %s\n' "$i" "${#extensiones[@]}" "$ext"
    code --install-extension "$ext" --force >>"$LOG" 2>&1 || fallidas+=("$ext")
  done
  ok "$(( ${#extensiones[@]} - ${#fallidas[@]} )) de ${#extensiones[@]} extensiones instaladas."
  if (( ${#fallidas[@]} )); then
    aviso "Extensiones que fallaron (quizás ya no existen en el Marketplace): ${fallidas[*]}"
  fi
}

instalar_npm_globales() {
  paso "Paquetes globales de npm (listas/npm-global.txt)"
  # Los globales van a ~/.local (sin sudo); Fedora ya tiene ~/.local/bin en el PATH
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
  local paquetes paquete fallidos=()
  mapfile -t paquetes < <(leer_lista "$LISTAS/npm-global.txt")
  for paquete in "${paquetes[@]}"; do
    echo "  npm install -g $paquete"
    npm install -g "$paquete" >>"$LOG" 2>&1 || fallidos+=("$paquete")
  done
  if (( ${#fallidos[@]} )); then
    aviso "Paquetes npm que fallaron: ${fallidos[*]}"
  else
    ok "${#paquetes[@]} paquetes globales instalados."
  fi
}

configurar_git() {
  paso "Configuración de Git"
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  git lfs install >/dev/null
  ok "Git: $GIT_USER_NAME <$GIT_USER_EMAIL> + Git LFS"
}

verificar() {
  paso "Verificación"
  local herramienta app
  for herramienta in git gh docker code google-chrome-stable node npm java mvn kubectl aws terraform; do
    if command -v "$herramienta" &>/dev/null; then
      ok "$herramienta"
    else
      aviso "$herramienta no quedó instalado"
    fi
  done
  if docker compose version &>/dev/null; then ok "docker compose"; else aviso "docker compose no responde"; fi
  for app in "${FLATPAKS[@]}"; do
    if flatpak info "$app" &>/dev/null; then ok "$app"; else aviso "$app no quedó instalado"; fi
  done
}

resumen() {
  paso "¡Listo!"
  if (( ${#AVISOS[@]} )); then
    echo "  Revisa estos avisos:"
    printf '   - %s\n' "${AVISOS[@]}"
  fi
  echo "  Log completo: $LOG"
  echo
  echo "  SIGUIENTE PASO: reinicia el equipo  →  sudo reboot"
  if (( MOK_PENDIENTE )); then
    cat <<'EOF'

  Al reiniciar aparecerá una PANTALLA AZUL (MOK management). Tienes ~10 segundos:
  presiona una tecla y luego:  Enroll MOK → Continue → Yes → contraseña temporal → Reboot
  Si se te pasa, el driver NVIDIA no cargará. Repite con:
      sudo mokutil --import /etc/pki/akmods/certs/public_key.der   y reinicia.
EOF
  fi
}

main() {
  comprobar_requisitos
  exec > >(tee -a "$LOG") 2>&1
  mantener_sudo
  actualizar_sistema
  configurar_repositorios
  instalar_nvidia
  instalar_paquetes
  instalar_docker
  instalar_terraform
  instalar_flatpaks
  instalar_extensiones_vscode
  instalar_npm_globales
  configurar_git
  verificar
  resumen
}

main "$@"
