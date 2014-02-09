#!/bin/sh
prolog <<EOF
%   What   : @(#)qqservant.sh	24.2 04/14/88
%   Author : Richard A. O'Keefe
%   Purpose: shell+Prolog script to make the Prolog-calling-Prolog servant.

compile(qqservant).
save_servant(qqservant).
halt.
EOF
