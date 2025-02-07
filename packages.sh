#bin/sh

# Preparation
sudo mkdir -v $LFS/sources
sudo chmod -v a+wt $LFS/sources
sudo wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
sudo wget --input-file=wget-list-patches --continue --directory-prefix=$LFS/sources
sudo chown root:root $LFS/sources/*

# Limited Directory Layout
sudo mkdir -pv $LFS/{etc,var,lib64,tool} $LFS/usr/{bin,lib,sbin}
sudo ln -sv usr/bin $LFS/bin
sudo ln -sv usr/lib $LFS/lib
sudo ln -sv usr/sbin $LFS/sbin

# Adding the LFS user
sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
sudo passwd lfs
sudo chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools,lib64}
su - lfs

# Setting up the Environment
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j$(nproc)
EOF

sudo [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
source ~/.bash_profile
