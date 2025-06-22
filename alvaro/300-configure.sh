#!/bin/bash
#set -e
##################################################################################################################################
# Author    : Alvaro Sainz-Pardo (based on  scripts from Erik Dubois)
##################################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################################
#tput setaf 0 = black
#tput setaf 1 = red
#tput setaf 2 = green
#tput setaf 3 = yellow
#tput setaf 4 = dark blue
#tput setaf 5 = purple
#tput setaf 6 = cyan
#tput setaf 7 = gray
#tput setaf 8 = light blue
##################################################################################################################################

if [ "$DEBUG" = true ]; then
  echo
  echo "------------------------------------------------------------"
  echo "Running $(basename $0)"
  echo "------------------------------------------------------------"
  echo
  read -n 1 -s -r -p "Debug mode is on. Press any key to continue..."
  echo
fi

##################################################################################################################################

install_if_not_installed() {
  for pkg in "$@"; do
    if pacman -Qi $pkg &> /dev/null; then
      log_ok "Package $pkg is already installed"
    else
      log_info "Installing package $pkg"
      sudo pacman -S --noconfirm --needed $pkg
    fi
  done
}

remove_if_installed() {
  for pattern in "$@"; do
    # Find all installed packages that match the pattern (exact + variants)
    matches=$(pacman -Qq | grep "^${pattern}$\|^${pattern}-")

    if [ -n "$matches" ]; then
      for pkg in $matches; do
        log_info "Removing package: $pkg"
        sudo pacman -Rs --noconfirm "$pkg"
      done
    else
      log_ok "No packages matching $pattern are installed"
    fi
  done
}

log_info() {
  echo
  tput setaf 3
  echo " [INFO]: $1"
  tput sgr0
  echo
}

log_ok() {
  echo
  tput setaf 2
  echo "   [OK]: $1"
  tput sgr0
  echo
}

log_error() {
  echo
  tput setaf 1
  echo "[ERROR]: $1"
  tput sgr0
  echo
}

log_header() {
  echo
  tput setaf 3
  echo "########################################################################"
  echo "################### Running $(basename $0)"
  echo "########################################################################"
  tput sgr0
  echo

  if [ "$DEBUG" = true ]; then
    read -n 1 -s -r -p "Debug mode is on. Press any key to continue..."
    echo
  fi
}

log_footer() {
  echo
  tput setaf 6
  echo "########################################################################"
  echo "################### $(basename $0) done"
  echo "########################################################################"
  tput sgr0
  echo
}

##################################################################################################################################

configure_virt-manager () {

# Check for backup of /etc/libvirt/libvirtd.conf file before making modifications
if [[ ! -f /etc/libvirt/libvirtd.conf.nemesis ]]; then
  sudo cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.nemesis # if backup file doesn't exist then make backup
else
  sudo cp /etc/libvirt/libvirtd.conf.nemesis /etc/libvirt/libvirtd.conf # restore backup
fi
# Uncomment lines in /etc/libvirt/libvirtd.conf to set the UNIX domain socket ownership to libvirt group and the UNIX socket permission to read and write
sudo sed -i '/^#unix_sock_group/s/^#//g' /etc/libvirt/libvirtd.conf
sudo sed -i '/^#unix_sock_rw_perms/s/^#//g' /etc/libvirt/libvirtd.conf

# Add user to libvirt group
sudo usermod -aG libvirt $(whoami)
# newgrp libvirt

# Run QEMU as non root user
# Check for backup of /etc/libvirt/qemu.conf file before making modifications
if [[ ! -f /etc/libvirt/qemu.conf.nemesis ]]; then
  sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.nemesis # if backup file doesn't exist then make backup
else
  sudo cp /etc/libvirt/qemu.conf.nemesis /etc/libvirt/qemu.conf # restore backup
fi
sudo sed -i '/^#user/s/libvirt-qemu/'$(whoami)'/g' /etc/libvirt/qemu.conf
sudo sed -i '/^#user/s/^#//g' /etc/libvirt/qemu.conf
sudo sed -i '/^#group/s/libvirt-qemu/'$(whoami)'/g' /etc/libvirt/qemu.conf
sudo sed -i '/^#group/s/^#//g' /etc/libvirt/qemu.conf

sudo systemctl enable libvirtd.socket
sudo systemctl restart libvirtd.socket

cp /etc/libvirt/libvirt.conf $XDG_CONFIG_HOME/libvirt/
# Uncomment line to set system default uri (for virsh to work)
sed -i '/^#uri_default/s/^#//g' $XDG_CONFIG_HOME/libvirt/libvirt.conf

log_info "Setting default network"
virsh net-autostart default

log_error "TODO: Enabling nested virtualization"

# Create directory in home for storage pool
[[ -d $HOME/QEMU/images ]] || mkdir $HOME/QEMU/images
# Alternative version (less compact more readable)
# if [[ ! -d $HOME/QEMU/images ]]; then
#    mkdir $HOME/QEMU/images
# fi
# mkdir -p $HOME/QEMU/images # is equivalent because mkdir -p doen't complain if directory exists

# Delete default storage pool that points to /var/lib/libvirt/images
if virsh pool-info default >/dev/null 2>&1 ; then
  log_info "Deleting default storage pool"
  virsh pool-destroy default # make storage pool inactive
  virsh pool-undefine default # Delete only pool definition, not folder
fi
# Create default storage pool pointing to $HOME/QEMU/images
log_info "Creating new default storage pool"
virsh pool-define-as default dir - - - - $HOME/QEMU/images
virsh pool-build default
virsh pool-start default
virsh pool-autostart default

# Configure virt-manager UI
dconf write /org/virt-manager/virt-manager/xmleditor-enabled true
dconf write /org/virt-manager/virt-manager/system-tray true
dconf write /org/virt-manager/virt-manager/new-vm/cpu-default "'host-passthrough'"
dconf write /org/virt-manager/virt-manager/new-vm/firmware "'uefi'"
}

function configure_nvim() {
  log_info "Configuring Neovim"
  mkdir -p $HOME/.config/stylua
  cat <<-EOF >$HOME/.config/stylua/stylua.toml
	indent_type = "Spaces"
	indent_width = 2
	quote_style = "AutoPreferSingle"
	call_parentheses = "None"
	EOF
}

function configure_xfce4_terminal () {
  log_info "Configuring XFCE4 Terminal"
  xconf-query -c xfce4-terminal -n -p /background-darkness  0.850000
  xconf-query -c xfce4-terminal -n -p /background-mode      TERMINAL_BACKGROUND_TRANSPARENT
  xconf-query -c xfce4-terminal -n -p /command-login-shell -s true
  xconf-query -c xfce4-terminal -n -p /scrolling-unlimited -s true
}

function configure_wallpapers () {
  log_info "Configuring wallpapers"
  mkdir -p $HOME/Pictures/wallpapers/
  cd $HOME/Pictures/wallpapers
  git clone https://gitlab.com/dwt1/wallpapers.git ./distrotube
  git clone https://github.com/mylinuxforwork/wallpaper.git ./mylinuxforwork
}

##################################################################################################################################

log_header

##################################################################################################################################

# configure_virt-manager
# configure_nvim
# configure_xfce4_terminal
configure_wallpapers

##################################################################################################################################

log_footer
