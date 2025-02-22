#/bin/sh

cd $LFS/sources

# Binutils
tar -xf binutils-2.31.1.tar.xz
cd binutils-2.31.1
mkdir -v build && cd build
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make
mkdir -v /tools/lib
ln -sv lib /tools/lib64
make install
cd $LFS/sources
rm -rf binutils-2.31.1

# GCC
tar -xf gcc-8.2.0.tar.xz
cd gcc-8.2.0
tar -xf ../mpfr-4.0.1.tar.xz
mv -v mpfr-4.0.1 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

for file in gcc/config/{linux,i386/linux{,64}}.h
do
	cp -uv $file{,.orig}
	sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
	    -e 's@/usr@/tools@g' $file.orig > $file
	echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
	touch $file.orig
done

sed -e '/m64=/s/lib64/lib/' \
    -i.orig gcc/config/i386/t-linux64

mkdir -v build && cd build
../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
make && make install
cd $LFS/sources
rm -rf gcc-8.2.0

# Linux API Headers
tar -xf linux-4.18.5.tar.xz
cd linux-4.18.5
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include
cd $LFS/sources
rm -rf linux-4.18.5

# Glibc
tar -xf glibc-2.28.tar.xz
cd glibc-2.28
mkdir -v build && cd build
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include      \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes
make && make install
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools' >> /home/lfs/lfs-log.txt
cd $LFS/sources
rm -rf glibc-2.28

# Libstdc++
tar -xf gcc-8.2.0.tar.xz
cd gcc-8.2.0
mkdir -v build && cd build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0
make && make install
cd $LFS/sources
rm -rf gcc-8.2.0

# Binutils 2
tar -xf binutils-2.31.1.tar.xz
cd binutils-2.31.1
mkdir  -v build && cd build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make && make install
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin
cd $LFS/sources
rm -rf binutils-2.31.1

# GCC 2
tar -xf gcc-8.2.0.tar.xz
cd gcc-8.2.0
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
for file in gcc/config/{linux,i386/linux{,64}}.h
do
	cp -uv $file{,.orig}
	sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
	    -e 's@/usr@/tools@g' $file.orig > $file
	echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
	touch $file.orig
done
sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
tar -xf ../mpfr-4.0.1.tar.xz
mv -v mpfr-4.0.1 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc
mkdir -v build && cd build
CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
make && make install
ln -sv gcc /tools/bin/cc
echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools' >> /home/lfs/lfs-log.txt
cd $LFS/sources
rm -rf gcc-8.2.0

# Tcl
tar -xf tcl8.6.8-src.tar.gz
cd tcl8.6.8 && cd unix
./configure --prefix=/tools
make && make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh
cd $LFS/sources
rm -rf tcl8.6.8

# Expect
tar -xf expect5.45.4.tar.gz
cd expect5.45.4
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make && make SCRIPTS="" install
cd $LFS/sources
rm -rf expect5.45.4

# DejaGNU
tar -xf dejagnu-1.6.1.tar.gz
cd dejagnu-1.6.1
./configure --prefix=/tools
make install
cd $LFS/sources
rm -rf dejagnu-1.6.1

# M4
tar -xf m4-1.4.18.tar.xz
cd m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf m4-1.4.18

# Ncurses
tar -xf ncurses-6.1.tar.gz
cd ncurses-6.1
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make && make install
cd $LFS/sources
rm -rf ncurses-6.1

# Bash
tar -xf bash-4.4.18.tar.gz
cd bash-4.4.18
./configure --prefix=/tools --without-bash-malloc
make && make install
ln -sv bash /tools/bin/sh
cd $LFS/sources
rm -rf bash-4.4.18

# Bison
tar -xf bison-3.0.5.tar.xz
cd bison-3.0.5
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf bison-3.0.5

# Bzip2
tar -xf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
make && make PREFIX=/tools install
cd $LFS/sources
rm -rf bzip2-1.0.6

# Coreutils
tar -xf coreutils-8.30.tar.xz
cd coreutils-8.30
./configure --prefix=/tools --enable-install-program=hostname
make && make install
cd $LFS/sources
rm -rf coreutils-8.30

# Diffutils
tar -xf diffutils-3.6.tar.xz
cd diffutils-3.6
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf diffutils-3.6

# File
tar -xf file-5.34.tar.gz
cd file-5.34
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf file-5.34

# Findutils
tar -xf findutils-4.6.0.tar.gz
cd findutils-4.6.0
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf findutils-4.6.0

# Gawk
tar -xf gawk-4.2.1.tar.xz
cd gawk-4.2.1
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf gawk-4.2.1

# Gettext
tar -xf gettext-0.19.8.1.tar.xz
cd gettext-0.19.8.1 && cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
cd $LFS/sources
rm -rf gettext-0.19.8.1

# Grep
tar -xf grep-3.1.tar.xz
cd grep-3.1
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf grep-3.1

# Gzip
tar -xf gzip-1.9.tar.xz
cd gzip-1.9
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf gzip-1.9

# Make
tar -xf make-4.2.1.tar.bz2
cd make-4.2.1
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/tools --without-guile
make && make install
cd $LFS/sources
rm -rf make-4.2.1

# Patch
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf patch-2.7.6

# Perl
tar -xf perl-5.28.0.tar.xz
cd perl-5.28.0
sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
make
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.28.0
cp -Rv lib/* /tools/lib/perl5/5.28.0
cd $LFS/sources
rm -rf perl-5.28.0

# Sed
tar -xf sed-4.5.tar.xz
cd sed-4.5
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf sed-4.5

# Tar
tar -xf tar-1.30.tar.xz
cd tar-1.30
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf tar-1.30

# Texinfo
tar -xf texinfo-6.5.tar.xz
cd texinfo-6.5
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf texinfo-6.5

# Util-linux
tar -xf util-linux-2.32.1.tar.xz
cd util-linux-2.32.1
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            --without-ncurses              \
            PKG_CONFIG=""
make && make install
cd $LFS/sources
rm -rf util-linux-2.32.1

# Xz
tar -xf xz-5.2.4.tar.xz
cd xz-5.2.4
./configure --prefix=/tools
make && make install
cd $LFS/sources
rm -rf xz-5.2.4

# Stripping
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
rm -rf /tools/{,share}/{info,man,doc}
find /tools/{lib,libexec} -name \*.la -delete
