#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"
read -p "username: " username
echo -e "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo -e "Completed"
