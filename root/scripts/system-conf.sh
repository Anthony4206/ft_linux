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
tmpfs          /run         tmpfs    defaults            0     0
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
cd $LFS/sources/xc
wget https://www.x.org/pub/individual/util/util-macros-1.19.2.tar.bz2
wget https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2018.4.tar.bz2
wget https://www.x.org/pub/individual/lib/libXau-1.0.8.tar.bz2
wget https://www.x.org/pub/individual/lib/libXdmcp-1.1.2.tar.bz2
wget https://xcb.freedesktop.org/dist/xcb-proto-1.13.tar.bz2
wget https://xcb.freedesktop.org/dist/libxcb-1.13.tar.bz2
wget https://sourceforge.net/projects/pcre/files/pcre/8.42/pcre-8.42.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/glib/2.56/glib-2.56.1.tar.xz
wget http://download.icu-project.org/files/icu4c/62.1/icu4c-62_1-src.tgz
wget https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.8.8.tar.bz2
wget https://ftp.gnu.org/gnu/which/which-2.21.tar.gz
wget https://downloads.sourceforge.net/libpng/libpng-1.6.35.tar.xz
wget https://sourceforge.net/projects/freetype/files/freetype2/2.9.1/freetype-2.9.1.tar.bz2
wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.0.tar.bz2
cat > lib-7.md5 << "EOF"
c5ba432dd1514d858053ffe9f4737dd8  xtrans-1.3.5.tar.bz2
6b0f83e851b3b469dd660f3a95ac3e42  libX11-1.6.6.tar.bz2
52df7c4c1f0badd9f82ab124fb32eb97  libXext-1.3.3.tar.bz2
d79d9fe2aa55eb0f69b1a4351e1368f7  libFS-1.0.7.tar.bz2
addfb1e897ca8079531669c7c7711726  libICE-1.0.9.tar.bz2
499a7773c65aba513609fe651853c5f3  libSM-1.2.2.tar.bz2
eeea9d5af3e6c143d0ea1721d27a5e49  libXScrnSaver-1.2.3.tar.bz2
8f5b5576fbabba29a05f3ca2226f74d3  libXt-1.1.5.tar.bz2
41d92ab627dfa06568076043f3e089e4  libXmu-1.1.2.tar.bz2
20f4627672edb2bd06a749f11aa97302  libXpm-3.5.12.tar.bz2
e5e06eb14a608b58746bdd1c0bd7b8e3  libXaw-1.0.13.tar.bz2
07e01e046a0215574f36a3aacb148be0  libXfixes-5.0.3.tar.bz2
f7a218dcbf6f0848599c6c36fc65c51a  libXcomposite-0.4.4.tar.bz2
802179a76bded0b658f4e9ec5e1830a4  libXrender-0.9.10.tar.bz2
58fe3514e1e7135cf364101e714d1a14  libXcursor-1.1.15.tar.bz2
0cf292de2a9fa2e9a939aefde68fd34f  libXdamage-1.1.4.tar.bz2
0920924c3a9ebc1265517bdd2f9fde50  libfontenc-1.1.3.tar.bz2
b7ca87dfafeb5205b28a1e91ac3efe85  libXfont2-2.0.3.tar.bz2
331b3a2a3a1a78b5b44cfbd43f86fcfe  libXft-2.3.2.tar.bz2
1f0f2719c020655a60aee334ddd26d67  libXi-1.7.9.tar.bz2
0d5f826a197dae74da67af4a9ef35885  libXinerama-1.1.4.tar.bz2
28e486f1d491b757173dd85ba34ee884  libXrandr-1.5.1.tar.bz2
5d6d443d1abc8e1f6fc1c57fb27729bb  libXres-1.2.0.tar.bz2
ef8c2c1d16a00bd95b9fdcef63b8a2ca  libXtst-1.2.3.tar.bz2
210b6ef30dda2256d54763136faa37b9  libXv-1.0.11.tar.bz2
4cbe1c1def7a5e1b0ed5fce8e512f4c6  libXvMC-1.0.10.tar.bz2
d7dd9b9df336b7dd4028b6b56542ff2c  libXxf86dga-1.1.4.tar.bz2
298b8fff82df17304dfdb5fe4066fe3a  libXxf86vm-1.1.4.tar.bz2
d2f1f0ec68ac3932dd7f1d9aa0a7a11c  libdmx-1.1.4.tar.bz2
8f436e151d5106a9cfaa71857a066d33  libpciaccess-0.14.tar.bz2
4a4cfeaf24dab1b991903455d6d7d404  libxkbfile-1.0.9.tar.bz2
42dda8016943dc12aff2c03a036e0937  libxshmfence-1.3.tar.bz2
EOF
mkdir lib &&
cd lib &&
grep -v '^#' ../lib-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/lib/ &&
md5sum -c ../lib-7.md5
cd $LFS/sources/xc
wget https://xcb.freedesktop.org/dist/xcb-util-0.4.0.tar.bz2
wget https://xcb.freedesktop.org/dist/xcb-util-image-0.4.0.tar.bz2
wget https://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.0.tar.bz2
wget https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.9.tar.bz2
wget https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.1.tar.bz2
wget https://xcb.freedesktop.org/dist/xcb-util-cursor-0.1.3.tar.bz2
wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tar.xz
wget https://files.pythonhosted.org/packages/source/M/MarkupSafe/MarkupSafe-1.0.tar.gz
wget https://files.pythonhosted.org/packages/source/B/Beaker/Beaker-1.10.0.tar.gz
wget https://files.pythonhosted.org/packages/source/M/Mako/Mako-1.0.4.tar.gz
wget https://dri.freedesktop.org/libdrm/libdrm-2.4.93.tar.bz2
wget https://archive.mesa3d.org/older-versions/18.x/mesa-18.1.6.tar.xz
wget https://www.x.org/pub/individual/data/xbitmaps-1.1.2.tar.bz2
cat > app-7.md5 << "EOF"
3b9b79fa0f9928161f4bad94273de7ae  iceauth-1.0.8.tar.bz2
c4a3664e08e5a47c120ff9263ee2f20c  luit-1.1.1.tar.bz2
18c429148c96c2079edda922a2b67632  mkfontdir-1.0.7.tar.bz2
987c438e79f5ddb84a9c5726a1610819  mkfontscale-1.1.3.tar.bz2
e475167a892b589da23edf8edf8c942d  sessreg-1.1.1.tar.bz2
2c47a1b8e268df73963c4eb2316b1a89  setxkbmap-1.3.1.tar.bz2
3a93d9f0859de5d8b65a68a125d48f6a  smproxy-1.0.6.tar.bz2
f0b24e4d8beb622a419e8431e1c03cd7  x11perf-1.6.0.tar.bz2
f3f76cb10f69b571c43893ea6a634aa4  xauth-1.0.10.tar.bz2
d50cf135af04436b9456a5ab7dcf7971  xbacklight-1.2.2.tar.bz2
9956d751ea3ae4538c3ebd07f70736a0  xcmsdb-1.0.5.tar.bz2
b58a87e6cd7145c70346adad551dba48  xcursorgen-1.0.6.tar.bz2
8809037bd48599af55dad81c508b6b39  xdpyinfo-1.3.2.tar.bz2
480e63cd365f03eb2515a6527d5f4ca6  xdriinfo-1.0.6.tar.bz2
249bdde90f01c0d861af52dc8fec379e  xev-1.2.2.tar.bz2
90b4305157c2b966d5180e2ee61262be  xgamma-1.0.6.tar.bz2
f5d490738b148cb7f2fe760f40f92516  xhost-1.0.7.tar.bz2
6a889412eff2e3c1c6bb19146f6fe84c  xinput-1.6.2.tar.bz2
12610df19df2af3797f2c130ee2bce97  xkbcomp-1.4.2.tar.bz2
c747faf1f78f5a5962419f8bdd066501  xkbevd-1.1.4.tar.bz2
502b14843f610af977dffc6cbf2102d5  xkbutils-1.0.4.tar.bz2
938177e4472c346cf031c1aefd8934fc  xkill-1.0.5.tar.bz2
5dcb6e6c4b28c8d7aeb45257f5a72a7d  xlsatoms-1.1.2.tar.bz2
4fa92377e0ddc137cd226a7a87b6b29a  xlsclients-1.1.4.tar.bz2
e50ffae17eeb3943079620cb78f5ce0b  xmessage-1.0.5.tar.bz2
723f02d3a5f98450554556205f0a9497  xmodmap-1.0.9.tar.bz2
eaac255076ea351fd08d76025788d9f9  xpr-1.0.5.tar.bz2
4becb3ddc4674d741487189e4ce3d0b6  xprop-1.2.3.tar.bz2
ebffac98021b8f1dc71da0c1918e9b57  xrandr-1.5.0.tar.bz2
96f9423eab4d0641c70848d665737d2e  xrdb-1.1.1.tar.bz2
c56fa4adbeed1ee5173f464a4c4a61a6  xrefresh-1.0.6.tar.bz2
70ea7bc7bacf1a124b1692605883f620  xset-1.2.4.tar.bz2
5fe769c8777a6e873ed1305e4ce2c353  xsetroot-1.1.2.tar.bz2
558360176b718dee3c39bc0648c0d10c  xvinfo-1.1.3.tar.bz2
11794a8eba6d295a192a8975287fd947  xwd-1.0.7.tar.bz2
9a505b91ae7160bbdec360968d060c83  xwininfo-1.1.4.tar.bz2
79972093bb0766fcd0223b2bd6d11932  xwud-1.0.5.tar.bz2
EOF
mkdir app &&
cd app &&
grep -v '^#' ../app-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/app/ &&
md5sum -c ../app-7.md5
cd $LFS/sources/xc
wget https://www.x.org/pub/individual/data/xcursor-themes-1.0.5.tar.bz2
cat > font-7.md5 << "EOF"
23756dab809f9ec5011bb27fb2c3c7d6  font-util-1.3.1.tar.bz2
0f2d6546d514c5cc4ecf78a60657a5c1  encodings-1.0.4.tar.bz2
6d25f64796fef34b53b439c2e9efa562  font-alias-1.0.3.tar.bz2
fcf24554c348df3c689b91596d7f9971  font-adobe-utopia-type1-1.0.4.tar.bz2
e8ca58ea0d3726b94fe9f2c17344be60  font-bh-ttf-1.0.3.tar.bz2
53ed9a42388b7ebb689bdfc374f96a22  font-bh-type1-1.0.3.tar.bz2
bfb2593d2102585f45daa960f43cb3c4  font-ibm-type1-1.0.3.tar.bz2
6306c808f7d7e7d660dfb3859f9091d2  font-misc-ethiopic-1.0.3.tar.bz2
3eeb3fb44690b477d510bbd8f86cf5aa  font-xfree86-type1-1.0.4.tar.bz2
EOF
mkdir font &&
cd font &&
grep -v '^#' ../font-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/font/ &&
md5sum -c ../font-7.md5
cd $LFS/sources/xc
wget https://www.x.org/pub/individual/data/xkeyboard-config/xkeyboard-config-2.24.tar.bz2
wget https://github.com/anholt/libepoxy/releases/download/1.5.2/libepoxy-1.5.2.tar.xz
wget https://www.cairographics.org/releases/pixman-0.34.0.tar.gz
wget https://www.x.org/pub/individual/xserver/xorg-server-1.20.1.tar.bz2
wget http://bitmath.org/code/mtdev/mtdev-1.1.5.tar.bz2
wget https://www.freedesktop.org/software/libevdev/libevdev-1.5.9.tar.xz
wget https://www.freedesktop.org/software/libinput/libinput-1.11.3.tar.xz
wget https://www.x.org/pub/individual/driver/xf86-input-libinput-0.28.0.tar.bz2
wget https://www.x.org/pub/individual/driver/xf86-video-vmware-13.3.0.tar.bz2
wget https://www.x.org/pub/individual/app/twm-1.0.10.tar.bz2
wget https://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-2.37.tar.bz2
wget http://invisible-mirror.net/archives/xterm/xterm-335.tgz
wget https://www.x.org/pub/individual/app/xclock-1.0.7.tar.bz2
wget https://www.x.org/pub/individual/app/xinit-1.4.0.tar.bz2
cat > legacy.dat << "EOF"
2a455d3c02390597feb9cefb3fe97a45 app/ bdftopcf-1.1.tar.bz2
1347c3031b74c9e91dc4dfa53b12f143 font/ font-adobe-100dpi-1.0.3.tar.bz2
6c9f26c92393c0756f3e8d614713495b font/ font-adobe-75dpi-1.0.3.tar.bz2
cb7b57d7800fd9e28ec35d85761ed278 font/ font-jis-misc-1.0.3.tar.bz2
0571bf77f8fab465a5454569d9989506 font/ font-daewoo-misc-1.0.3.tar.bz2
a2401caccbdcf5698e001784dbd43f1a font/ font-isas-misc-1.0.3.tar.bz2
EOF
mkdir legacy &&
cd legacy &&
grep -v '^#' ../legacy.dat | awk '{print $2$3}' | wget -i- -c \
     -B https://www.x.org/pub/individual/ &&
