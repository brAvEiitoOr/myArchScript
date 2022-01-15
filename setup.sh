#!/bin/bash

arroot="/dev/sda2"
password="edwinbra"

instalar(){
    #Formato
    mkfs.ext4 $arroot

    #Montaje
    mount $arroot /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
    
    #Mirrors y pacman
    echo "Server = http://mirror.espoch.edu.ec/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
    echo "Server = http://mirror.cedia.org.ec/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

    pacman -Syy

    #instalacionBase
    pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware

    genfstab -pU /mnt >> /mnt/etc/fstab

    cp $0 /mnt/setup.sh
    arch-chroot /mnt sh setup.sh chroot

}

configurar(){
    echo "dell3442" > /etc/hostname
    sed -i 's/#\[multilib\]/\[multilib\]\nInclude \= \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf
    sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    pacman -Syyu --noconfirm refind os-prober ntfs-3g networkmanager efibootmgr gvfs gvfs-mtp xdg-user-dirs nano netctl wpa_supplicant dialog wget git zsh
    systemctl enable NetworkManager
    ln -sf /usr/share/zoneinfo/America/Guayaquil /etc/localtime

    echo "es_EC.UTF-8 UTF-8" >> /etc/locale.gen
    echo "LANG=es_EC.UTF-8" > /etc/locale.conf
    locale-gen
    hwclock -w
    echo "KEYMAP=la-latin1" > /etc/vconsole.conf

    refind-install
    echo "\"Boot with standard options\"  \"rw root=UUID=$(lsblk -no UUID $arroot) quiet splash vt.global_cursor_default=0 loglevel=3 initrd=/boot/intel-ucode.img initrd=/boot/initramfs-linux-zen.img\"" > /boot/refind_linux.conf
    echo "\"Boot to single-user mode\"  \"ro root=UUID=$(lsblk -no UUID $arroot) single\"" >> /boot/refind_linux.conf
    echo "\"Boot with minimal options\"  \"ro root=UUID=$(lsblk -no UUID $arroot)\"" >> /boot/refind_linux.conf

    sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

    echo -en "$password\n$password" | passwd
    useradd -m -s /usr/bin/zsh g users -G audio,lp,optical,storage,video,wheel,games,power,scanner edwin
    echo -en "$password\n$password" | passwd edwin

    pacman -Syy --noconfirm mesa mesa-demos xf86-video-intel intel-ucode lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader
    

    gnome
    #plasma
    #programas
}

gnome(){
    pacman -Sy --noconfirm gnome gdm xorg-xwayland
    systemctl enable gdm
}

plasma(){
    sudo pacman -Sy --noconfirm xorg-server xorg-xinit xf86-input-synaptics plasma ark dolphin dolphin-plugins ffmpegthumbs gwenview kamera kate kcalc kdeconnect kdegraphics-thumbnailers kdenetwork-filesharing kdialog kfind kio-extras kio-gdrive kipi-plugins konsole korganizer okular spectacle kde-gtk-config sddm
    systemctl enable sddm
}

programas(){
    local progr=''

    #General
    progr+=' alsa-utils firefox openssh unrar unzip vlc gparted inter-font'

    #Desarrollo
    progr+=' apache mariadb php php-apache iconv jdk11-openjdk jre11-openjdk'
    
    pacman -Syy --noconfirm $progr
    
    #Activar servicios
    systemctl enable cups
    systemctl enable sshd
    systemctl enable httpd
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    systemctl enable mariadb

    #yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm --asroot
    cd ..
    rm -rf yay
    

}

set -ex

if [ "$1" == "chroot" ]
then
    configurar
else
    instalar
fi
