FROM archlinux:latest

# ─── Initialize pacman keyring (required in Docker) ───────────────────
RUN pacman-key --init && \
    pacman-key --populate archlinux

# ─── System update + build tools ──────────────────────────────────────
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        archiso \
        base-devel \
        git \
        squashfs-tools \
        dosfstools \
        libisoburn \
        mtools \
        erofs-utils \
        grub \
        syslinux

# ─── Calamares build dependencies ─────────────────────────────────────
RUN pacman -S --noconfirm \
        cmake \
        ninja \
        extra-cmake-modules \
        qt6-base \
        qt6-declarative \
        qt6-svg \
        qt6-tools \
        qt6-translations \
        kcoreaddons \
        kpmcore \
        libpwquality \
        yaml-cpp \
        boost \
        boost-libs \
        icu \
        python

# ─── Create build user (makepkg can't run as root) ────────────────────
RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# ─── Build Calamares from source ──────────────────────────────────────
USER builder
WORKDIR /home/builder

RUN git clone https://github.com/calamares/calamares.git && \
    cd calamares && \
    LATEST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1) && \
    echo "Building Calamares ${LATEST_TAG}" && \
    git checkout "${LATEST_TAG}" && \
    mkdir build && cd build && \
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DWITH_QT6=ON \
        -DSKIP_MODULES="tracking interactiveterminal initramfs initramfscfg \
                         dracut dracutlukscfg \
                         dummycpp dummyprocess dummypython dummypythonqt \
                         plasmalnf plymouthcfg zfs zfshostid" && \
    ninja

# ─── Install to staging directory ─────────────────────────────────────
USER root
RUN cd /home/builder/calamares/build && \
    DESTDIR=/home/builder/calamares-staging ninja install

# ─── Package as pacman pkg and install it into the container ──────────
RUN mkdir -p /home/builder/pkgwork && \
    CALAM_VER=$(ls /home/builder/calamares-staging/usr/lib/libcalamares.so.*.* 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "3.3.14") && \
    echo "Packaging Calamares version: ${CALAM_VER}" && \
    printf '%s\n' \
        "pkgname=calamares-local" \
        "pkgver=${CALAM_VER}" \
        "pkgrel=1" \
        'pkgdesc="Calamares installer framework (locally compiled for ArchInstaller)"' \
        "arch=('x86_64')" \
        "license=('GPL-3.0-or-later')" \
        "depends=('kcoreaddons' 'kpmcore' 'libpwquality' 'qt6-declarative' 'qt6-svg' 'yaml-cpp' 'boost-libs' 'icu' 'qt6-base')" \
        "provides=('calamares')" \
        "conflicts=('calamares')" \
        "" \
        "package() {" \
        '    cp -a /home/builder/calamares-staging/* "$pkgdir"/' \
        "}" \
        > /home/builder/pkgwork/PKGBUILD && \
    chown -R builder:builder /home/builder/pkgwork && \
    cd /home/builder/pkgwork && \
    su builder -c "makepkg -f --nocheck --skipinteg" && \
    pacman -U --noconfirm /home/builder/pkgwork/calamares-local-3*.pkg.tar.zst && \
    cp /home/builder/pkgwork/calamares-local-3*.pkg.tar.zst /var/cache/pacman/pkg/ && \
    echo "Calamares installed successfully in container"

# ─── Entry point: patch profile and build ISO ─────────────────────────
WORKDIR /build

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
