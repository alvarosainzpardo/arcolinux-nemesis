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

log_header

##################################################################################################################################

# General software
install_if_not_installed git
install_if_not_installed stow
install_if_not_installed bash-completion
install_if_not_installed firefox
install_if_not_installed less
install_if_not_installed vim
install_if_not_installed tar
install_if_not_installed curl
install_if_not_installed wget
install_if_not_installed zsh
install_if_not_installed fish
install_if_not_installed nodejs
install_if_not_installed npm
install_if_not_installed nvm
install_if_not_installed man-db man-pages
install_if_not_installed noto-fonts
install_if_not_installed xorg-xrandr
install_if_not_installed nitrogen feh

# neovim
install_if_not_installed neovim
install_if_not_installed python-pynvim
install_if_not_installed luarocks
install_if_not_installed tree-sitter-cli
install_if_not_installed neovim
install_if_not_installed neovim
install_if_not_installed neovim

# virt-manager / libvirt / QEMU / KVM
install_if_not_installed qemu-desktop
install_if_not_installed virt-manager
install_if_not_installed dnsmasq
install_if_not_installed libguestfs # tools for managing virtual disk images from host (guestfish, guestmount, ...)

##################################################################################################################################

log_footer
