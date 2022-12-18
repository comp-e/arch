#!/bin/bash

read -p 'username: ' USER

mkdir -p /home/$USER/.local/share/fonts
cp IosevkaTermNerdFontComplete.ttf /home/$USER/.local/share/fonts/
cp -R ../../.config /home/$USER/                                               
cp .gtkrc-2.0 /home/$USER/
chown -R $USER:$USER /home/$USER/.local
chown -R $USER:$USER /home/$USER/.config
chown $USER:$USER /home/$USER/.gtkrc-2.0
chmod -R +x /home/$USER/.config/bspwm/
chmod -R +x /home/$USER/.config/sxhkd/
chmod -R +x /home/$USER/.config/polybar/scripts
cd ..
