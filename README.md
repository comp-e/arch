https://steamcommunity.com/id/bequicker

# Dotfiles

WMs: dwm, bspwm

Terminal: st

Shell: zsh

Configs: ~/.config or ~/.repos


# Installation

1. Clone the repository

2. Install required packages with pacman
`sudo pacman -S xorg xorg-server xorg-xinit`

3. Add user to video group
`sudo usermod -aG video $(whoami)`

3. Install yay

4. To install suckless software:
	* Go to the `.repos/` directory and cd into `dwm/`, `st/` or `dmenu/` directories.
	* Run `make`
	* Run `sudo make install`
	* Make `~/.xinitrc` and add the following line:
	  `exec dwm`
5. To install bspwm:
	* Go to the `.repos/bspwm` directory
	* Run `sudo bash setup.sh`
	* Run `bash install.sh`
	* Run `bash config.sh`
	* Make `~/.xinitrc` and add the following line:
	  `exec bspwm`
