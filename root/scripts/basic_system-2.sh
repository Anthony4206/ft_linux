#/bin/sh

# Libtool
tar -xf libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make
make check TESTSUITEFLAGS=-j8 | tee -a /var/log/lfs/libtool-log.txt
make install
cd /sources
rm -rf libtool-2.4.6

# GDBM
tar -xf gdbm-1.17.tar.gz
cd gdbm-1.17
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat
make
make check | tee -a /var/log/lfs/gdbm-log.txt
make install
cd /sources
rm -rf gdbm-1.17

# Gperf
tar -xf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
make -j1 check | tee -a /var/log/lfs/gperf-log.txt
make install
cd /sources
rm -rf gperf-3.1

# Expat
tar -xf expat-2.2.6.tar.bz2
cd expat-2.2.6
sed -i 's|usr/bin/env |bin/|' run.sh.in
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.6
make
make check | tee -a /var/log/lfs/expat-log.txt
make install
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.6
cd /sources
rm -rf expat-2.2.6

# Inetutils
tar -xf inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
make check | tee -a /var/log/lfs/inetutils-log.txt
make install
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
cd /sources
rm -rf inetutils-1.9.4

# Perl
tar -xf perl-5.28.0.tar.xz
cd perl-5.28.0
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads
make
make -k test | tee -a /var/log/lfs/perl-log.txt
make install
unset BUILD_ZLIB BUILD_BZIP2
cd /sources
rm -rf perl-5.28.0

# XML Parser
tar -xf XML-Parser-2.44.tar.gz
cd XML-Parser-2.44
perl Makefile.PL
make
make test | tee -a /var/log/lfs/xml-parser-log.txt
make install
cd /sources
rm -rf XML-Parser-2.44

# Intltool
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/intltool-log.txt
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd /sources
rm -rf intltool-0.51.0

# Autoconf
tar -xf autoconf-2.69.tar.xz
cd autoconf-2.69
./configure --prefix=/usr
make
make check TESTSUITEFLAGS=-j8 | tee -a /var/log/lfs/autoconf-log.txt
make install
cd /sources
rm -rf autoconf-2.69

# Automake
tar -xf automake-1.16.1.tar.xz
cd automake-1.16.1
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
make
make -j8 check | tee -a /var/log/lfs/automake-log.txt
make install
cd /sources
rm -rf automake-1.16.1

# Xz
tar -xf xz-5.2.4.tar.xz
cd xz-5.2.4
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4
make
make check | tee -a /var/log/lfs/xz-log.txt
make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd /sources
rm -rf xz-5.2.4

# Kmod
tar -xf kmod-25.tar.xz
cd kmod-25
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make && make install
for target in depmod insmod lsmod modinfo modprobe rmmod; do
	ln -sfv ../bin/kmod /sbin/$target
done
ln -sfv kmod /bin/lsmod
cd /sources
rm -rf kmod-25

# Gettext
tar -xf gettext-0.19.8.1.tar.xz
cd gettext-0.19.8.1
sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in
sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' \
    -i gettext-tools/its/appdata.loc
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1
make
make check | tee -a /var/log/lfs/gettext-log.txt
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd /sources
rm -rf gettext-0.19.8.1

# Libelf
tar -xf elfutils-0.173.tar.bz2
cd elfutils-0.173
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/libelf-log.txt
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
cd /sources
rm -rf elfutils-0.173

# Libffi
tar -xf libffi-3.2.1.tar.gz
cd libffi-3.2.1
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in
sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make
make check | tee -a /var/log/lfs/libffi-log.txt
make install
cd /sources
rm -rf libffi-3.2.1

