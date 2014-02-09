#!/bin/sh
# @(#)ld.rs6000.sh	76.1 05/12/99

RUNTIME=/home/emily/Desktop/ALFRED/quintus_prolog/quintus3.5/bin3.5/linux

exec cc "$@" -m32 -rdynamic -ldl
