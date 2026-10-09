#!/usr/bin/env bash
# =============================================================================
#  clonar-proyectos.sh — Clona todos mis repos de GitHub en ~/Proyectos
#
#  Uso (después de "gh auth login"):
#      ./clonar-proyectos.sh              # en ~/Proyectos
#      ./clonar-proyectos.sh ~/otra-ruta
# =============================================================================

set -euo pipefail

DESTINO="${1:-$HOME/Proyectos}"

if ! gh auth status &>/dev/null; then
  echo "Primero inicia sesión en GitHub:  gh auth login  y luego  gh auth setup-git"
  exit 1
fi

mkdir -p "$DESTINO"
cd "$DESTINO"

gh repo list --limit 500 --json nameWithOwner --jq '.[].nameWithOwner' | while read -r repo; do
  nombre="${repo#*/}"
  if [[ -d "$nombre" ]]; then
    echo "  ya existe: $nombre"
    continue
  fi
  echo "  clonando $repo"
  gh repo clone "$repo" "$nombre" -- --quiet </dev/null
  # Ramas con el trabajo que estaba sin subir antes de formatear Windows
  if git -C "$nombre" branch -r --list 'origin/respaldo/*' | grep -q .; then
    echo "    ↳ tiene ramas respaldo/* con trabajo pendiente: revísalas con  git branch -r"
  fi
done

echo
echo "Listo: tus proyectos están en $DESTINO"
echo "Recuerda copiar los .env desde RESPALDO-SECRETOS.zip a cada proyecto."
