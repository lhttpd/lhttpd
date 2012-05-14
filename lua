#!/bin/sh
LUA_PATH=./?.lua\;./?/init.lua\;\; exec lua $*
#\;$HOME/.luagit/lib/?.lua\;$HOME/.luagit/lib/?/init.lua LUA_CPATH=$HOME/.luagit/lib/?.so exec lua $*
