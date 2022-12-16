#!/bin/bash

echo -e "-- INSTALLING PACKAGES --"
pacman -Rsu $(comm -23 <(pacman -Qq | sort) <(sort pkglist.txt))

echo -e "\n\n-- INSTALLING YAY --"
cd .repos/yay-git/
make
make install

echo -e "\n\n-- INSTALLING YAY PACKAGES --"
yay -S --needed < pkglist.txt

echo -e "\n\n-- COPYING FILES --"
cp -r .config/ $HOME
cp -r .repos/ $HOME
cp -r .local/bin $HOME/.local

echo -e "\n\n DONE..."
