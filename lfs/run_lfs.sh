#/bin/sh

echo "Hello"
echo $LFS
echo $LC_ALL
echo $LFS_TGT
echo $PATH
echo $PWD
echo $MAKEFLAGS

sed -i '/run_lfs.sh/d' ~/.bashrc
rm -- $0
