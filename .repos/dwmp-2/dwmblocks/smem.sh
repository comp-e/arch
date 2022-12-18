#!/bin/sh

mem=(free -h --kilo | awk 'NR==2 {print $2}')
icon=M
printf " %s %s \\n" "$icon" "$mem"
