# Comandos para Fedora, en orden

Copia y pega de arriba hacia abajo en la Terminal de Fedora.

## 1. Instalar todo

Primero inicia sesión en GitHub (se abre el navegador); así también quedan listos tus repos privados.

```bash
sudo dnf install -y git gh
gh auth login
gh auth setup-git
gh repo clone Basty66/fedora-setup
cd fedora-setup
chmod +x setup.sh clonar-proyectos.sh
./setup.sh
sudo reboot
```

Al reiniciar, si aparece la **pantalla azul (MOK)** tienes ~10 segundos: presiona una tecla →
**Enroll MOK** → **Continue** → **Yes** → contraseña temporal → **Reboot**.

## 2. Comprobar que todo funciona

```bash
nvidia-smi
docker run --rm hello-world
docker compose version
node -v && java -version && code --version
```

## 3. Descargar todos tus proyectos

```bash
cd ~/fedora-setup
./clonar-proyectos.sh
```

Quedan en `~/Proyectos`. Los repos con trabajo que no habías subido lo tienen en una rama de respaldo:

```bash
cd ~/Proyectos/paulina-store
git branch -r
git switch respaldo/pre-fedora
```

## 4. Recuperar los secretos

Descarga `RESPALDO-SECRETOS` desde tu Google Drive (queda en `~/Descargas`) y descomprímelo:

```bash
sudo dnf install -y p7zip p7zip-plugins
7z x ~/Descargas/RESPALDO-SECRETOS.* -o"$HOME/respaldo-secretos"
```

Llaves SSH, AWS y Kubernetes (Linux exige permisos estrictos en `.ssh`):

```bash
cp -r ~/respaldo-secretos/.ssh ~/respaldo-secretos/.aws ~/respaldo-secretos/.kube ~/
chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
```

Los `.env` mantienen la ruta que tenían en Windows. Para verlos todos y copiar cada uno a su proyecto:

```bash
find ~/respaldo-secretos -name ".env*"
cp ~/respaldo-secretos/Desktop/paulina/.env ~/Proyectos/paulina-store/
```

Ojo: algunas carpetas de Windows tienen otro nombre que el repo (por ejemplo `paulina` → `paulina-store`,
`floreria` → `dolce-fiore`, `tatuajes` → `ms-estudio-tatuajes`, `medina` → `isy1102-cuidarte`).

Los proyectos `barberias-app` y `dashu-store` completos, con su historial, están en
`~/respaldo-secretos/repos-con-claves/`.

## 5. Bases de datos locales

```bash
docker compose -f ~/fedora-setup/servicios/docker-compose.yml up -d mysql      # root / root
docker compose -f ~/fedora-setup/servicios/docker-compose.yml up -d postgres   # postgres / postgres
docker compose -f ~/fedora-setup/servicios/docker-compose.yml up -d rabbitmq   # guest / guest
docker compose -f ~/fedora-setup/servicios/docker-compose.yml down             # apagarlas
```

## 6. Mantenimiento

Actualizar todo (una vez a la semana):

```bash
sudo dnf upgrade --refresh
flatpak update
```

Pasar a la siguiente versión de Fedora (una vez al año; cambia 45 por la versión nueva):

```bash
sudo dnf upgrade --refresh
sudo dnf system-upgrade download --releasever=45
sudo dnf offline reboot
```

## Si algo falla

| Problema | Comando |
|---|---|
| `permission denied` con Docker | `newgrp docker` (o reinicia) |
| `nvidia-smi` no funciona | `mokutil --sb-state` y luego `sudo mokutil --import /etc/pki/akmods/certs/public_key.der` y reinicia |
| Volver a correr el instalador | `cd ~/fedora-setup && ./setup.sh` |
