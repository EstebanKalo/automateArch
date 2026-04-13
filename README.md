# ArchInstaller — ISO de Arch Linux con Instalador Gráfico

ISO live personalizada de Arch Linux con [Calamares](https://calamares.io/) como instalador gráfico.
Bootea en un escritorio Xfce liviano donde el usuario lanza Calamares para instalar un **sistema Arch Linux limpio y mínimo** — funcional y listo para personalizar.

## Filosofía

- **Mínimo y sin opiniones**: instala `base`, `linux`, `linux-firmware`, red, sudo y un bootloader. Nada más.
- **El usuario decide**: sin DE preinstalado, sin temas, sin bloat. El sistema instalado es un lienzo en blanco.
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

## Requisitos

Para **buildear** la ISO necesitás un sistema Arch Linux existente (o cualquier distro basada en Arch) con:

- `archiso` (herramienta oficial para construir ISOs)
- `git`
- Privilegios de root
- ~6 GB de espacio libre en disco
- Conexión a internet

## Construir la ISO

```bash
git clone https://github.com/EstebanKalo/automateArch.git
cd automateArch
sudo ./build.sh
```

La ISO se genera en `./out/`.

### Opciones de build

```bash
sudo ./build.sh --no-yay         # No instalar yay en el sistema destino
sudo ./build.sh --clean          # Limpiar directorio de trabajo antes de buildear
```

## Grabar la ISO en USB

```bash
# Pendrive USB (reemplazá /dev/sdX con tu dispositivo)
sudo dd bs=4M if=out/archinstaller-*.iso of=/dev/sdX status=progress oflag=sync

# O usá Ventoy, balenaEtcher, etc.
```

## Cómo funciona

1. El usuario bootea la ISO → auto-login a una sesión live de Xfce
2. Doble clic en "Install Arch Linux" en el escritorio (o se abre automáticamente)
3. Calamares guía paso a paso: Idioma → Teclado → Particionado → Configuración de usuario → Instalar
4. Por detrás, Calamares ejecuta `pacstrap` para instalar un sistema Arch limpio (sin extracción de imagen)
5. Scripts de post-instalación configuran: fstab, locale, bootloader, microcódigo, creación de usuario, habilitación de servicios
6. Reinicio a una instalación de Arch limpia y mínima

## Estructura del proyecto

```
automateArch/
├── build.sh                          # Script de construcción de la ISO
├── README.md
└── profile/
    ├── profiledef.sh                 # Definición del perfil archiso
    ├── packages.x86_64               # Paquetes para el entorno LIVE
    ├── pacman.conf                   # pacman.conf usado durante el build de la ISO
    └── airootfs/                     # Overlay para el filesystem live
        └── etc/
            ├── calamares/
            │   ├── settings.conf     # Config principal de Calamares (secuencia de módulos)
            │   ├── branding/         # Branding de la UI (nombre, logo, colores)
            │   ├── modules/          # Configuración por módulo
            │   └── scripts/          # Scripts de shell llamados por Calamares
            ├── skel/Desktop/         # Acceso directo del instalador en el escritorio
            ├── systemd/system/       # Configuración de auto-login
            └── xdg/autostart/        # Auto-lanzamiento de Calamares al iniciar sesión
```

## Personalización

### Cambiar paquetes instalados

Editá `profile/airootfs/etc/calamares/scripts/pacstrap.sh` — el array `PACKAGES` define qué se instala en el sistema destino.

### Cambiar el branding

Editá `profile/airootfs/etc/calamares/branding/archinstaller/branding.desc` para cambiar nombres, descripciones y colores.

### Agregar un hook de post-instalación

Editá `profile/airootfs/etc/calamares/scripts/post-install.sh` para agregar comandos que se ejecuten dentro del sistema instalado (vía arch-chroot).

## Licencia

MIT

## Créditos

- [Arch Linux](https://archlinux.org/) y [archiso](https://wiki.archlinux.org/title/Archiso)
- Framework de instalación [Calamares](https://calamares.io/)
- Inspirado en los flujos de instalación de EndeavourOS y Manjaro
