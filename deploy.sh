#!/bin/bash
set -e
export PART2 ROOT_PASSWORD REGION_CITY HOST USERNAME KEYMAP

# Timezone
ln -sf /usr/share/zoneinfo/"$REGION_CITY" /etc/localtime
hwclock --systohc

# Localization
echo -e "CHARSET=UTF-8
LANG=en_GB.UTF-8
LC_COLLATE=C
XKB_DEFAULT_LAYOUT=$KEYMAP" >/etc/environment

echo "en_GB.UTF-8 UTF-8" >/etc/locale.gen
locale-gen

echo -e "FONT_MAP=8859-2
KEYMAP=$KEYMAP" >/etc/vconsole.conf

# Hostname
echo "$HOST" >/etc/hostname
mkdir -p /etc/conf.d
echo -e "hostname=$HOST" >/etc/conf.d/hostname

# User
useradd -m -G users,audio,video,input -s /usr/bin/bash $USERNAME
echo "$USERNAME:$ROOT_PASSWORD" | chpasswd
echo "root:$ROOT_PASSWORD" | chpasswd

# Pacman mirrors
echo -e '# Default mirrors
Server = https://mirrors.rit.edu/artixlinux/$repo/os/$arch
Server = https://mirrors.dotsrc.org/artix-linux/repos/$repo/os/$arch' >/etc/pacman.d/mirrorlist

echo -e "[universe]
Server = https://universe.artixlinux.org/\$arch
" >>/etc/pacman.conf
# Enable keyring
pacman -Sy --needed --noconfirm artix-keyring artix-archlinux-support

# Install base packages
pacman -Sy --needed --noconfirm --disable-download-timeout alsa-utils backlight-runit bluez-runit dbus-broker doas egl-gbm egl-x11 fwupd gtk-engines gtk-engine-murrine haveged-runit iw jitterentropy networkmanager networkmanager-runit mesa openbox pipewire pipewire-alsa pipewire-pulse rsync tmux tor-runit torsocks unzip usbutils vim wget xdg-utils xdg-user-dirs xorg-xinit xterm
# Enable services
ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/backlight /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/haveged /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/tor /etc/runit/runsvdir/default/

# mkinitcpio
sed -i -e 's/^HOOKS.*$/HOOKS=(base udev autodetect modconf keyboard block encrypt filesystems)/g' /etc/mkinitcpio.conf
mkinitcpio -P

echo -e "SocksPort 127.0.0.1:9050 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr
Sandbox 1
HardwareAccel 0
UseEntryGuards 1
EnforceDistinctSubnets 1
StrictNodes 0" >>/etc/tor/torrc

echo -e "CPU_LIMIT=0
GPU_USE_SYNC_OBJECTS=1
SHARED_MEMORY=1
MALLOC_CONF=background_thread:true
MALLOC_CHECK=0
MALLOC_TRACE=0
LD_DEBUG_OUTPUT=0
LD_BIND_NOW=1
LLVM_DEBUG=0
PP_DEBUG=0
MESA_DEBUG=0
LIBGL_DEBUG=0
LIBGL_NO_DRAWARRAYS=1
LIBGL_THROTTLE_REFRESH=1
LIBC_FORCE_NOCHECK=1
HISTCONTROL=ignoreboth:eraseboth
HISTSIZE=5
LESSHISTFILE=-
LESSHISTSIZE=0
LESSSECURE=1
PAGER=less" >>/etc/environment

