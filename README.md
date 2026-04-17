# ArchInstaller — ISO de Arch Linux con Instalador Gráfico

ISO live personalizada de Arch Linux con [Calamares](https://calamares.io/) como instalador gráfico.
Bootea en un escritorio Xfce donde el usuario lanza Calamares para instalar un **sistema Arch Linux limpio y mínimo** — funcional y listo para personalizar.

## Filosofía

- **Mínimo y sin opiniones**: instala `base`, `linux`, `linux-firmware`, red, sudo y un bootloader. Nada más.
- **El usuario decide**: sin DE preinstalado, sin temas, sin bloat. Lo básico.
- **UX familiar**: Calamares ofrece la misma experiencia de instalador gráfico que Manjaro, EndeavourOS, etc.

## Qué se instala

| Componente        | Elección                        |
|-------------------|---------------------------------|
| Kernel            | `linux` (último estable)        |
| Bootloader        | GRUB (EFI + BIOS)              |
| Red               | NetworkManager                  |
| Shell             | bash                            |
| Init              | systemd                         |
| Helper AUR        | yay (opcional, habilitado por defecto) |
| Microcódigo       | Auto-detectado (AMD / Intel)    |
| Guest tools       | Auto-detectado (VirtualBox, VMware, QEMU, Hyper-V) |

## Requisitos

### Para buildear con Docker (recomendado, cualquier distro Linux)

- Docker o Podman
- `git`
- ~10 GB de espacio libre en disco
- Conexión a internet

### Para buildear en Arch Linux directamente

- `archiso`
- `git`
- Privilegios de root
- ~6 GB de espacio libre en disco
- Conexión a internet

## Construir la ISO

### Con Docker (recomendado — no toca tu sistema)

```bash
git clone https://github.com/EstebanKalo/automateArch.git
cd automateArch
./docker-build.sh
```

El Dockerfile compila Calamares desde source (Qt6/Ninja), lo empaqueta como `calamares-local`, y genera la ISO. La primera vez tarda ~15-30 minutos (compilación de Calamares). Las siguientes veces usan cache de Docker y tardan ~5 minutos.

### En Arch Linux directamente

```bash
sudo ./build.sh
```

> **Nota**: `build.sh` agrega temporalmente Chaotic-AUR a tu sistema. Usar `docker-build.sh` es más seguro.

### Opciones de build

```bash
sudo ./build.sh --no-yay        # No instalar yay en el sistema destino
sudo ./build.sh --clean          # Limpiar directorio de trabajo antes de buildear
```

La ISO se genera en `./out/`.

## Grabar la ISO en USB

```bash
# Pendrive USB (reemplazá /dev/sdX con tu dispositivo)
sudo dd bs=4M if=out/archinstaller-*.iso of=/dev/sdX status=progress oflag=sync

# O usá Ventoy, balenaEtcher, etc.
```

### VirtualBox (recomendado para testear)

1. Nueva máquina → Arch Linux (64-bit) → 4 GB RAM → Disco 20 GB
3. Settings → Storage → Cargar la ISO
5. Iniciar

## Cómo funciona

1. El usuario bootea la ISO → auto-login a una sesión live de Xfce (vía getty + startxfce4)
2. Calamares se abre automáticamente (o doble clic en "Install Arch Linux" en el escritorio)
3. Calamares guía paso a paso: Idioma → Teclado → Particionado → Configuración de usuario → Instalar
4. Por detrás, Calamares ejecuta `pacstrap` para instalar un sistema Arch limpio
5. Scripts de post-instalación configuran: sudoers, pacman (color + parallel downloads), GRUB, initramfs, mirrors (reflector), yay
6. Reinicio a una instalación de Arch limpia y mínima


## Personalización

### Cambiar paquetes instalados

Editá `profile/airootfs/etc/calamares/scripts/pacstrap.sh` — el array `PACKAGES` define qué se instala en el sistema destino.

### Cambiar el branding

Editá `profile/airootfs/etc/calamares/branding/archinstaller/branding.desc` para cambiar nombres, descripciones y colores.

### Agregar un hook de post-instalación

Editá `profile/airootfs/etc/calamares/scripts/post-install.sh` para agregar comandos que se ejecuten dentro del sistema instalado (vía arch-chroot).

### Cambiar paquetes del entorno live

Editá `profile/packages.x86_64` para agregar o quitar paquetes de la sesión live (no del sistema instalado).

## Problemas que tengo que corregir 

- **NetworkManager no se habilita automáticamente** en el sistema instalado. Después del primer boot, ejecutar: `sudo systemctl enable --now NetworkManager`
- **Timezone**: si seleccionás una región con sub-zonas (como Argentina), asegurate de elegir la ciudad específica en el dropdown de Calamares (falta config)
