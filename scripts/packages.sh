#bin/sh

LFS=/mnt/lfs
sudo mkdir -v $LFS/sources
sudo chmod -v a+wt $LFS/sources
sudo wget --input-file=wget-list/wget-list-8.3 --continue --directory-prefix=$LFS/sources
sudo cp ./wget-list/md5sum-8.3/md5sums $LFS/sources/
pushd $LFS/sources
md5sum -c md5sums
sudo rm -f md5sums
popd
sudo chown root:root $LFS/sources/*