mkdir -p /etc/modprobe.d
echo -e "blacklist pcspkr
blacklist snd_pcsp
blacklist lpc_ich
blacklist gpio-ich
blacklist iTCO_wdt
blacklist iTCO_vendor_support
blacklist joydev
blacklist mousedev
blacklist mac_hid
blacklist uvcvideo
blacklist parport_pc
blacklist parport
blacklist lp
blacklist ppdev
blacklist sunrpc
blacklist floppy
blacklist arkfb
blacklist aty128fb
blacklist atyfb
blacklist radeonfb
blacklist cirrusfb
blacklist cyber2000fb
blacklist kyrofb
blacklist matroxfb_base
blacklist mb862xxfb
blacklist neofb
blacklist pm2fb
blacklist pm3fb
blacklist s3fb
blacklist savagefb
blacklist sisfb
blacklist tdfxfb
blacklist tridentfb
blacklist vt8623fb
blacklist sp5100-tco
blacklist sp5100_tco
blacklist pcmcia
blacklist yenta_socket
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
blacklist n-hdlc
blacklist ax25
blacklist netrom
blacklist x25
blacklist rose
blacklist decnet
blacklist econet
blacklist af_802154
blacklist ipx
blacklist appletalk
blacklist psnap
blacklist p8022
blacklist p8023
blacklist llc
blacklist i2400m
blacklist i2400m_usb
blacklist wimax
blacklist parport
blacklist parport_pc
blacklist cramfs
blacklist freevxfs
blacklist jffs2
blacklist hfs
blacklist wl
blacklist ssb
blacklist b43
blacklist b43legacy
blacklist bcma
blacklist bcm43xx
blacklist brcm80211
blacklist brcmfmac
blacklist brcmsmac" >/etc/modprobe.d/nomisc.conf

# Connection
echo -e "vm.min_free_kbytes=65536
vm.mmap_rnd_bits=32
vm.mmap_rnd_compat_bits=16
fs.file-max=1048576
fs.nr_open=1048576
fs.aio-max-nr=524288
fs.protected_hardlinks=1
fs.protected_symlinks=1
fs.protected_fifos=2
fs.protected_regular=2
fs.suid_dumpable=0
abi.vsyscall32=0
kernel.split_lock_mitigate=0
kernel.unprivileged_bpf_disabled=1
kernel.yama.ptrace_scope=1
kernel.dmesg_restrict=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.arp_evict_nocarrier=1
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.log_martians=0
net.ipv4.tcp_notsent_lowat=131072
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.udp_early_demux=1
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.route.flush=1
net.ipv4.ipfrag_time=0
net.ipv4.ipfrag_secret_interval=0
net.core.default_qdisc=cake
net.core.busy_poll=50
net.core.busy_read=50
net.core.high_order_alloc_disable=0
net.core.warnings=0
net.core.tstamp_allow_data=1
net.core.enable_tcp_offloading=1
net.core.netdev_tstamp_prequeue=1
net.core.netdev_max_backlog=65535
net.core.somaxconn=65535
net.core.optmem_max=65535
net.core.rmem_max=6291456
net.core.wmem_max=6291456" >/lib/sysctl.d/99-system.conf
sysctl -w vm.drop_caches=3 || true

wget -qO /etc/hosts https://github.com/StevenBlack/hosts/raw/refs/heads/master/alternates/fakenews-gambling-porn-social/hosts && sed -i -e 's/#.*0.0.0.0/0.0.0.0/g' /etc/hosts

mkdir -p /etc/NetworkManager/conf.d
cat >/etc/NetworkManager/conf.d/00-mac-randomization.conf <<'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

chattr -i /etc/resolv.conf 2>/dev/null || true
cat > /etc/resolv.conf <<EOF
nameserver 9.9.9.9
nameserver 149.112.112.112
EOF
chattr +i /etc/resolv.conf
# Priv
echo -e "permit nopass :$USERNAME" >/etc/doas.conf
sed -i -e "s|\${GETTY_ARGS}|--autologin $USERNAME|g" /etc/runit/sv/agetty-tty1/run

# GRUB
GRUB_PASS=$(echo -e "$ROOT_PASSWORD\n$ROOT_PASSWORD" | grub-mkpasswd-pbkdf2 | grep -oE '[^ ]+$')
echo -e "set superusers=$USERNAME
password_pbkdf2 $USERNAME $GRUB_PASS" >>/etc/grub.d/40_custom

sed -i -e "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=$PART2:root:allow-discards root=/dev/mapper/root quiet loglevel=3 slab_nomerge pti=on page_poison=1 init_on_alloc=1 init_on_free=1\"|g" /etc/default/grub
if ! grep -q "^GRUB_ENABLE_CRYPTODISK=y" /etc/default/grub 2>/dev/null; then
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
fi
sed -i -e 's/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i -e 's/GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=0/' /etc/default/grub
sed -i -e 's/GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
sed -i -e 's/GRUB_DISABLE_RECOVERY=.*/GRUB_DISABLE_RECOVERY=true/' /etc/default/grub
sed -i -e 's/GRUB_DISABLE_SUBMENU=.*/GRUB_DISABLE_SUBMENU=true/' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg
