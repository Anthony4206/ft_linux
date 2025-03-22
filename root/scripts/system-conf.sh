#/bin/sh

# LFS Bootscripts
tar -xf lfs-bootscripts-20180820.tar.bz2
cd lfs-bootscripts-20180820
make install
cd /sources
rm -rf lfs-bootscripts-20180820

# Hostname
echo "alevasse" > /etc/hostname
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost
127.0.1.1 alevasse.local alevasse

::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

# System V
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF

cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

KEYMAP="us"
FONT="lat0-16 -m 8859-1"
UNICODE="1"

# End /etc/sysconfig/console
EOF

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sdb3      /            ext4     defaults            1     1
/dev/sdb1      /boot        ext4     defaults            0     2
/dev/sdb2      swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
# Bash configtmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF

# Kernel
cd /sources
tar -xf linux-4.18.5.tar.xz
cd linux-4.18.5
make mrproper
make defconfig
sed -i 's/^EXTRAVERSION =/EXTRAVERSION = -alevasse/' Makefile
make
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-4.18.5-alevasse
cp -iv System.map /boot/System.map-4.18.5
cp -iv .config /boot/config-4.18.5
install -d /usr/share/doc/linux-4.18.5
cp -r Documentation/* /usr/share/doc/linux-4.18.5
chown -R 0:0 ../linux-4.18.5
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
grub-install /dev/sdb
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext4
set root=(hd1,1)

menuentry "GNU/Linux, Linux 4.18.5-alevasse" {
        linux   /vmlinuz-4.18.5-alevasse root=/dev/sda3 ro
}
EOF
mv /sources/linux-4.18.5 /usr/src/kernel-4.18.5
echo 8.3 > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="8.3"
DISTRIB_CODENAME="alevasse"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

# Wget -> Move in the chapter 5 later
wget -P /mnt/lfs/sources https://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz
cd /mnt/lfs/sources/
checksum_res=$(md5sum wget-1.19.5.tar.gz | awk '{ print $1 }')
if [ "$checksum_res" == "2db6f03d655041f82eb64b8c8a1fa7da" ]; then
    echo "Checksum OK!"
else
    echo "Checksum not OK!"
fi
cd /sources
tar -xf wget-1.19.5.tar.gz
cd wget-1.19.5
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make
make check
make install
cd /sources
rm wget-1.19.5

# dhcpcd
tar -xf dhcpcd-7.0.7.tar.xz
cd dhcpcd-7.0.7
./configure --libexecdir=/lib/dhcpcd \
            --dbdir=/var/lib/dhcpcd  &&
make
make install
cd /sources
tar -xf blfs-bootscripts-20180105.tar.xz
cd blfs-bootscripts-20180105
make install-service-dhcpcd
cat > /etc/sysconfig/ifconfig.enp0s3 << "EOF"
ONBOOT="yes"
IFACE="enp0s3"
SERVICE="dhcpcd"
EOF
cd /sources
rm -rf dhcpcd-7.0.7

# WGET REQUIREMENTS OTHER TOOLS
wget http://anduin.linuxfromscratch.org/BLFS/gpm/gpm-1.20.7.tar.bz2
wget https://www.linuxfromscratch.org/patches/downloads/gpm/gpm-1.20.7-glibc_2.26-1.patch
wget https://www.kernel.org/pub/software/scm/git/git-2.18.0.tar.xz
wget http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.7p1.tar.gz
wget https://www.linuxfromscratch.org/patches/downloads/openssh/openssh-7.7p1-openssl-1.1.0-1.patch
wget https://curl.haxx.se/download/curl-7.61.0.tar.xz
chown -R root:root /sources/lfs/sources/*

### Install other tools ###
cd /sources/blfs/sources
tar -xf blfs-bootscripts-20180105.tar.xz
# GPM
tar -xf gpm-1.20.7.tar.bz2
cd gpm-1.20.7
sed -i -e 's:<gpm.h>:"headers/gpm.h":' \
src/prog/{display-buttons,display-coords,get-versions}.c &&
patch -Np1 -i ../gpm-1.20.7-glibc_2.26-1.patch &&
./autogen.sh                                &&
./configure --prefix=/usr --sysconfdir=/etc &&
make
make install                                          &&

install-info --dir-file=/usr/share/info/dir           \
             /usr/share/info/gpm.info                 &&

ln -sfv libgpm.so.2.1.0 /usr/lib/libgpm.so            &&
install -v -m644 conf/gpm-root.conf /etc              &&

install -v -m755 -d /usr/share/doc/gpm-1.20.7/support &&
install -v -m644    doc/support/*                     \
                    /usr/share/doc/gpm-1.20.7/support &&
install -v -m644    doc/{FAQ,HACK_GPM,README*}        \
                    /usr/share/doc/gpm-1.20.7
cd /sources/blfs/sources/blfs-bootscripts-20180105
make install-gpm
cat > /etc/sysconfig/mouse << "EOF"
# Begin /etc/sysconfig/mouse

MDEVICE="/dev/input/mice"
PROTOCOL="imps2"
GPMOPTS=""

# End /etc/sysconfig/mouse
EOF
cd /sources/blfs/sources
rm -rf gpm-1.20.7

# Git
tar -xf git-2.18.0.tar.xz
cd git-2.18.0
./configure --prefix=/usr --with-gitconfig=/etc/gitconfig &&
make
make install
cd /sources/blfs/sources
rm -rf git-2.18.0

# OpenSSH
tar -xf openssh-7.7p1.tar.gz
cd openssh-7.7p1
install  -v -m700 -d /var/lib/sshd &&
chown    -v root:sys /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd
patch -Np1 -i ../openssh-7.7p1-openssl-1.1.0-1.patch &&

./configure --prefix=/usr                     \
            --sysconfdir=/etc/ssh             \
            --with-md5-passwords              \
            --with-privsep-path=/var/lib/sshd &&
make
make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-7.7p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-7.7p1
cd /sources/blfs/sources/blfs-bootscripts-20180105
make install-sshd
cd /sources/blfs/sources
rm -rf openssh-7.7p1

# Curl
tar -xf curl-7.61.0.tar.xz
cd curl-7.61.0
./configure --prefix=/usr                           \
            --disable-static                        \
            --enable-threaded-resolver              \
            --with-ca-path=/etc/ssl/certs &&
make
make install &&

rm -rf docs/examples/.deps &&

find docs \( -name Makefile\* -o -name \*.1 -o -name \*.3 \) -exec rm {} \; &&

install -v -d -m755 /usr/share/doc/curl-7.61.0 &&
cp -v -R docs/*     /usr/share/doc/curl-7.61.0
cd /sources/blfs/sources
rm -rf curl-7.61.0

# WGET REQUIREMENTS XORG
# Preparation from user
mkdir -vp $LFS/sources/xc
wget --input-file=wget-list-xorg --continue --directory-prefix=$LFS/sources/xc
./wget-dir.sh
chown -R root:root /sources/xc/*
chown -R root:root /sources/xc/lib/*
chown -R root:root /sources/xc/app/*
chown -R root:root /sources/xc/font/*
chown -R root:root /sources/xc/legacy/*

# Install Xorg
cd /sources/xc
export XORG_PREFIX="/usr"
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc \
    --localstatedir=/var --disable-static"
cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="$XORG_PREFIX"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
chmod 644 /etc/profile.d/xorg.sh

# Util macros
tar -xf util-macros-1.19.2.tar.bz2
cd util-macros-1.19.2
./configure $XORG_CONFIG
make install
cd /sources/xc
rm -rf util-macros-1.19.2

# Xorgproto
tar -xf xorgproto-2018.4.tar.bz2
cd xorgproto-2018.4
mkdir build &&
cd    build &&
meson --prefix=$XORG_PREFIX .. &&
ninja
ninja install &&
install -vdm 755 $XORG_PREFIX/share/doc/xorgproto-2018.4 &&
install -vm 644 ../[^m]*.txt ../PM_spec $XORG_PREFIX/share/doc/xorgproto-2018.4

cd /sources/xc
rm -rf xorgproto-2018.4

# libXau
tar -xf  libXau-1.0.8.tar.bz2
cd libXau-1.0.8
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf libXau-1.0.8

# libXdmcp
tar -xf libXdmcp-1.1.2.tar.bz2
cd libXdmcp-1.1.2
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf libXdmcp-1.1.2

# xcb-proto
tar -xf xcb-proto-1.13.tar.bz2
cd xcb-proto-1.13
./configure $XORG_CONFIG
make install
cd /sources/xc
rm -rf xcb-proto-1.13

# libxcb
tar -xf libxcb-1.13.tar.bz2
cd libxcb-1.13
sed -i "s/pthread-stubs//" configure &&
./configure $XORG_CONFIG      \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.13 &&
make && make install
cd /sources/xc
rm -rf libxcb-1.13

# Which
tar -xf which-2.21.tar.gz
cd which-2.21
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf which-2.21

# libpng
tar -xf libpng-1.6.35.tar.xz
cd libpng-1.6.35
LIBS=-lpthread ./configure --prefix=/usr --disable-static &&
make
make install &&
mkdir -v /usr/share/doc/libpng-1.6.35 &&
cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.35
cd /sources/xc
rm -rf libpng-1.6.35

# PCRE
tar -xf pcre-8.42.tar.bz2
cd pcre-8.42
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.42 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                 &&
make
make install                     &&
mv -v /usr/lib/libpcre.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so
cd /sources/xc
rm -rf pcre-8.42

# GLib
tar -xf glib-2.56.1.tar.xz
cd glib-2.56.1
./configure --prefix=/usr      \
            --with-pcre=system \
            --with-python=/usr/bin/python3 &&
make && make install
cd /sources/xc
rm -rf glib-2.56.1

# gobject-introspection
tar -xf gobject-introspection-1.56.1.tar.xz
cd gobject-introspection-1.56.1
./configure --prefix=/usr    \
            --disable-static \
            --with-python=/usr/bin/python3 &&
make && make install
cd /sources/xc
rm -rf gobject-introspection-1.56.1

# ICU
tar -xf icu4c-62_1-src.tgz
cd icu
cd source                                    &&
./configure --prefix=/usr                    &&
make && make install
cd /sources/xc
rm -rf icu

# FreeType
tar -xf freetype-2.9.1.tar.bz2
cd freetype-2.9.1
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&
sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&
./configure --prefix=/usr --enable-freetype-config --disable-static &&
make
make install &&
cp builds/unix/freetype-config /usr/bin
cd /sources/xc
rm -rf freetype-2.9.1

# HarfBuzz
tar -xf harfbuzz-1.8.8.tar.bz2
cd harfbuzz-1.8.8
./configure --prefix=/usr --with-gobject &&
make && make install
cd /sources/xc
rm -rf harfbuzz-1.8.8

# FreeType 2
tar -xf freetype-2.9.1.tar.bz2
cd freetype-2.9.1
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&
sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&
./configure --prefix=/usr --enable-freetype-config --disable-static &&
make
make install &&
cp builds/unix/freetype-config /usr/bin
cd /sources/xc
rm -rf freetype-2.9.1

# Fontconfig
tar -xf fontconfig-2.13.0.tar.bz2
cd fontconfig-2.13.0
rm -f src/fcobjshash.h
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --docdir=/usr/share/doc/fontconfig-2.13.0 &&
make && make install
cd /sources/xc
rm -rf fontconfig-2.13.0

# Xorg Libraries
cd lib
bash -e
for package in $(grep -v '^#' ../lib-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  case $packagedir in
    libICE* )
      ./configure $XORG_CONFIG ICE_LIBS=-lpthread
    ;;

    libXfont2-[0-9]* )
      ./configure $XORG_CONFIG --disable-devel-docs
    ;;

    libXt-[0-9]* )
      ./configure $XORG_CONFIG \
                  --with-appdefaultdir=/etc/X11/app-defaults
    ;;

    * )
      ./configure $XORG_CONFIG
    ;;
  esac
  make
  #make check 2>&1 | tee ../$packagedir-make_check.log
  as_root make install
  popd
  rm -rf $packagedir
  as_root /sbin/ldconfig
done
exit
cd /sources/xc

# xcb-util
tar -xf xcb-util-0.4.0.tar.bz2
cd xcb-util-0.4.0
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcb-util-0.4.0

# xcb-util-image
tar -xf xcb-util-image-0.4.0.tar.bz2
cd xcb-util-image-0.4.0
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcb-util-image-0.4.0

# xcb-util-keysyms
tar -xf xcb-util-keysyms-0.4.0.tar.bz2
cd xcb-util-keysyms-0.4.0
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcb-util-keysyms-0.4.0

# xcb-util-renderutil
tar -xf xcb-util-renderutil-0.3.9.tar.bz2
cd xcb-util-renderutil-0.3.9
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcb-util-renderutil-0.3.9

# xcb-util-wm
tar -xf xcb-util-wm-0.4.1.tar.bz2
cd xcb-util-wm-0.4.1
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcb-util-wm-0.4.1

# xcb-util-cursor
tar -xf xcb-util-cursor-0.1.3.tar.bz2
cd xcb-util-cursor-0.1.3
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcb-util-cursor-0.1.3

# libdrm
tar -xf libdrm-2.4.93.tar.bz2
cd libdrm-2.4.93
mkdir build &&
cd    build &&
meson --prefix=$XORG_PREFIX -Dudev=true &&
ninja && ninja install
cd /sources/xc
rm -rf libdrm-2.4.93

# Python2
tar -xf Python-2.7.15.tar.xz
cd Python-2.7.15
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes \
            --enable-unicode=ucs4 &&
make
make install &&
chmod -v 755 /usr/lib/libpython2.7.so.1.0
cd /sources/xc
rm -rf Python-2.7.15

# MarkupSafe
tar -xf MarkupSafe-1.0.tar.gz
cd MarkupSafe-1.0
python setup.py build
python setup.py install --optimize=1
python3 setup.py build
python3 setup.py install --optimize=1
cd /sources/xc
rm -rf MarkupSafe-1.0

# Beaker
tar -xf Beaker-1.10.0.tar.gz
cd Beaker-1.10.0
python setup.py install --optimize=1
python3 setup.py install --optimize=1
cd /sources/xc
rm -rf Beaker-1.10.0

# Mako
tar -xf Mako-1.0.4.tar.gz
cd Mako-1.0.4
python setup.py install --optimize=1
sed -i "s:mako-render:&3:g" setup.py &&
python3 setup.py install --optimize=1
cd /sources/xc
rm -rf Mako-1.0.4

# libxml2
tar -xf libxml2-2.9.8.tar.gz
cd libxml2-2.9.8
patch -Np1 -i ../libxml2-2.9.8-python3_hack-1.patch
sed -i '/_PyVerify_fd/,+1d' python/types.c
./configure --prefix=/usr    \
            --disable-static \
            --with-history   \
            --with-python=/usr/bin/python3 &&
make && make install
cd /sources/xc
rm -rf libxml2-2.9.8

# Wayland
tar -xf wayland-1.15.0.tar.xz
cd wayland-1.15.0
./configure --prefix=/usr    \
            --disable-static \
            --disable-documentation &&
make && make install
cd /sources/xc
rm -rf wayland-1.15.0

# Wayland-Protocols
tar -xf wayland-protocols-1.15.tar.xz
cd wayland-protocols-1.15
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf wayland-protocols-1.15

# libuv
tar -xf libuv-v1.22.0.tar.gz
cd libuv-v1.22.0
sh autogen.sh                              &&
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libuv-v1.22.0

# libarchive
tar -xf libarchive-3.3.2.tar.gz
cd libarchive-3.3.2
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libarchive-3.3.2

# CMake
tar -xf cmake-3.12.1.tar.gz
cd cmake-3.12.1
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&
./bootstrap --prefix=/usr        \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.12.1 &&
make && make install
cd /sources/xc
rm -rf cmake-3.12.1

# LLVM
tar -xf llvm-6.0.1.src.tar.xz
cd llvm-6.0.1
mkdir -v build &&
cd       build &&
CC=gcc CXX=g++                              \
cmake -DCMAKE_INSTALL_PREFIX=/usr           \
      -DLLVM_ENABLE_FFI=ON                  \
      -DCMAKE_BUILD_TYPE=Release            \
      -DLLVM_BUILD_LLVM_DYLIB=ON            \
      -DLLVM_LINK_LLVM_DYLIB=ON             \
      -DLLVM_TARGETS_TO_BUILD="host;AMDGPU" \
      -DLLVM_BUILD_TESTS=ON                 \
      -Wno-dev -G Ninja ..                           &&
ninja && ninja install
install -v -m644 docs/man/* /usr/share/man/man1             &&
install -v -d -m755 /usr/share/doc/llvm-6.0.1/llvm-html     &&
cp -Rv docs/html/* /usr/share/doc/llvm-6.0.1/llvm-html
cd /sources/xc
rm -rf llvm-6.0.1


# Mesa
tar -xf mesa-18.1.6.tar.xz
cd mesa-18.1.6
GLL_DRV="r300,r600,svga,swrast"
./configure CFLAGS='-O2' CXXFLAGS='-O2' LDFLAGS=-lLLVM \
            --prefix=$XORG_PREFIX              \
            --sysconfdir=/etc                  \
            --enable-texture-float             \
            --enable-osmesa                    \
            --enable-xa                        \
            --enable-glx-tls                   \
            --with-platforms="drm,x11,wayland" \
            --with-gallium-drivers=$GLL_DRV    &&
unset GLL_DRV &&
make && make install
cd /sources/xc
rm -rf mesa-18.1.6

# xbitmaps
tar -xf xbitmaps-1.1.2.tar.bz2
cd xbitmaps-1.1.2
./configure $XORG_CONFIG && make install
cd /sources/xc
rm -rf xbitmaps-1.1.2

# Xorg Applications
cd app
bash -e
for package in $(grep -v '^#' ../app-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
     case $packagedir in
       luit-[0-9]* )
         sed -i -e "/D_XOPEN/s/5/6/" configure
       ;;
     esac

     ./configure $XORG_CONFIG
     make
     as_root make install
  popd
  rm -rf $packagedir
done
exit
rm -f $XORG_PREFIX/bin/xkeystone
cd /sources/xc

# xcursor-themes
tar -xf xcursor-themes-1.0.5.tar.bz2
cd xcursor-themes-1.0.5
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xcursor-themes-1.0.5

# Xorg Fonts
cd font
bash -e
for package in $(grep -v '^#' ../font-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
    ./configure $XORG_CONFIG
    make
    as_root make install
  popd
  as_root rm -rf $packagedir
done
exit
install -v -d -m755 /usr/share/fonts                               &&
ln -svfn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF &&
ln -svfn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF
cd /sources/xc

# XKeyboardConfig
tar -xf xkeyboard-config-2.24.tar.bz2
cd xkeyboard-config-2.24
./configure $XORG_CONFIG --with-xkb-rules-symlink=xorg &&
make && make install
cd /sources/xc
rm -rf xkeyboard-config-2.24

# Pixman
tar -xf pixman-0.34.0.tar.gz
cd pixman-0.34.0
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf pixman-0.34.0

# libepoxy
tar -xf libepoxy-1.5.2.tar.xz
cd libepoxy-1.5.2
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf libepoxy-1.5.2

# Xorg-Server
tar -xf xorg-server-1.20.1.tar.bz2
cd xorg-server-1.20.1
./configure $XORG_CONFIG            \
           --enable-glamor          \
           --enable-install-setuid  \
           --enable-suid-wrapper    \
           --disable-systemd-logind \
           --with-xkb-output=/var/lib/xkb &&
make
make install &&
mkdir -pv /etc/X11/xorg.conf.d &&
cat >> /etc/sysconfig/createfiles << "EOF"
/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root
EOF
cd /sources/xc
rm -rf xorg-server-1.20.1

# mtdev
tar -xf mtdev-1.1.5.tar.bz2
cd mtdev-1.1.5
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf mtdev-1.1.5

# libevdev
# KERNEL CONF
tar -xf libevdev-1.5.9.tar.xz
cd libevdev-1.5.9
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf libevdev-1.5.9

# libinput
tar -xf libinput-1.11.3.tar.xz
cd libinput-1.11.3
mkdir build &&
cd    build &&
meson --prefix=$XORG_PREFIX \
      -Dudev-dir=/lib/udev  \
      -Ddebug-gui=false     \
      -Dtests=false         \
      -Ddocumentation=false \
      -Dlibwacom=false      \
      ..                    &&
ninja && ninja install
cd /sources/xc
rm -rf libinput-1.11.3

# Xorg Libinput Driver
tar -xf xf86-input-libinput-0.28.0.tar.bz2
cd xf86-input-libinput-0.28.0
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xf86-input-libinput-0.28.0

# Xorg VMware Driver
# KERNEL CONF
tar -xf xf86-video-vmware-13.3.0.tar.bz2
cd xf86-video-vmware-13.3.0
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xf86-video-vmware-13.3.0

# twm
tar -xf twm-1.0.10.tar.bz2
cd twm-1.0.10
sed -i -e '/^rcdir =/s,^\(rcdir = \).*,\1/etc/X11/app-defaults,' src/Makefile.in &&
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf twm-1.0.10

# DejaVu fonts
tar -xf dejavu-fonts-2.37.tar.bz2
cd dejavu-fonts-2.37
install -v -d -m755 /usr/share/fonts/dejavu &&
install -v -m644 ttf/*.ttf /usr/share/fonts/dejavu &&
fc-cache -v /usr/share/fonts/dejavu
cd /sources/xc
rm -rf dejavu-fonts-2.37

# xterm
tar -xf xterm-335.tgz
cd xterm-335
sed -i '/v0/{n;s/new:/new:kb=^?:/}' termcap &&
printf '\tkbs=\\177,\n' >> terminfo &&
TERMINFO=/usr/share/terminfo \
./configure $XORG_CONFIG     \
    --with-app-defaults=/etc/X11/app-defaults &&
make
make install    &&
make install-ti &&

mkdir -pv /usr/share/applications &&
cp -v *.desktop /usr/share/applications/
cat >> /etc/X11/app-defaults/XTerm << "EOF"
*VT100*locale: true
*VT100*faceName: Monospace
*VT100*faceSize: 10
*backarrowKeyIsErase: true
*ptyInitialErase: true
EOF
cd /sources/xc
rm -rf xterm-335

# xclock
tar -xf xclock-1.0.7.tar.bz2
cd xclock-1.0.7
./configure $XORG_CONFIG &&
make && make install
cd /sources/xc
rm -rf xclock-1.0.7

# xinit
tar -xf xinit-1.4.0.tar.bz2
cd xinit-1.4.0
sed -e '/$serverargs $vtarg/ s/serverargs/: #&/' \
    -i startx.cpp
./configure $XORG_CONFIG --with-xinitdir=/etc/X11/app-defaults &&
make
make install &&
ldconfig
cd /sources/xc
rm -rf xinit-1.4.0

# Test Xorg
startx
cat /var/log/Xorg.0.log
usermod -a -G video root
glxinfo
glxinfo | egrep "(OpenGL vendor|OpenGL renderer|OpenGL version)"
xrandr --listproviders

# Xorg Legacy
cd legacy
bash -e
for package in $(grep -v '^#' ../legacy.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  ./configure $XORG_CONFIG
  make
  as_root make install
  popd
  rm -rf $packagedir
  as_root /sbin/ldconfig
done
exit
cd /sources/xc

# Rsync
tar -xf rsync-3.1.3.tar.gz
cd rsync-3.1.3
./configure --prefix=/usr --without-included-zlib &&
make && make install
cd /sources/xc
rm -rf rsync-3.1.3

# Vim
tar -xf ../vim-8.1.tar.bz2
cd vim-8.1
echo '#define SYS_VIMRC_FILE  "/etc/vimrc"' >>  src/feature.h &&
echo '#define SYS_GVIMRC_FILE "/etc/gvimrc"' >> src/feature.h &&
./configure --prefix=/usr \
            --with-features=huge \
            --with-tlib=ncursesw &&
make && make install
ln -snfv ../vim/vim80/doc /usr/share/doc/vim-8.1
rsync -avzcP --exclude="/dos/" --exclude="/spell/" \
    ftp.nluug.nl::Vim/runtime/ ./runtime/
make -C src installruntime &&
vim -c ":helptags /usr/share/doc/vim-8.1" -c ":q"
cd /sources/xc
rm -rf vim-8.1

# Extra lib
# Cairo
tar -xf cairo-1.14.12.tar.xz
cd cairo-1.14.12
./configure --prefix=/usr    \
            --disable-static \
            --enable-tee &&
make && make install
cd /sources/xc
rm -rf cairo-1.14.12

# NASM
tar -xf nasm-2.13.03.tar.xz
cd nasm-2.13.03
sed -e '/seg_init/d'                      \
    -e 's/pure_func seg_alloc/seg_alloc/' \
    -i include/nasmlib.h
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf nasm-2.13.03

# libjpeg-turbo
tar -xf libjpeg-turbo-2.0.0.tar.gz
cd libjpeg-turbo-2.0.0
mkdir build &&
cd    build &&
cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=RELEASE  \
      -DENABLE_STATIC=FALSE       \
      -DCMAKE_INSTALL_DOCDIR=/usr/share/doc/libjpeg-turbo-2.0.0 \
      -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib  \
      .. &&
make && make install
cd /sources/xc
rm -rf libjpeg-turbo-2.0.0

# shared-mime-info
tar -xf shared-mime-info-1.10.tar.xz
cd shared-mime-info-1.10
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf shared-mime-info-1.10

# libcroco
tar -xf libcroco-0.6.12.tar.xz
cd libcroco-0.6.12
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libcroco-0.6.12

# FriBidi
tar -xf fribidi-1.0.5.tar.bz2
cd fribidi-1.0.5
mkdir build &&
cd build    &&
meson --prefix=/usr .. &&
ninja && ninja install
cd /sources/xc
rm -rf fribidi-1.0.5

# Pango
tar -xf pango-1.42.3.tar.xz
cd pango-1.42.3
mkdir build &&
cd    build &&
meson --prefix=/usr --sysconfdir=/etc .. &&
ninja && ninja install
cd /sources/xc
rm -rf pango-1.42.3

# libssh2
tar -xf libssh2-1.8.0.tar.gz
cd libssh2-1.8.0
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libssh2-1.8.0

# Rustc
tar -xf rustc-1.25.0-src.tar.gz
cd rustc-1.25.0
cat << EOF > config.toml
# see config.toml.example for more possible options
[llvm]
targets = "X86"

# When using system llvm prefer shared libraries
link-shared = true

[build]
# install cargo as well as rust
extended = true

[install]
prefix = "/usr"
docdir = "share/doc/rustc-1.25.0"

[rust]
channel = "stable"
rpath = false

# get reasonably clean output from the test harness
quiet-tests = true

# BLFS does not install the FileCheck executable from llvm,
# so disable codegen tests
codegen-tests = false

[target.x86_64-unknown-linux-gnu]
# delete this *section* if you are not using system llvm.
# NB the output of llvm-config (i.e. help options) may be
# dumped to the screen when config.toml is parsed.
llvm-config = "/usr/bin/llvm-config"

EOF
export RUSTFLAGS="$RUSTFLAGS -C link-args=-lffi" &&
./x.py build
DESTDIR=${PWD}/install ./x.py install
chown -R root:root install &&
cp -a install/* /
unset DESTDIR
cd /sources/xc
rm -rf rustc-1.25.0

# Vala
tar -xf vala-0.40.8.tar.xz
cd vala-0.40.8
sed -i '115d; 121,137d; 139,140d'  configure.ac &&
sed -i '/valadoc/d' Makefile.am                 &&
ACLOCAL= autoreconf -fiv
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf vala-0.40.8

# LibTIFF
tar -xf tiff-4.0.9.tar.gz
cd tiff-4.0.9
mkdir -p libtiff-build &&
cd       libtiff-build &&
cmake -DCMAKE_INSTALL_DOCDIR=/usr/share/doc/libtiff-4.0.9 \
      -DCMAKE_INSTALL_PREFIX=/usr -G Ninja .. &&
ninja && ninja install
cd /sources/xc
rm -rf tiff-4.0.9

# gdk-pixbuf
tar -xf gdk-pixbuf-2.36.12.tar.xz
cd gdk-pixbuf-2.36.12
./configure --prefix=/usr --with-x11 &&
make && make install
cd /sources/xc
rm -rf gdk-pixbuf-2.36.12

# librsvg
tar -xf librsvg-2.42.2.tar.xz
cd librsvg-2.42.2
./configure --prefix=/usr    \
            --enable-vala    \
            --disable-static &&
make && make install
cd /sources/xc
rm -rf librsvg-2.42.2

# ATK
tar -xf atk-2.29.2.tar.xz
cd atk-2.29.2
mkdir build &&
cd    build &&
meson --prefix=/usr &&
ninja && ninja install
cd /sources/xc
rm -rf atk-2.29.2

# hicolor-icon-theme
tar -xf hicolor-icon-theme-0.17.tar.xz
cd hicolor-icon-theme-0.17
./configure --prefix=/usr && make install
cd /sources/xc
rm -rf hicolor-icon-theme-0.17

# GTK+2
tar -xf gtk+-2.24.32.tar.xz
cd gtk+-2.24.32
sed -e 's#l \(gtk-.*\).sgml#& -o \1#' \
    -i docs/{faq,tutorial}/Makefile.in      &&
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf gtk+-2.24.32

# dbus
tar -xf dbus-1.12.10.tar.gz
cd dbus-1.12.10
groupadd -g 18 messagebus &&
useradd -c "D-Bus Message Daemon User" -d /var/run/dbus \
        -u 18 -g messagebus -s /bin/false messagebus
./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --disable-static                     \
            --docdir=/usr/share/doc/dbus-1.12.10 \
            --with-console-auth-dir=/run/console \
            --with-system-pid-file=/run/dbus/pid \
            --with-system-socket=/run/dbus/system_bus_socket &&
make && make install
dbus-uuidgen --ensure
cd /sources/xc
rm -rf dbus-1.12.10

# at-spi2-core
tar -xf at-spi2-core-2.28.0.tar.xz
cd at-spi2-core-2.28.0
mkdir build &&
cd    build &&
meson --prefix=/usr --sysconfdir=/etc  .. &&
ninja && ninja install
cd /sources/xc
rm -rf at-spi2-core-2.28.0

# at-spi2-atk
tar -xf at-spi2-atk-2.26.2.tar.xz
cd at-spi2-atk-2.26.2
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf at-spi2-atk-2.26.2

# six
tar -xf six-1.11.0.tar.gz
cd six-1.11.0
python2 setup.py build
python2 setup.py install --optimize=1
python3 setup.py build
python3 setup.py install --optimize=1
cd /sources/xc
rm -rf six-1.11.0

# adwaita-icon-theme
tar -xf adwaita-icon-theme-3.26.1.tar.xz
cd adwaita-icon-theme-3.26.1
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf adwaita-icon-theme-3.26.1

# libxkbcommon
tar -xf libxkbcommon-0.8.2.tar.xz
cd libxkbcommon-0.8.2
./configure $XORG_CONFIG     \
            --docdir=/usr/share/doc/libxkbcommon-0.8.2 &&
make && make install
cd /sources/xc
rm -rf libxkbcommon-0.8.2

# GTK+3
tar -xf gtk+-3.22.30.tar.xz
cd gtk+-3.22.30
./configure --prefix=/usr             \
            --sysconfdir=/etc         \
            --enable-broadway-backend \
            --enable-x11-backend      \
            --enable-wayland-backend &&
make && make install
cd /sources/xc
rm -rf gtk+-3.22.30

# imlib2
tar -xf imlib2-1.5.1.tar.bz2
cd imlib2-1.5.1
./configure --prefix=/usr --disable-static &&
make
make install &&
install -v -m755 -d /usr/share/doc/imlib2-1.5.1 &&
install -v -m644    doc/{*.gif,index.html} \
                    /usr/share/doc/imlib2-1.5.1
cd /sources/xc
rm -rf imlib2-1.5.1

#Xfce
# libxfce4util
tar -xf libxfce4util-4.12.1.tar.bz2
cd libxfce4util-4.12.1
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf libxfce4util-4.12.1

# dbus-glib
tar -xf dbus-glib-0.110.tar.gz
cd dbus-glib-0.110
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static &&
make && make install
cd /sources/xc
rm -rf dbus-glib-0.110

# Xfconf
tar -xf xfconf-4.12.1.tar.bz2
cd xfconf-4.12.1
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xfconf-4.12.1

# startup-notification
tar -xf startup-notification-0.12.tar.gz
cd startup-notification-0.12
./configure --prefix=/usr --disable-static &&
make
make install &&
install -v -m644 -D doc/startup-notification.txt \
    /usr/share/doc/startup-notification-0.12/startup-notification.txt
cd /sources/xc
rm -rf startup-notification-0.12

# libxfce4ui
tar -xf libxfce4ui-4.12.1.tar.bz2
cd libxfce4ui-4.12.1
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf libxfce4ui-4.12.1

# URI
tar -xf URI-1.74.tar.gz
cd URI-1.74
perl Makefile.PL &&
make && make install
cd /sources/xc
rm -rf URI-1.74

# Exo
tar -xf exo-0.12.2.tar.bz2
cd exo-0.12.2
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf exo-0.12.2

# Garcon
tar -xf garcon-0.6.1.tar.bz2
cd garcon-0.6.1
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf garcon-0.6.1

# gtk-xfce-engine
tar -xf gtk-xfce-engine-3.2.0.tar.bz2
cd gtk-xfce-engine-3.2.0
sed -i 's/\xd6/\xc3\x96/' gtk-3.0/xfce_style_types.h &&
./configure --prefix=/usr --enable-gtk3              &&
make && make install
cd /sources/xc
rm -rf gtk-xfce-engine-3.2.0

# libwnck
tar -xf libwnck-2.30.7.tar.xz
cd libwnck-2.30.7
./configure --prefix=/usr \
            --disable-static \
            --program-suffix=-1 &&
make GETTEXT_PACKAGE=libwnck-1
make GETTEXT_PACKAGE=libwnck-1 install
cd /sources/xc
rm -rf libwnck-2.30.7

# xfce4-panel
tar -xf xfce4-panel-4.12.2.tar.bz2
cd xfce4-panel-4.12.2
./configure --prefix=/usr --sysconfdir=/etc --enable-gtk3 &&
make && make install
cd /sources/xc
rm -rf xfce4-panel-4.12.2

# ISO Codes
tar -xf iso-codes-3.79.tar.xz
cd iso-codes-3.79
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf iso-codes-3.79

# libxklavier
tar -xf libxklavier-5.4.tar.bz2
cd libxklavier-5.4
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libxklavier-5.4

# xfce4-xkb-plugin
tar -xf xfce4-xkb-plugin-0.7.1.tar.bz2
cd xfce4-xkb-plugin-0.7.1
sed -e 's|xfce4/panel-plugins|xfce4/panel/plugins|' \
    -i panel-plugin/{Makefile.in,xkb-plugin.desktop.in.in} &&
./configure --prefix=/usr         \
            --libexecdir=/usr/lib \
            --disable-debug       &&
make && make install
cd /sources/xc
rm -rf xfce4-xkb-plugin-0.7.1

# XML::Simple
tar -xf XML-Simple-2.25.tar.gz
cd XML-Simple-2.25
perl Makefile.PL &&
make && make install
cd /sources/xc
rm -rf XML-Simple-2.25

# icon-naming-utils
tar -xf icon-naming-utils-0.8.90.tar.bz2
cd icon-naming-utils-0.8.90
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf icon-naming-utils-0.8.90

# gnome-icon-theme
tar -xf gnome-icon-theme-3.12.0.tar.xz
cd gnome-icon-theme-3.12.0
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf gnome-icon-theme-3.12.0

# libgudev
tar -xf libgudev-232.tar.xz
cd libgudev-232
./configure --prefix=/usr --disable-umockdev &&
make && make install
cd /sources/xc
rm -rf libgudev-232

# gstreamer
tar -xf gstreamer-1.14.2.tar.xz
cd gstreamer-1.14.2
./configure --prefix=/usr \
            --with-package-name="GStreamer 1.14.2 BLFS" \
            --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" &&
make && make install
cd /sources/xc
rm -rf gstreamer-1.14.2

### KERNEL CONF !!!
# alsa-lib
tar -xf alsa-lib-1.1.6.tar.bz2
cd alsa-lib-1.1.6
./configure &&
make && make install
cd /sources/xc
rm -rf alsa-lib-1.1.6

# libogg
tar -xf libogg-1.3.3.tar.xz
cd libogg-1.3.3
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libogg-1.3.3 &&
make && make install
cd /sources/xc
rm -rf libogg-1.3.3

# libvorbis
tar -xf libvorbis-1.3.6.tar.xz
cd libvorbis-1.3.6
./configure --prefix=/usr --disable-static &&
make
make install &&
install -v -m644 doc/Vorbis* /usr/share/doc/libvorbis-1.3.6
cd /sources/xc
rm -rf libvorbis-1.3.6

# libcanberra
tar -xf libcanberra-0.30.tar.xz
cd libcanberra-0.30
./configure --prefix=/usr --disable-oss &&
make
make docdir=/usr/share/doc/libcanberra-0.30 install
cd /sources/xc
rm -rf libcanberra-0.30

# notification-daemon
tar -xf notification-daemon-3.20.0.tar.xz
cd notification-daemon-3.20.0
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  &&
make && make install
cd /sources/xc
rm -rf notification-daemon-3.20.0

# libnotify
tar -xf libnotify-0.7.7.tar.xz
cd libnotify-0.7.7
./configure --prefix=/usr --disable-static &&
make
make install
cd /sources/xc
rm -rf libnotify-0.7.7

# Thunar
tar -xf Thunar-1.7.0.tar.bz2
cd Thunar-1.7.0
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/Thunar-1.7.0 &&
make && make install
cd /sources/xc
rm -rf Thunar-1.7.0

# libgpg-error
tar -xf libgpg-error-1.32.tar.bz2
cd libgpg-error-1.32
./configure --prefix=/usr &&
make
make install &&
install -v -m644 -D README /usr/share/doc/libgpg-error-1.32/README
cd /sources/xc
rm -rf libgpg-error-1.32

# libgcrypt
tar -xf libgcrypt-1.8.3.tar.bz2
cd libgcrypt-1.8.3
./configure --prefix=/usr &&
make
make install &&
install -v -dm755   /usr/share/doc/libgcrypt-1.8.3 &&
install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
                    /usr/share/doc/libgcrypt-1.8.3
cd /sources/xc
rm -rf libgcrypt-1.8.3

# libtasn1
tar -xf libtasn1-4.13.tar.gz
cd libtasn1-4.13
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libtasn1-4.13

# make-ca
tar -xf make-ca-0.8.tar.gz
cd make-ca-0.8
install -vdm755 /etc/ssl/local &&
wget http://www.cacert.org/certs/root.crt &&
wget http://www.cacert.org/certs/class3.crt &&
openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
        > /etc/ssl/local/CAcert_Class_1_root.pem &&
openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
        > /etc/ssl/local/CAcert_Class_3_root.pem
make install
/usr/sbin/make-ca -g
cd /sources/xc
rm -rf make-ca-0.8

# p11-kit
tar -xf p11-kit-0.23.13.tar.gz
cd p11-kit-0.23.13
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --with-trust-paths=/etc/pki/anchors &&
make && make install
cd /sources/xc
rm -rf p11-kit-0.23.13

# libassuan
tar -xf libassuan-2.5.1.tar.bz2
cd libassuan-2.5.1
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf libassuan-2.5.1

# libksba
tar -xf libksba-1.3.5.tar.bz2
cd libksba-1.3.5
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf libksba-1.3.5

# npth
tar -xf npth-1.6.tar.bz2
cd npth-1.6
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf npth-1.6

# pinentry
tar -xf pinentry-1.1.0.tar.bz2
cd pinentry-1.1.0
./configure --prefix=/usr --enable-pinentry-tty &&
make && make install
cd /sources/xc
rm -rf pinentry-1.1.0

# gnupg
tar -xf gnupg-2.2.9.tar.bz2
cd gnupg-2.2.9
./configure --prefix=/usr            \
            --enable-symcryptrun     \
            --docdir=/usr/share/doc/gnupg-2.2.9 &&
make &&
makeinfo --html --no-split -o doc/gnupg_nochunks.html doc/gnupg.texi &&
makeinfo --plaintext       -o doc/gnupg.txt           doc/gnupg.texi
make install &&
install -v -m755 -d /usr/share/doc/gnupg-2.2.9/html            &&
install -v -m644    doc/gnupg_nochunks.html \
                    /usr/share/doc/gnupg-2.2.9/html/gnupg.html &&
install -v -m644    doc/*.texi doc/gnupg.txt \
                    /usr/share/doc/gnupg-2.2.9
cd /sources/xc
rm -rf gnupg-2.2.9

# sgml-common
tar -xf sgml-common-0.6.3.tgz
cd sgml-common-0.6.3
patch -Np1 -i ../sgml-common-0.6.3-manpage-1.patch &&
autoreconf -f -i
./configure --prefix=/usr --sysconfdir=/etc &&
make
make docdir=/usr/share/doc install &&
install-catalog --add /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&
install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat
cd /sources/xc
rm -rf sgml-common-0.6.3

# unzip
tar -xf unzip60.tar.gz
cd unzip60
make -f unix/Makefile generic
make prefix=/usr MANDIR=/usr/share/man/man1 \
 -f unix/Makefile install
cd /sources/xc
rm -rf unzip60

# docbook-xml
tar -xf docbook-xml-4.5.zip
cd docbook-xml-4.5
install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5 &&
install -v -d -m755 /etc/xml &&
chown -R root:root . &&
cp -v -af docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-4.5
if [ ! -e /etc/xml/docbook ]; then
    xmlcatalog --noout --create /etc/xml/docbook
fi &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
cd /sources/xc
rm -rf docbook-xml-4.5

# docbook-xsl
tar -xf docbook-xsl-1.79.2.tar.bz2
cd docbook-xsl-1.79.2
patch -Np1 -i ../docbook-xsl-1.79.2-stack_fix-1.patch
install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-1.79.2 &&
cp -v -R VERSION assembly common eclipse epub epub3 extensions fo        \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
    /usr/share/xml/docbook/xsl-stylesheets-1.79.2 &&
ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-1.79.2/VERSION.xsl &&
install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-1.79.2/README.txt &&
install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-1.79.2
if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi &&
if [ ! -f /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-1.79.2" \
    /etc/xml/catalog
cd /sources/xc
rm -rf docbook-xsl-1.79.2

# libxslt
tar -xf libxslt-1.1.32.tar.gz
cd libxslt-1.1.32
sed -i s/3000/5000/ libxslt/transform.c doc/xsltproc.{1,xml} &&
./configure --prefix=/usr --disable-static                   &&
make && make install
cd /sources/xc
rm -rf libxslt-1.1.32

# gcr
tar -xf gcr-3.28.0.tar.xz
cd gcr-3.28.0
sed -i -r 's:"(/desktop):"/org/gnome\1:' schema/*.xml &&
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --without-gtk-doc &&
make && make install
cd /sources/xc
rm -rf gcr-3.28.0

# Linux-PAM-1.3.0.tar.bz2
tar -xf Linux-PAM-1.3.0.tar.bz2
cd Linux-PAM-1.3.0
./configure --prefix=/usr                    \
            --sysconfdir=/etc                \
            --libdir=/usr/lib                \
            --disable-regenerate-docu        \
            --enable-securedir=/lib/security \
            --docdir=/usr/share/doc/Linux-PAM-1.3.0 &&
make
install -v -m755 -d /etc/pam.d &&
cat > /etc/pam.d/other << "EOF"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
EOF
rm -fv /etc/pam.d/*
make install &&
chmod -v 4755 /sbin/unix_chkpwd &&
for file in pam pam_misc pamc
do
  mv -v /usr/lib/lib${file}.so.* /lib &&
  ln -sfv ../../lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
done

cat > /etc/pam.d/other << "EOF" &&
# Begin /etc/pam.d/other

auth            required        pam_unix.so     nullok
account         required        pam_unix.so
session         required        pam_unix.so
password        required        pam_unix.so     nullok

# End /etc/pam.d/other
EOF

install -vdm755 /etc/pam.d &&
cat > /etc/pam.d/system-account << "EOF" &&
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
EOF

cat > /etc/pam.d/system-auth << "EOF" &&
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

cat > /etc/pam.d/system-session << "EOF"
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
EOF

cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# use sha512 hash for encryption, use shadow, and try to use any previously
# defined authentication token (chosen password) set by any prior module
password  required    pam_unix.so       sha512 shadow try_first_pass

# End /etc/pam.d/system-password
EOF

cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
EOF

sed -i 's/groups$(EXEEXT) //' src/Makefile.in &&
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; &&
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; &&
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; &&
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs &&
sed -i 's/1000/999/' etc/useradd                           &&
./configure --sysconfdir=/etc --with-group-name-max-length=32 &&
make
make install &&
mv -v /usr/bin/passwd /bin
sed -i 's/yes/no/' /etc/default/useradd
install -v -m644 /etc/login.defs /etc/login.defs.orig &&
for FUNCTION in FAIL_DELAY               \
                FAILLOG_ENAB             \
                LASTLOG_ENAB             \
                MAIL_CHECK_ENAB          \
                OBSCURE_CHECKS_ENAB      \
                PORTTIME_CHECKS_ENAB     \
                QUOTAS_ENAB              \
                CONSOLE MOTD_FILE        \
                FTMP_FILE NOLOGINS_FILE  \
                ENV_HZ PASS_MIN_LEN      \
                SU_WHEEL_ONLY            \
                CRACKLIB_DICTPATH        \
                PASS_CHANGE_TRIES        \
                PASS_ALWAYS_WARN         \
                CHFN_AUTH ENCRYPT_METHOD \
                ENVIRON_FILE
do
    sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
done

cat > /etc/pam.d/login << "EOF"
# Begin /etc/pam.d/login

# Set failure delay before next prompt to 3 seconds
auth      optional    pam_faildelay.so  delay=3000000

# Check to make sure that the user is allowed to login
auth      requisite   pam_nologin.so

# Check to make sure that root is allowed to login
# Disabled by default. You will need to create /etc/securetty
# file for this module to function. See man 5 securetty.
#auth      required    pam_securetty.so

# Additional group memberships - disabled by default
#auth      optional    pam_group.so

# include the default auth settings
auth      include     system-auth

# check access for the user
account   required    pam_access.so

# include the default account settings
account   include     system-account

# Set default environment variables for the user
session   required    pam_env.so

# Set resource limits for the user
session   required    pam_limits.so

# Display date of last login - Disabled by default
#session   optional    pam_lastlog.so

# Display the message of the day - Disabled by default
#session   optional    pam_motd.so

# Check user's mail - Disabled by default
#session   optional    pam_mail.so      standard quiet

# include the default session and password settings
session   include     system-session
password  include     system-password

# End /etc/pam.d/login
EOF

cat > /etc/pam.d/passwd << "EOF"
# Begin /etc/pam.d/passwd

password  include     system-password

# End /etc/pam.d/passwd
EOF

cat > /etc/pam.d/su << "EOF"
# Begin /etc/pam.d/su

# always allow root
auth      sufficient  pam_rootok.so
auth      include     system-auth

# include the default account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session defaults
session   include     system-session

# End /etc/pam.d/su
EOF

cat > /etc/pam.d/chage << "EOF"
# Begin /etc/pam.d/chage

# always allow root
auth      sufficient  pam_rootok.so

# include system defaults for auth account and session
auth      include     system-auth
account   include     system-account
session   include     system-session

# Always permit for authentication updates
password  required    pam_permit.so

# End /etc/pam.d/chage
EOF

for PROGRAM in chfn chgpasswd chpasswd chsh groupadd groupdel \
               groupmems groupmod newusers useradd userdel usermod
do
    install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
    sed -i "s/chage/$PROGRAM/" /etc/pam.d/${PROGRAM}
done
[ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}
[ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}
cd /sources/xc
rm -rf Linux-PAM-1.3.0

# gnome-keyring
tar -xf gnome-keyring-3.28.2.tar.xz
cd gnome-keyring-3.28.2
sed -i -r 's:"(/desktop):"/org/gnome\1:' schema/*.xml &&
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --with-pam-dir=/lib/security &&
make && make install
cd /sources/xc
rm -rf gnome-keyring-3.28.2

# libsecret
tar -xf libsecret-0.18.6.tar.xz
cd libsecret-0.18.6
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libsecret-0.18.6

# nettle
tar -xf nettle-3.4.tar.gz
cd nettle-3.4
./configure --prefix=/usr --disable-static &&
make
make install &&
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
install -v -m755 -d /usr/share/doc/nettle-3.4 &&
install -v -m644 nettle.html /usr/share/doc/nettle-3.4
cd /sources/xc
rm -rf nettle-3.4

# libunistring
tar -xf libunistring-0.9.10.tar.xz
cd libunistring-0.9.10
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-0.9.10 &&
make && make install
cd /sources/xc
rm -rf libunistring-0.9.10

# GnuTLS
tar -xf gnutls-3.5.19.tar.xz
cd gnutls-3.5.19
./configure --prefix=/usr \
            --with-default-trust-store-pkcs11="pkcs11:" &&
make && make install
cd /sources/xc
rm -rf gnutls-3.5.19

# gsettings-desktop-schemas
tar -xf gsettings-desktop-schemas-3.28.0.tar.xz
cd gsettings-desktop-schemas-3.28.0
sed -i -r 's:"(/system):"/org/gnome\1:g' schemas/*.in &&
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf gsettings-desktop-schemas-3.28.0

# glib-networking
tar -xf glib-networking-2.56.1.tar.xz
cd glib-networking-2.56.1
mkdir build &&
cd    build &&
meson --prefix=/usr            \
      -Dlibproxy_support=false \
      -Dca_certificates_path=/etc/ssl/ca-bundle.crt .. &&
ninja && ninja install
cd /sources/xc
rm -rf glib-networking-2.56.1

# SQLite
tar -xf sqlite-autoconf-3240000.tar.gz
cd sqlite-autoconf-3240000
./configure --prefix=/usr     \
            --disable-static  \
            --enable-fts5     \
            CFLAGS="-g -O2                    \
            -DSQLITE_ENABLE_FTS4=1            \
            -DSQLITE_ENABLE_COLUMN_METADATA=1 \
            -DSQLITE_ENABLE_UNLOCK_NOTIFY=1   \
            -DSQLITE_ENABLE_DBSTAT_VTAB=1     \
            -DSQLITE_SECURE_DELETE=1          \
            -DSQLITE_ENABLE_FTS3_TOKENIZER=1" &&
make && make install
cd /sources/xc
rm -rf sqlite-autoconf-3240000

# libsoup
tar -xf libsoup-2.62.3.tar.xz
cd libsoup-2.62.3
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libsoup-2.62.3

# libcdio
tar -xf libcdio-2.0.0.tar.gz
cd libcdio-2.0.0
./configure --prefix=/usr --disable-static &&
make && make install
tar -xf ../libcdio-paranoia-10.2+0.94+2.tar.gz &&
cd libcdio-paranoia-10.2+0.94+2 &&
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf libcdio-2.0.0

# libatasmart
tar -xf libatasmart-0.19.tar.xz
cd libatasmart-0.19
./configure --prefix=/usr --disable-static &&
make
make docdir=/usr/share/doc/libatasmart-0.19 install
cd /sources/xc
rm -rf libatasmart-0.19

# libbytesize
tar -xf libbytesize-1.4.tar.gz
cd libbytesize-1.4
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf libbytesize-1.4

# KERNEL CONFIG !!!
# LVM2
tar -xf LVM2.2.02.177.tgz
cd LVM2.2.02.177
SAVEPATH=$PATH                  &&
PATH=$PATH:/sbin:/usr/sbin      &&
./configure --prefix=/usr       \
            --exec-prefix=      \
            --enable-applib     \
            --enable-cmdlib     \
            --enable-pkgconfig  \
            --enable-udev_sync  &&
make                            &&
PATH=$SAVEPATH                  &&
unset SAVEPATH
make -C tools install_dmsetup_dynamic &&
make -C udev  install                 &&
make -C libdm install
make install
cd /sources/xc
rm -rf LVM2.2.02.177

# parted
tar -xf parted-3.2.tar.xz
cd parted-3.2
sed -i '/utsname.h/a#include <sys/sysmacros.h>' libparted/arch/linux.c &&
./configure --prefix=/usr --disable-static &&
make &&
make -C doc html                                       &&
makeinfo --html      -o doc/html       doc/parted.texi &&
makeinfo --plaintext -o doc/parted.txt doc/parted.texi
make install &&
install -v -m755 -d /usr/share/doc/parted-3.2/html &&
install -v -m644    doc/html/* \
                    /usr/share/doc/parted-3.2/html &&
install -v -m644    doc/{FAT,API,parted.{txt,html}} \
                    /usr/share/doc/parted-3.2
cd /sources/xc
rm -rf parted-3.2

# json-c
tar -xf json-c-0.13.1.tar.gz
cd json-c-0.13.1
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf json-c-0.13.1

# popt
tar -xf popt-1.16.tar.gz
cd popt-1.16
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf popt-1.16

# CONFIG KERNEL !!!
# cryptsetup
tar -xf cryptsetup-2.0.4.tar.xz
cd cryptsetup-2.0.4
./configure --prefix=/usr \
            --with-crypto_backend=openssl &&
make && make install
cd /sources/xc
rm -rf cryptsetup-2.0.4

# gpgme
tar -xf gpgme-1.11.1.tar.bz2
cd gpgme-1.11.1
./configure --prefix=/usr --disable-gpg-test &&
make && make install
cd /sources/xc
rm -rf gpgme-1.11.1

# volume_key
tar -xf volume_key-0.3.11.tar.xz
cd volume_key-0.3.11
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf volume_key-0.3.11

# yaml
tar -xf yaml-0.2.1.tar.gz
cd yaml-0.2.1
./configure --prefix=/usr --disable-static &&
make && make install
cd /sources/xc
rm -rf yaml-0.2.1

# libblockdev
tar -xf libblockdev-2.19.tar.gz
cd libblockdev-2.19
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --with-python3    \
            --without-gtk-doc \
            --without-nvdimm  \
            --without-dm      &&
make && make install
cd /sources/xc
rm -rf libblockdev-2.19

# nspr
tar -xf nspr-4.19.tar.gz
cd nspr-4.19
cd nspr                                                     &&
sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
sed -i 's#$(LIBRARY) ##'            config/rules.mk         &&
./configure --prefix=/usr \
            --with-mozilla \
            --with-pthreads \
            $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
make && make install
cd /sources/xc
rm -rf nspr-4.19

# yasm
tar -xf yasm-1.3.0.tar.gz
cd yasm-1.3.0
sed -i 's#) ytasm.*#)#' Makefile.in &&
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf yasm-1.3.0

# Zip
tar -xf zip30.tar.gz
cd zip30
make -f unix/Makefile generic_gcc
make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install
cd /sources/xc
rm -rf zip30

# JS-52.2.1gnome1
tar -xf mozjs-52.2.1gnome1.tar.gz
cd mozjs-52.2.1gnome1
cd js/src &&
./configure --prefix=/usr       \
            --with-intl-api     \
            --with-system-zlib  \
            --with-system-nspr  \
            --with-system-icu   \
            --enable-threadsafe \
            --enable-readline   &&
make && make install
cd /sources/xc
rm -rf mozjs-52.2.1gnome1

# Polkit
tar -xf polkit-0.114.tar.gz
cd polkit-0.114
groupadd -fg 27 polkitd &&
useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd
sed -e '/JS_ReportWarningUTF8/s/,/, "%s",/'  \
        -i  src/polkitbackend/polkitbackendjsauthority.cpp
./configure --prefix=/usr                    \
            --sysconfdir=/etc                \
            --localstatedir=/var             \
            --disable-static                 \
            --enable-libsystemd-login=no     \
            --enable-libelogind=no           \
            --with-authfw=shadow             &&
make && make install
### WARNING
# SI LA SORTIE CONTIENT libpam.so ne PAS executer  le cat pour la conf:
ldd /usr/libexec/polkit-agent-helper-1 | grep pam
# OUI NON ?
cat > /etc/pam.d/polkit-1 << "EOF"
# Begin /etc/pam.d/polkit-1

auth     include        system-auth
account  include        system-account
password include        system-password
session  include        system-session

# End /etc/pam.d/polkit-1
EOF
##############
cd /sources/xc
rm -rf polkit-0.114

# lzo
tar -xf lzo-2.10.tar.gz
cd lzo-2.10
./configure --prefix=/usr                    \
            --enable-shared                  \
            --disable-static                 \
            --docdir=/usr/share/doc/lzo-2.10 &&
make && make install
cd /sources/xc
rm -rf lzo-2.10

# asciidoc
tar -xf asciidoc-8.6.9.tar.gz
cd asciidoc-8.6.9
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/asciidoc-8.6.9 &&
make
make install &&
make docs
cd /sources/xc
rm -rf asciidoc-8.6.9

# xmlto
tar -xf xmlto-0.0.28.tar.bz2
cd xmlto-0.0.28
LINKS="/usr/bin/links" \
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xmlto-0.0.28

# KERNEL CONFIG
# btrfs-progs
tar -xf btrfs-progs-v4.17.1.tar.xz
cd btrfs-progs-v4.17.1
sed -i '40,107 s/\.gz//g' Documentation/Makefile.in &&
./configure --prefix=/usr  \
            --bindir=/bin  \
            --libdir=/lib  \
            --disable-zstd &&
make
make install &&
ln -sfv ../../lib/$(readlink /lib/libbtrfs.so) /usr/lib/libbtrfs.so &&
ln -sfv ../../lib/$(readlink /lib/libbtrfsutil.so) /usr/lib/libbtrfsutil.so &&
rm -fv /lib/libbtrfs.{a,so} /lib/libbtrfsutil.{a,so} &&
mv -v /bin/{mkfs,fsck}.btrfs /sbin
cd /sources/xc
rm -rf btrfs-progs-v4.17.1

# dosfstools
tar -xf dosfstools-4.1.tar.xz
cd dosfstools-4.1
./configure --prefix=/               \
            --enable-compat-symlinks \
            --mandir=/usr/share/man  \
            --docdir=/usr/share/doc/dosfstools-4.1 &&
make && make install
cd /sources/xc
rm -rf dosfstools-4.1

# gptfdisk
tar -xf gptfdisk-1.0.4.tar.gz
cd gptfdisk-1.0.4
patch -Np1 -i ../gptfdisk-1.0.4-convenience-1.patch &&
make && make install
cd /sources/xc
rm -rf gptfdisk-1.0.4

# mdadm
tar -xf mdadm-4.0.tar.xz
cd mdadm-4.0
sed 's@-Werror@@' -i Makefile
make && make install
cd /sources/xc
rm -rf mdadm-4.0

# xfsprogs
tar -xf xfsprogs-4.17.0.tar.xz
cd xfsprogs-4.17.0
make DEBUG=-DNDEBUG     \
     INSTALL_USER=root  \
     INSTALL_GROUP=root \
     LOCAL_CONFIGURE_OPTIONS="--enable-readline"
make PKG_DOC_DIR=/usr/share/doc/xfsprogs-4.17.0 install     &&
make PKG_DOC_DIR=/usr/share/doc/xfsprogs-4.17.0 install-dev &&
rm -rfv /usr/lib/libhandle.a                                &&
rm -rfv /lib/libhandle.{a,la,so}                            &&
ln -sfv ../../lib/libhandle.so.1 /usr/lib/libhandle.so      &&
sed -i "s@libdir='/lib@libdir='/usr/lib@" /usr/lib/libhandle.la
cd /sources/xc
rm -rf xfsprogs-4.17.0

# udisks
tar -xf udisks-2.8.0.tar.bz2
cd udisks-2.8.0
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-static     &&
make && make install
cd /sources/xc
rm -rf udisks-2.8.0

# gvfs
tar -xf gvfs-1.36.2.tar.xz
cd gvfs-1.36.2
mkdir build &&
cd    build &&
meson --prefix=/usr     \
      --sysconfdir=/etc \
      -Dfuse=false      \
      -Dgphoto2=false   \
      -Dafc=false       \
      -Dbluray=false    \
      -Dnfs=false       \
      -Dmtp=false       \
      -Dsmb=false       \
      -Dtmpfilesdir=no  \
      -Dlogind=false    \
      -Ddnssd=false     \
      -Dgoa=false       \
      -Dgoogle=false    \
      -Dsystemduserunitdir=no .. &&
ninja && ninja install
cd /sources/xc
rm -rf gvfs-1.36.2

# polkit-gnome
tar -xf polkit-gnome-0.105.tar.xz
cd polkit-gnome-0.105
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf polkit-gnome-0.105

# thunar-volman
tar -xf thunar-volman-0.8.1.tar.bz2
cd thunar-volman-0.8.1
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf thunar-volman-0.8.1

# Tumbler
tar -xf tumbler-0.2.1.tar.bz2
cd tumbler-0.2.1
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf tumbler-0.2.1

# xfce4-appfinder
tar -xf xfce4-appfinder-4.12.0.tar.bz2
cd xfce4-appfinder-4.12.0
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xfce4-appfinder-4.12.0

# libusb
tar -xf libusb-1.0.22.tar.bz2
cd libusb-1.0.22
sed -i "s/^PROJECT_LOGO/#&/" doc/doxygen.cfg.in &&
./configure --prefix=/usr --disable-static &&
make -j1 && make install
cd /sources/xc
rm -rf libusb-1.0.22

# UPower
tar -xf upower-0.99.7.tar.xz
cd upower-0.99.7
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --enable-deprecated  \
            --disable-static     &&
make && make install
cd /sources/xc
rm -rf upower-0.99.7

# xfce4-power-manager
tar -xf xfce4-power-manager-1.6.1.tar.bz2
cd xfce4-power-manager-1.6.1
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf xfce4-power-manager-1.6.1

# xfce4-settings
tar -xf xfce4-settings-4.12.4.tar.bz2
cd xfce4-settings-4.12.4
./configure --prefix=/usr --sysconfdir=/etc &&
make && make install
cd /sources/xc
rm -rf xfce4-settings-4.12.4

# Xfdesktop
tar -xf xfdesktop-4.12.4.tar.bz2
cd xfdesktop-4.12.4
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xfdesktop-4.12.4

# Xfwm4
tar -xf xfwm4-4.12.5.tar.bz2
cd xfwm4-4.12.5
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xfwm4-4.12.5

# desktop-file-utils
tar -xf desktop-file-utils-0.23.tar.xz
cd desktop-file-utils-0.23
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf desktop-file-utils-0.23

# xfce4-session
tar -xf xfce4-session-4.12.1.tar.bz2
cd xfce4-session-4.12.1
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --disable-legacy-sm &&
make && make install
update-desktop-database &&
update-mime-database /usr/share/mime
cat > ~/.xinitrc << "EOF"
ck-launch-session dbus-launch --exit-with-session startxfce4
EOF
cd /sources/xc
rm -rf xfce4-session-4.12.1

# PCRE2
tar -xf pcre2-10.31.tar.bz2
cd pcre2-10.31
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/pcre2-10.31 \
            --enable-unicode                    \
            --enable-jit                        \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static                    &&
make && make install
cd /sources/xc
rm -rf pcre2-10.31

# VTE
tar -xf vte-0.52.2.tar.xz
cd vte-0.52.2
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-static       \
            --enable-introspection &&
make && make install
cd /sources/xc
rm -rf vte-0.52.2

# xfce4-terminal
tar -xf xfce4-terminal-0.8.7.4.tar.bz2
cd xfce4-terminal-0.8.7.4
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xfce4-terminal-0.8.7.4

# xfce4-notifyd
tar -xf xfce4-notifyd-0.4.2.tar.bz2
cd xfce4-notifyd-0.4.2
./configure --prefix=/usr &&
make && make install
cd /sources/xc
rm -rf xfce4-notifyd-0.4.2

# Bash config
cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend

# Set the initial path
export PATH=/bin:/usr/bin

if [ $EUID -eq 0 ] ; then
        pathappend /sbin:/usr/sbin
        unset HISTFILE
fi

# Setup some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"

# Set some defaults for graphical systems
export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share/}
export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg/}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

# Setup a red prompt for root and a green one for users.
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

for script in /etc/profile.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done

unset script RED GREEN NORMAL

# End /etc/profile
EOF
install --directory --mode=0755 --owner=root --group=root /etc/profile.d

cat > /etc/profile.d/bash_completion.sh << "EOF"
# Begin /etc/profile.d/bash_completion.sh
# Import bash completion scripts

for script in /etc/bash_completion.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done
# End /etc/profile.d/bash_completion.sh
EOF
install --directory --mode=0755 --owner=root \
        --group=root /etc/bash_completion.d

cat > /etc/profile.d/dircolors.sh << "EOF"
# Setup for /bin/ls and /bin/grep to support color, the alias is in /etc/bashrc.
if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)
fi

if [ -f "$HOME/.dircolors" ] ; then
        eval $(dircolors -b $HOME/.dircolors)
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
EOF

cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

# Set some defaults before other applications add to these paths.
pathappend /usr/share/man  MANPATH
pathappend /usr/share/info INFOPATH
EOF

cat > /etc/profile.d/readline.sh << "EOF"
# Setup the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF

cat > /etc/profile.d/umask.sh << "EOF"
# By default, the umask should be set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF

cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
export LANG=en_US.UTF-8
EOF

cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides colored /bin/ls and /bin/grep commands.  Used in conjunction
# with code in /etc/profile.

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

unset RED GREEN NORMAL

# End /etc/bashrc
EOF

cat > ~/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF

cat > ~/.profile << "EOF"
# Begin ~/.profile
# Personal environment variables and startup programs.

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.profile
EOF

cat > ~/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

if [ -f "/etc/bashrc" ] ; then
  source /etc/bashrc
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.bashrc
EOF

cat > ~/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal items to perform on logout.

# End ~/.bash_logout
EOF

dircolors -p > /etc/dircolors

# Reboot
logout
swapoff -v /dev/sdb2
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys
umount -v $LFS/boot
umount -v $LFS

