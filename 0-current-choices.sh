#!/bin/bash
#set -e
##################################################################################################################################
# Author    : Erik Dubois
# Website   : https://www.erikdubois.be
# Youtube   : https://youtube.com/erikdubois
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

#end colors
#tput sgr0
##################################################################################################################################

set -uo pipefail  # Do not use set -e, we want to continue on error

# Trap all ERR conditions and call the handler
trap 'on_error $LINENO "$BASH_COMMAND"' ERR

on_error() {
    local lineno="$1"
    local cmd="$2"

    # Set colors
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)

    echo
    echo "${RED}⚠️ ERROR DETECTED${RESET}"
    echo "${YELLOW}✳️  Line: $lineno"
    echo "📌  Command: '$cmd'"
    echo "⏳  Waiting 10 seconds before continuing...${RESET}"
    echo

    sleep 10
}


#networkmanager issue
#nmcli connection modify Wired\ connection\ 1 ipv6.method "disabled"

# what is the present working directory
installed_dir=$(dirname $(readlink -f $(basename `pwd`)))

##################################################################################################################################

# set DEBUG to true to be able to analyze the scripts file per file
#
# works on Bash not Fish
# sudo chsh -s /usr/bin/bash erik
# logout and login to change from zsh or fish to bash

export DEBUG=false

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

run_script() {
    cd "Personal/settings/voyage-of-chadwm/$1-chadwm/" || exit 1
    sh ./1-all-in-one.sh
    exit 1
}
if [ -f /etc/lsb-release ] && grep -q "MX 23.4" /etc/lsb-release; then
    run_script "mxlinux"
fi
if grep -q "bunsenlabs" /etc/os-release; then run_script "bunsenlabs"; fi
if grep -q "FreeBSD" /etc/os-release; then run_script "freebsd"; fi
if grep -q "GhostBSD" /etc/os-release; then run_script "ghostbsd"; fi
if grep -q "Debian" /etc/os-release; then run_script "debian"; fi
if grep -q "Peppermint" /etc/os-release; then run_script "peppermint"; fi
if grep -q "Pop!" /etc/os-release; then run_script "popos"; fi
if grep -q "LMDE 6" /etc/os-release; then run_script "lmde6"; fi
if grep -q "linuxmint" /etc/os-release; then run_script "mint"; fi
if grep -q "AlmaLinux" /etc/os-release; then run_script "almalinux"; fi
if grep -q "AnduinOS" /etc/os-release; then run_script "anduin"; fi
if grep -q "ubuntu" /etc/os-release; then run_script "ubuntu"; fi
if grep -q "void" /etc/os-release; then run_script "void"; fi
if grep -q "Nobara" /etc/os-release; then run_script "nobara"; fi
if grep -q "Fedora" /etc/os-release; then run_script "fedora"; fi
if grep -q "Solus" /etc/os-release; then run_script "solus"; fi

echo "Use the script give-me-pacman.conf.sh to only get the new /etc/pacman.conf"
echo "Stop this script with CTRL + C then and run give-me-pacman.conf.sh"

echo
tput setaf 3
echo "########################################################################"
echo "Do you want to install Chadwm on your system?"
echo "Answer with Y/y or N/n"
echo "########################################################################"
tput sgr0
echo

read response

if [[ "$response" == [yY] ]]; then
    touch /tmp/install-chadwm
    for pkg in arcolinux-chadwm-pacman-hook-git arcolinux-chadwm-git; do
        if pacman -Q "$pkg" &>/dev/null; then
            sudo pacman -R --noconfirm "$pkg"
        fi
    done
fi

##################################################################################################################################

if ! grep -q -e "Manjaro" -e "Artix" /etc/os-release; then

  echo "Deleting current /etc/pacman.d/mirrorlist and replacing with"
  echo
echo "## Best Arch Linux servers worldwide from arcolinux-nemesis

Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch
Server = http://mirror.osbeck.com/archlinux/\$repo/os/\$arch
Server = http://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch"  | sudo tee /etc/pacman.d/mirrorlist
    echo
    tput setaf 2
    echo "################################################################################"
    echo "Arch Linux Servers have been written to /etc/pacman.d/mirrorlist"
    echo "Use nmirrorlist when on ArcoLinux to inspect"
    echo "################################################################################"
    tput sgr0
    echo  
fi

# order is important - dependencies

echo "################################################################################"
echo "Installing Chaotic keyring and Chaotic mirrorlist"
echo "################################################################################"
echo

