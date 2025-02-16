#/bin/sh

### PARTITIONING ###
# fdisk: manipulate disk partition table
#   - n: create a partition
#        - p: primary
#	      - Select first sector (default)
#	      - Select last sector: boot: +200M, swap: +2G, root: the rest
#        - e: extended
#   - a: toggle a bootable flag
#        - Choose the /boot partition
#   - t: change a partition type
#        - Choose the /swap partition
#        - 82: Linux swap
#   - p: print the partition table
#   - w: write table to disk and exit

echo -e "n\np\n1\n\n+200M\n\
	a\n1\n\
	n\np\n2\n\n+2G\n\
	n\np\n3\n\n\n\
	t\n2\n82\n\
	w" | sudo fdisk /dev/sdb

### FORMATTING ###
# mkfs: build a linux filesystem
sudo mkfs -vt ext4 /dev/sdb3 # Format root with ext4 (fourth extended filesystem) 
sudo mkfs -vt ext4 /dev/sdb1: format boot with ext4
# mkswap: set up a Linux swap area
sudo mkswap /dev/sdb2: format swap (an exchange partition)
sudo swapon /dev/sdb2: activate swap
### MOUNTING  ###
export LFS=/mnt/lfs
echo "export LFS=/mnt/lfs" >> /home/alevasse/.bashrc
echo "export LFS=/mnt/lfs" | sudo tee -a /root/.bashrc > /dev/null
# mount: mount a filesystem (allows to operate a disk or partition)
sudo mkdir -vp $LFS
sudo mount -vt ext4 /dev/sdb3 $LFS
sudo mkdir -vp $LFS/boot
sudo mount -Vt ext4 /dev/sdb1 $LFS/boot
echo "/dev/sdb3	/mnt/lfs	ext4	defaults	1	1" \
| sudo tee -a /etc/fstab > /dev/null 
echo "/dev/sdb1	/mnt/lfs/boot	ext4	defaults	1	1" \
| sudo tee -a /etc/fstab > /dev/null
