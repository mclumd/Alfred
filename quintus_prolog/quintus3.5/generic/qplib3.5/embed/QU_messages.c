/*  SCCS   : @(#)QU_messages.c	69.1 09/07/93
    File   : QU_messages.c
    Author : Anil Nair
    Updated: 5/11/90
    Purpose: Interface to QP_error_message() from QU_messages.pl

    Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include "quintus.h"

int
QU_error_message(error_no, is_qp_error, error_string)
    int error_no;
    int * is_qp_error;
    char ** error_string;
    {
	return QP_error_message(error_no, is_qp_error, error_string);
    }
