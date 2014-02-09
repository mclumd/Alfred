#!/bin/sh
prolog <<EOF
%   What   : @(#)qqmaster.sh	24.2 04/14/88
%   Author : Richard A. O'Keefe
%   Purpose: shell+Prolog script to make the Prolog-calling-Prolog master

compile(qqmaster).
save_program(qqmaster).
halt.
EOF
