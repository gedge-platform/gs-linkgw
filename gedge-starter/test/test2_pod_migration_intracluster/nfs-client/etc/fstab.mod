# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/ubuntu-vg/ubuntu-lv during curtin installation
/dev/disk/by-id/dm-uuid-LVM-08n1WpVWFML0n0Ggj6ulwgbfET23AXvtUBATCwUKEANuGBAIecj6BdhkOxr6iF82 / ext4 defaults 0 1
# /boot was on /dev/vda2 during curtin installation
/dev/disk/by-uuid/991124b8-6c73-47c8-85ce-28e310c3de9d /boot ext4 defaults 0 1
#####/swap.img	none	swap	sw	0	0
10.0.0.160:/mnt/migration	/mnt/migration	nfs	defaults,_netdev 0 0
