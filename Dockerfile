FROM archlinux:latest

# Update and install build dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        archiso \
        git \
        base-devel \
        squashfs-tools \
        dosfstools \
        libisoburn \
        mtools \
        erofs-utils && \
    # Install Chaotic-AUR keyring and mirrorlist for Calamares
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 3056513887B78AEB && \
    pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
    # Add Chaotic-AUR to pacman.conf
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf && \
    pacman -Sy --noconfirm && \
    # Clean cache to reduce image size
    pacman -Scc --noconfirm

WORKDIR /build

ENTRYPOINT ["/bin/bash", "-c", "mkarchiso -v -w /tmp/archiso-work -o /build/out /build/profile"]
