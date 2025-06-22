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



##################################################################################################################################

log_header

##################################################################################################################################

log_info "Retrieving Chaotic AUR primary key"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
log_info "Installing chaotic-keyring and chaotic-mirrorlist packages" 
sudo pacman --noconfirm --needed -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman --noconfirm --needed -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

log_info "Configuring pacman.conf"
if [[ -f /etc/pacman.conf.nemesis ]]; then
  log_info "pacman.conf already configured. Skipping ..."
  exit
fi
sudo cp /etc/pacman.conf /etc/pacman.conf.nemesis
sudo bash -c 'cat <<EOF >>/etc/pacman.conf

[chaotic-aur]
SigLevel = Required DatabaseOptional
Include = /etc/pacman.d/chaotic-mirrorlist

#####################################################
# Remove these last lines once they produce errors
#####################################################

[arcolinux_repo]
SigLevel = Never
Include = /etc/pacman.d/arcolinux-mirrorlist

[arcolinux_repo_3party]
SigLevel = Never
Include = /etc/pacman.d/arcolinux-mirrorlist
EOF'

sudo bash -c 'cat <<"EOF" >/etc/pacman.d/arcolinux-mirrorlist
# United States - github
Server = https://arcolinux.github.io/$repo/$arch
EOF'

log_ok "pacman.conf successfully configured"
log_info "Updating system"
sudo pacman -Suyy
log_info "Installing Arconet packages"
sudo pacman -S --noconfirm --needed pklist.txt
log_info "Copying /etc/skel files"
cp -aT /etc/skel/. $HOME

##################################################################################################################################

log_footer

