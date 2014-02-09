/*  File   : 07/16/93 @(#)socketio.h	67.1
    Author : Tom Howland
    Purpose: buffered Prolog streams connected to sockets

    Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef SocketBufferSize

#define SocketBufferSize 4096
#define InputSocketBufferSize SocketBufferSize

struct socket_input_stream
    {
	QP_stream qpinfo;
	int fd;			 /* file descriptor */
	unsigned char buffer[InputSocketBufferSize];
    };

struct socket_output_stream
    {
	QP_stream qpinfo;
	int fd;			 /* file descriptor */
	unsigned char buffer[SocketBufferSize];
    };

#define CoerceSocketInputStream(x) ((struct socket_input_stream *)(x))
#define CoerceSocketOutputStream(x) ((struct socket_output_stream *)(x))

#endif