grep -v '^#' ../legacy.dat | awk '{print $1 " " $3}' > ../legacy.md5 &&
md5sum -c ../legacy.md5
cd $LFS/sources/xc
wget https://downloads.sourceforge.net/enlightenment/imlib2-1.5.1.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/libnotify/0.7/libnotify-0.7.7.tar.xz
wget https://github.com/fribidi/fribidi/releases/download/v1.0.5/fribidi-1.0.5.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/pango/1.42/pango-1.42.3.tar.xz
wget https://dbus.freedesktop.org/releases/dbus/dbus-1.12.10.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/at-spi2-core/2.28/at-spi2-core-2.28.0.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/at-spi2-atk/2.26/at-spi2-atk-2.26.2.tar.xz
wget https://wayland.freedesktop.org/releases/wayland-protocols-1.15.tar.xz
wget https://wayland.freedesktop.org/releases/wayland-1.15.0.tar.xz
wget https://xkbcommon.org/download/libxkbcommon-0.8.2.tar.xz
wget https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/adwaita-icon-theme/3.26/adwaita-icon-theme-3.26.1.tar.xz
wget https://pypi.io/packages/source/s/six/six-1.11.0.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/3.22/gtk+-3.22.30.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/atk/2.29/atk-2.29.2.tar.xz
wget https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.32.tar.xz
wget https://www.linuxfromscratch.org/patches/downloads/libxml2/libxml2-2.9.8-python3_hack-1.patch
wget http://www.libarchive.org/downloads/libarchive-3.3.2.tar.gz
wget http://xmlsoft.org/sources/libxml2-2.9.8.tar.gz
wget https://people.freedesktop.org/~hadess/shared-mime-info-1.10.tar.xz
wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.03/nasm-2.13.03.tar.xz
wget https://dist.libuv.org/dist/v1.22.0/libuv-v1.22.0.tar.gz
wget https://cmake.org/files/v3.12/cmake-3.12.1.tar.gz
wget https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-2.0.0.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.36/gdk-pixbuf-2.36.12.tar.xz
wget https://www.cairographics.org/releases/cairo-1.14.12.tar.xz
wget http://archive.xfce.org/src/xfce/libxfce4util/4.12/libxfce4util-4.12.1.tar.bz2
wget https://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.110.tar.gz
wget http://archive.xfce.org/src/xfce/xfconf/4.12/xfconf-4.12.1.tar.bz2
wget https://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz
wget http://archive.xfce.org/src/xfce/libxfce4ui/4.12/libxfce4ui-4.12.1.tar.bz2
wget https://cpan.metacpan.org/authors/id/E/ET/ETHER/URI-1.74.tar.gz
wget http://archive.xfce.org/src/xfce/exo/0.12/exo-0.12.2.tar.bz2
wget http://archive.xfce.org/src/xfce/garcon/0.6/garcon-0.6.1.tar.bz2
wget http://archive.xfce.org/src/xfce/gtk-xfce-engine/3.2/gtk-xfce-engine-3.2.0.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/libwnck/2.30/libwnck-2.30.7.tar.xz
wget http://archive.xfce.org/src/xfce/xfce4-panel/4.12/xfce4-panel-4.12.2.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/gobject-introspection/1.56/gobject-introspection-1.56.1.tar.xz
wget http://anduin.linuxfromscratch.org/BLFS/iso-codes/iso-codes-3.79.tar.xz
wget https://people.freedesktop.org/~svu/libxklavier-5.4.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/vala/0.40/vala-0.40.8.tar.xz
wget https://www.libssh2.org/download/libssh2-1.8.0.tar.gz
wget https://static.rust-lang.org/dist/rustc-1.25.0-src.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/libcroco/0.6/libcroco-0.6.12.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/librsvg/2.42/librsvg-2.42.2.tar.xz
wget http://archive.xfce.org/src/panel-plugins/xfce4-xkb-plugin/0.7/xfce4-xkb-plugin-0.7.1.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/libgudev/232/libgudev-232.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/gnome-icon-theme/3.12/gnome-icon-theme-3.12.0.tar.xz
wget http://tango.freedesktop.org/releases/icon-naming-utils-0.8.90.tar.bz2
wget http://archive.xfce.org/src/xfce/thunar/1.7/Thunar-1.7.0.tar.bz2
wget https://downloads.sourceforge.net/infozip/zip30.tar.gz
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
wget https://archive.mozilla.org/pub/nspr/releases/v4.19/src/nspr-4.19.tar.gz
wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz
wget http://ftp.gnome.org/pub/gnome/teams/releng/tarballs-needing-help/mozjs/mozjs-52.2.1gnome1.tar.gz
wget http://llvm.org/releases/6.0.1/llvm-6.0.1.src.tar.xz
wget https://www.freedesktop.org/software/polkit/releases/polkit-0.114.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/polkit-gnome/0.105/polkit-gnome-0.105.tar.xz
wget https://sqlite.org/2018/sqlite-autoconf-3240000.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/gsettings-desktop-schemas/3.28/gsettings-desktop-schemas-3.28.0.tar.xz
wget https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.xz
wget https://ftp.gnu.org/gnu/nettle/nettle-3.4.tar.gz
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/gnutls-3.5.19.tar.xz
wget https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.13.tar.gz
wget https://github.com/p11-glue/p11-kit/releases/download/0.23.13/p11-kit-0.23.13.tar.gz
wget https://github.com/djlucas/make-ca/archive/v0.8/make-ca-0.8.tar.gz
wget http://ftp.gnome.org/pub/gnome/sources/glib-networking/2.56/glib-networking-2.56.1.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/libsoup/2.62/libsoup-2.62.3.tar.xz
wget https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.32.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.3.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/libsecret/0.18/libsecret-0.18.6.tar.xz
wget http://ftp.gnome.org/pub/gnome/sources/gvfs/1.36/gvfs-1.36.2.tar.xz
wget http://archive.xfce.org/src/xfce/thunar-volman/0.8/thunar-volman-0.8.1.tar.bz2
wget http://archive.xfce.org/src/xfce/tumbler/0.2/tumbler-0.2.1.tar.bz2
wget http://archive.xfce.org/src/xfce/xfce4-appfinder/4.12/xfce4-appfinder-4.12.0.tar.bz2
wget https://github.com//libusb/libusb/releases/download/v1.0.22/libusb-1.0.22.tar.bz2
wget https://upower.freedesktop.org/releases/upower-0.99.7.tar.xz
wget http://archive.xfce.org/src/xfce/xfce4-power-manager/1.6/xfce4-power-manager-1.6.1.tar.bz2
wget http://archive.xfce.org/src/xfce/xfce4-settings/4.12/xfce4-settings-4.12.4.tar.bz2
wget http://archive.xfce.org/src/xfce/xfdesktop/4.12/xfdesktop-4.12.4.tar.bz2
wget http://archive.xfce.org/src/xfce/xfwm4/4.12/xfwm4-4.12.5.tar.bz2
wget https://www.freedesktop.org/software/desktop-file-utils/releases/desktop-file-utils-0.23.tar.xz
wget http://archive.xfce.org/src/xfce/xfce4-session/4.12/xfce4-session-4.12.1.tar.bz2
wget https://downloads.sourceforge.net/pcre/pcre2-10.31.tar.bz2
wget http://ftp.gnome.org/pub/gnome/sources/vte/0.52/vte-0.52.2.tar.xz
wget http://archive.xfce.org/src/apps/xfce4-terminal/0.8/xfce4-terminal-0.8.7.4.tar.bz2
wget http://archive.xfce.org/src/apps/xfce4-notifyd/0.4/xfce4-notifyd-0.4.2.tar.bz2
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
cd icu4c-62_1
cd source                                    &&
./configure --prefix=/usr                    &&
make && make install
cd /sources/xc
rm -rf icu4c-62_1

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

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd /sources/xc
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 

# 
tar -xf 
cd 

cd 
rm -rf 


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

