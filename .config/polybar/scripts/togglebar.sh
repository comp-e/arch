#!/bin/sh

if [[ $(pgrep polybar) ]]; then
	pkill polybar
	bspc config top_padding 0
else
	polybar
fi
