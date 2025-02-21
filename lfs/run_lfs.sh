#/bin/sh

./scripts/tmp_system.sh

sed -i '/run_lfs.sh/d' ~/.bashrc
rm -- "$0"
