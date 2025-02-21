#/bin/sh

LFS=/mnt/lfs

# Limited Directory Layout
sudo mkdir -pv $LFS/tools
sudo ln -sv $LFS/tools /

# Adding the LFS user
sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo "lfs:123" | sudo chpasswd
sudo chown -v lfs $LFS/tools $LFS/sources
sudo passwd -d lfs

# Setting up lfs config files
sudo cp ./lfs/bash_profile /home/lfs/.bash_profile
sudo cp ./lfs/bashrc /home/lfs/.bashrc
sudo cp ./lfs/run_lfs.sh /home/lfs/
mkdir -pv /home/lfs/scripts
sudo cp ./lfs/scripts/tmp_system.sh /home/lfs/scripts
sudo chown lfs:lfs /home/lfs/{.bash_profile,.bashrc,run_lfs.sh}
sudo chown lfs:lfs /home/lfs/scripts/tmp_system.sh
sudo chmod +x /home/lfs/run_lfs.sh /home/lfs/scripts/tmp_system.sh

su - lfs
