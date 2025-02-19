#/bin/sh

LFS=/mnt/lfs

# Limited Directory Layout
#sudo mkdir -pv $LFS/tools
#sudo ln -sv $LFS/tools /

# Adding the LFS user
#sudo groupadd lfs
#sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo "lfs:123" | sudo chpasswd
#sudo chown -v lfs $LFS/tools $LFS/sources
sudo passwd -d lfs
su - lfs

# Setting up the Environment
#cat > ~/.bash_profile << "EOF"
#exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
#EOF
#
#cat > ~/.bashrc << "EOF"
#set +h
#umask 022
#LFS=/mnt/lfs
#LC_ALL=POSIX
#LFS_TGT=$(uname -m)-lfs-linux-gnu
#PATH=/usr/bin
#if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
#PATH=$LFS/tools/bin:$PATH
#CONFIG_SITE=$LFS/usr/share/config.site
#export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
#export MAKEFLAGS=-j$(nproc)
#EOF
#
#sudo [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
#source ~/.bash_profile