# OpenSSL
tar -xf openssl-1.1.0i.tar.gz
cd openssl-1.1.0i
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
make test | tee -a /var/log/lfs/openssl-log.txt
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.0i
cp -vfr doc/* /usr/share/doc/openssl-1.1.0i
cd /sources
rm -rf openssl-1.1.0i

# Python
tar -xf Python-3.7.0.tar.xz
cd Python-3.7.0
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes
make && make install
chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so
install -v -dm755 /usr/share/doc/python-3.7.0/html
tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.7.0/html \
    -xvf ../python-3.7.0-docs-html.tar.bz2
cd /sources
rm -rf Python-3.7.0

# Ninja
tar -xf ninja-1.8.2.tar.gz
cd ninja-1.8.2
python3 configure.py --bootstrap
python3 configure.py
./ninja ninja_test | tee -a /var/log/lfs/ninja-log.txt
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots \
             | tee -a /var/log/lfs/ninja-log.txt
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd /sources
rm -rf ninja-1.8.2

# Meson
tar -xf meson-0.47.1.tar.gz
cd meson-0.47.1
python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /
cd /sources
rm -rf meson-0.47.1

# Procps-ng
tar -xf procps-ng-3.3.15.tar.xz
cd procps-ng-3.3.15
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill
make
sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
rm testsuite/pgrep.test/pgrep.exp
make check | tee -a /var/log/lfs/procs-ng-log.txt
make install
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd /sources
rm -rf procps-ng-3.3.15

# E2fsprogs
tar -xf e2fsprogs-1.44.3.tar.gz
cd e2fsprogs-1.44.3
mkdir -v build && cd build
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
make LD_LIBRARY_PATH=/tools/lib check | tee -a /var/log/lfs/e2fsprogs-log.txt
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
cd /sources
rm -rf e2fsprogs-1.44.3

# Coreutils
tar -xf coreutils-8.30.tar.xz
cd coreutils-8.30
patch -Np1 -i ../coreutils-8.30-i18n-1.patch
sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
FORCE_UNSAFE_CONFIGURE=1 make
make NON_ROOT_USERNAME=nobody check-root \
     | tee -a /var/log/lfs/coreutils-log.txt
echo "dummy:x:1000:nobody" >> /etc/group
chown -Rv nobody .
su nobody -s /bin/bash \
          -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check" \
	 | tee -a /var/log/lfs/coreutils-log.txt
sed -i '/dummy/d' /etc/group
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice} /bin
cd /sources
rm -rf coreutils-8.30

# Check
tar -xf check-0.12.0.tar.gz
cd check-0.12.0
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/check-log.txt
make install
sed -i '1 s/tools/usr/' /usr/bin/checkmk
cd /sources
rm -rf check-0.12.0

# Diffutils
tar -xf diffutils-3.6.tar.xz
cd diffutils-3.6
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/diffutils-log.txt
make install
cd /sources
rm -rf diffutils-3.6

# Gawk
tar -xf gawk-4.2.1.tar.xz
cd gawk-4.2.1
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/gawk-log.txt
make install
cd /sources
rm -rf gawk-4.2.1

# Findutils
tar -xf findutils-4.6.0.tar.gz
cd findutils-4.6.0
sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make check | tee -a /var/log/lfs/findutils-log.txt
make install
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
cd /sources
rm -rf findutils-4.6.0

# Groff
tar -xf groff-1.22.3.tar.gz
cd groff-1.22.3
PAGE=A4 ./configure --prefix=/usr
make -j1 && make install
cd /sources
rm -rf groff-1.22.3

# GRUB
tar -xf grub-2.02.tar.xz
cd grub-2.02
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make && make install
cd /sources
rm -rf grub-2.02

# Less
tar -xf less-530.tar.gz
cd less-530
./configure --prefix=/usr --sysconfdir=/etc
make && make install
cd /sources
rm -rf less-530

# Gzip
tar -xf gzip-1.9.tar.xz
cd gzip-1.9
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/gzip-log.txt
make install
mv -v /usr/bin/gzip /bin
cd /sources
rm -rf gzip-1.9

# IPRoute2
tar -xf iproute2-4.18.0.tar.xz
cd iproute2-4.18.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
sed -i 's/.m_ipt.o//' tc/Makefile
make && make DOCDIR=/usr/share/doc/iproute2-4.18.0 install
cd /sources
rm -rf iproute2-4.18.0

# Kbd
tar -xf kbd-2.0.4.tar.xz
cd kbd-2.0.4
patch -Np1 -i ../kbd-2.0.4-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make
make check | tee -a /var/log/lfs/kbd-log.txt
make install
mkdir -v       /usr/share/doc/kbd-2.0.4
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4
cd /sources
rm -rf kbd-2.0.4

# Libpipeline
tar -xf libpipeline-1.5.0.tar.gz
cd libpipeline-1.5.0
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/libpipeline-log.txt
make install
cd /sources
rm -rf libpipeline-1.5.0

# Make
tar -xf make-4.2.1.tar.bz2
cd make-4.2.1
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/usr
make
make PERL5LIB=$PWD/tests/ check | tee -a /var/log/lfs/make-log.txt
make install
cd /sources
rm -rf make-4.2.1

# Patch
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make
make check | tee -a /var/log/lfs/patch-log.txt
make install
cd /sources
rm -rf patch-2.7.6

# Sysklogd
tar -xf sysklogd-1.5.1.tar.gz
cd sysklogd-1.5.1
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make && make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
cd /sources
rm -rf sysklogd-1.5.1

# Sysvinit
tar -xf sysvinit-2.90.tar.xz
cd sysvinit-2.90
patch -Np1 -i ../sysvinit-2.90-consolidated-1.patch
make -C src && make -C src install
cd /sources
rm -rf sysvinit-2.90

# Eudev
tar -xf eudev-3.2.5.tar.gz
cd eudev-3.2.5
cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-manpages       \
            --disable-static        \
            --config-cache
LIBRARY_PATH=/tools/lib make
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
make LD_LIBRARY_PATH=/tools/lib check | tee -a /var/log/lfs/eudev-log.txt
make LD_LIBRARY_PATH=/tools/lib install
tar -xvf ../udev-lfs-20171102.tar.bz2
make -f udev-lfs-20171102/Makefile.lfs install
LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update
cd /sources
rm -rf eudev-3.2.5

# Util Linux
tar -xf util-linux-2.32.1.tar.xz
cd util-linux-2.32.1
mkdir -pv /var/lib/hwclock
rm -vf /usr/include/{blkid,libmount,uuid}
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.32.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir
make
chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check" \
   | tee -a /var/log/lfs/util-linux-log.txt
make install
cd /sources
rm -rf util-linux-2.32.1

# Man DB
tar -xf man-db-2.8.4.tar.xz
cd man-db-2.8.4
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.4 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap            \
            --with-systemdtmpfilesdir=
make
make check | tee -a /var/log/lfs/man-db-log.txt
make install
cd /sources
rm -rf man-db-2.8.4

# Tar
tar -xf tar-1.30.tar.xz
cd tar-1.30
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make
make check | tee -a /var/log/lfs/tar-log.txt
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.30
cd /sources
rm -rf tar-1.30

# Texinfo
tar -xf texinfo-6.5.tar.xz
cd texinfo-6.5
sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm
./configure --prefix=/usr --disable-static
make
make check | tee -a /var/log/lfs/texinfo-log.txt
make install
make TEXMF=/usr/share/texmf install-tex
cd /sources
rm -rf texinfo-6.5

# Vim
tar -xf vim-8.1.tar.bz2
cd vim81
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
LANG=en_US.UTF-8 make -j1 test &> vim-test.log
make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
	ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
cd /sources
rm -rf vim81