for pkg in packages/*.pkg.tar.zst; do
    [ -f "$pkg" ] && sudo pacman -U --noconfirm "$pkg"
done

# personal pacman.conf for Erik Dubois
if [[ ! -f /etc/pacman.conf.nemesis ]]; then
    echo
    tput setaf 2
    echo "################################################################################"
    echo "Copying /etc/pacman.conf to /etc/pacman.conf.nemesis"
    echo "Use npacman when on ArcoLinux to inspect"
    echo "################################################################################"
    tput sgr0
    echo
    sudo cp -v /etc/pacman.conf /etc/pacman.conf.nemesis
    echo
else
    echo
    tput setaf 2
    echo "################################################################################"
    echo "Backup already exists: /etc/pacman.conf.nemesis"
    echo "Use npacman when on ArcoLinux to inspect"
    echo "################################################################################"
    tput sgr0
    echo
fi

sudo cp -v pacman.conf /etc/pacman.conf
sudo cp -v pacman.conf /etc/pacman.conf.edu

echo
tput setaf 3
echo "########################################################################"
echo "######## Removing the Arch Linux Tweak Tool"
echo "######## Removing arcolinux-keyring"
echo "######## Removing arcolinux-mirrorlist-git"
echo "########################################################################"
tput sgr0
echo

for pkg in \
  archlinux-tweak-tool-git \
  archlinux-tweak-tool-dev-git \
  arcolinux-keyring \
  arcolinux-mirrorlist-git; do
  if pacman -Q "$pkg" &>/dev/null; then
    sudo pacman -R --noconfirm "$pkg"
  fi
done

echo
tput setaf 2
echo "################################################################################"
echo "Updating the system - sudo pacman -Syyu - before 700-intervention"
echo "################################################################################"
tput sgr0
echo

sudo pacman -Syyu --noconfirm

# only for ArchBang/Manjaro/Garuda/Archcraft/...
sh 700-intervention*

echo
tput setaf 2
echo "################################################################################"
echo "Updating the system - sudo pacman -Syyu - after 700-intervention"
echo "################################################################################"
tput sgr0
echo

sudo pacman -Syyu --noconfirm

echo
tput setaf 2
echo "################################################################################"
echo "Installing much needed software"
echo "################################################################################"
tput sgr0
echo

#first get tools for whatever distro
sudo pacman -S sublime-text-4 --noconfirm --needed
sudo pacman -S ripgrep --noconfirm --needed
sudo pacman -S meld --noconfirm --needed

# if on Arco... and systemd-boot is chosen, then proceed with
if [[ -f /etc/dev-rel ]]; then

    if [[ "$(sudo bootctl is-installed 2>/dev/null)" == "yes" ]]; then
        echo
        tput setaf 3
        echo "########################################################################"
        echo "################### By default we choose systemd-boot"
        echo "################### This is to be able to change the kernel"
        echo "########################################################################"
        tput sgr0
        echo

        sudo pacman -S --noconfirm --needed pacman-hook-kernel-install
    fi
fi

echo
tput setaf 3
echo "########################################################################"
echo "################### Start of the scripts - choices what to launch or not"
echo "########################################################################"
tput sgr0
echo

sh 100-remove-software*
sh 110-install-nemesis-software*
sh 120-install-core-software*

sh 160-install-bluetooth*
sh 170-install-cups*
sh 180-ananicy*

#packages we need to build
sh 200-software-aur-repo*
#sh 300-sardi-extras*
#sh 400-surfn-extras*

# for arcoplasma
sh 500-plasma*

# installation of Chadwm
sh 600-chadwm*

echo
tput setaf 3
echo "########################################################################"
echo "################### Going to the Personal folder"
echo "########################################################################"
tput sgr0
echo

installed_dir=$(dirname $(readlink -f $(basename `pwd`)))
cd $installed_dir/Personal

sh 900-*
sh 910-*
sh 920-*



sh 970-all*

sh 970-alci*
sh 970-archman*
sh 970-archcraft*
sh 970-arco*
sh 970-ariser*
sh 970-carli*
sh 970-eos*
sh 970-garuda*
sh 970-sierra*
sh 970-biglinux*
sh 970-rebornos*
sh 970-archbang*
sh 970-manjaro*

#has to be last - they are all Arch
sh 970-arch.sh

sh 990-skel*

sh 999-last*

tput setaf 3
echo "########################################################################"
echo "End current choices"
echo "########################################################################"
tput sgr0
