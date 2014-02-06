/* SCCS   : @(#)quintus.h	76.1 02/09/98
   File   : quintus.h
   Authors: Many
   Purpose: Header file for interfacing Quintus Prolog with other code
*/

#ifndef _QUINTUS_H
#define _QUINTUS_H

#if defined(__STDC__) || defined(__cplusplus)
#ifndef QUseProto
#define QUseProto 1
#endif
#endif

#ifdef QUseProto
#define QProto(args) args
#else
#define QProto(args) ()
#endif

/*  include the following for size_t and off_t defn  */
#if WIN32 || __hpux && !defined(_HPUX_SOURCE)
#include <stdio.h>
typedef long off_t;
#else
#include <sys/types.h>
#endif

#ifdef QUseProto
/* include files for fd_set and timeval definition */
#if __hpux && !_HPUX_SOURCE
typedef int fd_set;
#elif WIN32
#include <winsock.h>
#else
#include <sys/time.h>
#endif
#if AIX
#include <sys/select.h>
#endif
#endif

#if WIN32

/* when building a DLL we need to declare external data with dllimports	*/
/* unless the symbol is actually defined in the DLL we are building...	*/
#if defined(_LIBQP)
#define _LIBQPREF	extern
#elif QP_DLL
#define _LIBQPREF	__declspec(dllimport)
#else
#define _LIBQPREF	extern
#endif

#if defined(_QPENG)
#define _QPENGREF	extern
#elif QP_DLL
#define _QPENGREF	__declspec(dllimport)
#else
#define _QPENGREF	extern
#endif

#else  /* !WIN32 */

#define _LIBQPREF	extern
#define _QPENGREF	extern

#endif  /* !WIN32 */

#define QP_MAX_ATOM 65532

/* The following #define depends on the structure of the QP
   symbol table. If you get the string associated with an atom
   using s = QP_string_from_atom(a), then instead of doing strlen(s)
   to find the length of the atom, you can use QP_atom_length(s).
   library(strings) uses this trick. You can do this even with the
   string that Prolog passes you when you pass an atom from Prolog
   to C using +string.
*/
#define QP_atomlength(s)	((unsigned short *)(s))[-1]

#define QP_INT_MIN  ((-2147483647)-1) /* [PM] 3.5 avoid overflow */
#define QP_INT_MAX  ( 2147483647)
#define QP_INT_BITS 32

typedef unsigned int QP_atom;

typedef struct qp_db_reference {
    unsigned int address;
    unsigned int count;
} QP_db_reference;

/* Signals: */

#define QP_ABORT	0	/* abort to the current breaklevel */
#define QP_STOP		1	/* stop (suspend) process */
#define QP_IGNORE	2	/* Doesn't do anything */
#define QP_EXIT		3	/* exit Prolog immediately */
#define QP_MENU		4	/* present action menu */
#define QP_ARITH	5	/* indicate arithmetic exception */
#define QP_TRACE	6	/* turn on trace mode */
#define QP_DEBUG	7	/* turn on debugging */
#define QP_REALLY_ABORT 11	/* abort to the toplevel */
#define QP_ZIP          12
#define QP_NODEBUG      13

/* Return codes for I/O, calling Prolog from other languages, etc: */

#define QP_SUCCESS	 0
#define QP_FAILURE	-1
#define QP_ERROR	-2
#define QP_INVALID	-3


/* Definitions and externs for calling Prolog from other languages: */

typedef struct qp_qid {
	int *		ptr;		/* pointer to outputs frame */
	unsigned int    key;		/* pointer to identifying key */
	struct qp_qid * prev;		/* pointer to previous qp_qid */
} *QP_qid;

typedef char * QP_pred_ref;

/* Shorthand for error returns from QP_predicate() and QP_pred(): */

#define QP_BAD_PREDREF	((QP_pred_ref) QP_ERROR)
#define QP_BAD_QID	((QP_qid) QP_ERROR)


/* Definitions for term manipulation in C: */

typedef unsigned int * QP_term_ref;

#define QP_VARIABLE	1
#define QP_INTEGER	2
#define QP_ATOM		3
#define QP_FLOAT	4
#define QP_COMPOUND	5
#define QP_DB_REFERENCE	6

#define QP_is_atom(t) 		(QP_term_type(t) == QP_ATOM)
#define QP_is_float(t) 		(QP_term_type(t) == QP_FLOAT)
#define QP_is_integer(t) 	(QP_term_type(t) == QP_INTEGER)
#define QP_is_variable(t) 	(QP_term_type(t) == QP_VARIABLE)
#define QP_is_compound(t) 	(QP_term_type(t) == QP_COMPOUND)
#define QP_is_db_reference(t) 	(QP_term_type(t) == QP_DB_REFERENCE)

/* Character types and conversion: */

_LIBQPREF        char * QP_CharType;
_LIBQPREF unsigned char QP_Xlate[];

#define QP_UNDERBAR              0
#define QP_CAPITAL_LETTER        1
#define QP_SMALL_LETTER          2
#define QP_DIGIT                 3
#define QP_AGGLUTINATING         4
#define QP_PERCENT               5
#define QP_INDIV_CHAR            6
#define QP_INDIV_ATOM            7
#define QP_DOUBLE_QUOTE          8
#define QP_SINGLE_QUOTE          9
#define QP_WHITE_SPACE          10
#define QP_ESCAPE               11
#define QP_END_OF_STREAM        12
#define QP_SMALL_LETTER2        13      /* extended character support */
#define QP_SMALL_LETTER3        14      /* extended character support */
#define QP_SMALL_LETTER4        15      /* extended character support */

#define QP_NUM_CHARTYPES        16


/* Definitions for I/O: */

#ifndef	NULL
#define	NULL	0
#endif

#define QP_EOF		-1
#define	QP_OK		0
#define QP_FULL		0
#define QP_PART		1

/* flags */
#define QP_TEXT		0x0000
#define QP_BINARY	0x0100
#define	QP_OPTION	0x0800

#define	QP_NULL_STREAM	((QP_stream *) 0)

/* flags for stream format */
#define	QP_FMT_UNKNOWN	0	/* format has not been specified yet */
#define	QP_FIX_LEN	1	/* records have fixed length */
#define	QP_VAR_LEN	2	/* records have a length prefix */
#define	QP_DELIM_CR	3	/* records are terminated by <CR> */
#define	QP_DELIM_LF	4	/* records are terminated by <LF> */
#define	QP_DELIM_CRLF	5	/* records are terminated by <CR LF> */
#define	QP_DELIM_RMS	6	/* records are terminated by several things */
#define	QP_DELIM_TTY	7	/* terminal device emulator */

/* flags for overflow type */
#define	QP_OV_ERROR	0	/* line overflow -> error signal */
#define	QP_OV_TRUNCATE	1	/* line overflow -> discard excess */
#define	QP_OV_FLUSH	2	/* line overflow -> write partial record */
/* maybe in the future
#define	QP_OV_WRAP	3	 * line overflow -> insert newline *
*/

/* flags for stream mode */
#define	QP_READ		0	/* "r" mode; input only */
#define	QP_RDWR		1	/* "r+" mode; not yet supported */
#define	QP_WRITE	2	/* "w" mode; output only */
#define	QP_WRRD		3	/* "w+" mode; not yet supported */
#define	QP_APPEND	4	/* "a" mode; output only */
#define	QP_APPRD	5	/* "a+" mode; not yet supported */

/* flags for flush type */
#define	QP_FLUSH_ERROR	0	/* error to flush output */
#define	QP_FLUSH_FLUSH	1	/* just flush current record */ 
/* maybe in the future
#define	QP_FLUSH_WRAP	2	 * wrap record and write it out *
*/

/* flags for seek type */
#define	QP_SEEK_ERROR	  0	/* no seek permission */
#define	QP_SEEK_PREVIOUS 01	/* only seek back to previous position */
#define	QP_SEEK_BYTE	 03	/* seek to arbitrary location */
#define	QP_SEEK_RECORD	 05	/* seek to arbitrary record */

/* flags for seek type QP_SEEK_BYTE */
#define	QP_BEGINNING	0	/* offset from top of file */
#define	QP_CURRENT	1	/* offset from current location */
#define	QP_END		2	/* offset from bottom of file */

/* flag for reading past end of file action */
#define	QP_PASTEOF_ERROR   0	/* error to read beyond eof */
#define	QP_PASTEOF_EOFCODE 1	/* return eof code beyond eof */
#define	QP_PASTEOF_RESET   2	/* reset end of file state beyond eof */

/* flag for end of file state */
#define	QP_NOT_EOF	0	/* eof not reached */
#define	QP_REACHED_EOF	1	/* eof reached but not consumed */
#define	QP_CONSUMED_EOF	2	/* eof reached and consumed */

/* line border and file border code */
#define	QP_NOLB		-1	/* no line border code should be returned */
#define	QP_NOFB		-2	/* no file border code should be returned */

/* character codes */
#define	QP_CR		'\r'
#define	QP_LF		'\n'

/* flag for QI_input() */
#define	QP_INPUT_GET	0
#define	QP_INPUT_PEEK	1
#define	QP_INPUT_EOL	2	/* end of line test */

/* maximum length for a tty name */
#define	QP_MAX_TTY_NAME	32

/*  A QP_cookie is a set of co-ordinates which identifies the beginning
    of a record or fragment of a record.  */

union QP_cookie
    {
	struct RFA {		/* In VMS, we use Record File Addresses */
	    int BlockNumber;	/* which 512-byte block in file? */
	    short Offset;	/* which byte in that block? */
	} vms_rfa;
	int mvs_rrn;		/* MVS uses Relative Record Number */
	int cms_recno;		/* CMS uses plain record numbers */
	off_t byteno;		/* UNIX uses absolute byte numbers */
	int user_defined[2];	/* or what have you */
    };

typedef struct 			/* The C equivalent of a */
    {				/* stream-position record */
	size_t char_count;
	size_t line_count;
	size_t line_position;
	union QP_cookie magic;
    }	QP_position;

typedef	struct
    {
	size_t		char_cnt, record_cnt, line_pos;
	char 		tty_name[QP_MAX_TTY_NAME];
	struct _QP_stream	*input_list, *output_list;
    }	QP_ttylink;

typedef struct _QP_stream
    {			/* comment with '+' might be accessed by users */
	int		n_char;		/* number of characters */
	unsigned char	*char_ptr;	/* pointer to buffer */
	unsigned char	*buffer;	/* data buffer */
	size_t		record_cnt;	/* record (line) count */
	size_t		char_cnt;	/* character (byte) count */
	size_t		xline_pos;	/* extra line position */
	size_t		line_len;	/* length of current record */
	int		seal;		/* magic for verification */
	QP_ttylink	*tty_link;	/* pointer to tty link */
	struct _QP_stream *next_stream;	/* next stream in tty link */

	char		*prompt;	/* + (maybe) prompt string */
	char		*filename;	/* + file name of the stream */
	union QP_cookie magic;		/* + address of current record */
	int		errnum;		/* + system error code */
	int		max_reclen;	/* + maximum record length */
	int		line_border;	/* + record border code */
	int		file_border;	/* + file border code */
	int		(*read)();	/* + low-level read  function */
	int		(*write)();	/* + low-level write function */
	int		(*close)();	/* + low-level close function */
	int		(*seek)();	/* + low-level seek  function */
	int		(*flush)();	/* + low-level flush function */

	unsigned char	mode;		/* + input/output mode */
	unsigned char	format;		/* + file format */
	unsigned char	overflow;	/* + overflow action */
	unsigned char	flush_type;	/* + flush action */

	unsigned char	seek_type;	/* + seek  action */
	unsigned char	trim;		/* + trim the record or not */
	unsigned char	peof_act;	/* + past end of file action */

	unsigned char	eof_state;	/* end of file state */
	unsigned char	part_line;	/* current record is partial record */

	unsigned char	unused[3];	/* pad */
    } QP_stream;


/* We use four fields in stream structure for input related macros
   char_ptr is only used to access character in the buffer;
   n_char is  >= 0 for either line_border == QP_NOLB or part_line == 1,
	except after the call of QP_skipln().
   n_char is -1 for line_border >= 0 and part_line == 0 or 
	a special case line_border == QP_NOLB after QP_skipln()
	operation.
*/
#define	QP_getchar()	QP_getc(QP_curin)
#define	QP_getc(S)	(--(S)->n_char >= 0 ? (int)(*(S)->char_ptr++)	\
			: (S)->n_char == -1 && (S)->line_border >= 0 &&	\
				(S)->part_line == 0 ? (S)->line_border	\
				: QI_input((S), QP_INPUT_GET))
#define	QP_peekchar()	QP_peekc(QP_curin)
#define	QP_peekc(S)	((S)->n_char  > 0 ? (int)(*(S)->char_ptr)	\
			:(S)->n_char == 0 && (S)->line_border >= 0 &&	\
				(S)->part_line == 0 ? (S)->line_border	\
				: QI_input((S), QP_INPUT_PEEK))
/* check part_line, since it could be at the end of partial record */
#define	QP_eoln(S)	((S)->n_char <= 0 && (((S)->n_char == 0		\
					&& (S)->part_line == 0)		\
				|| QI_input((S), QP_INPUT_EOL)))
/* test non-necessary n_char <= 0 so it's fast for most cases */
/* [PM] 3.5 QPRM 2911 return QP_ERROR on error */
#define	QP_eof(S)	((S)->n_char <= 0 &&  ((S)->n_char < 0 ||	\
			   (S)->part_line || (S)->line_border < 0) &&	\
			 (QI_input((S), QP_INPUT_EOL)==QP_ERROR ? QP_ERROR : \
				(S)->eof_state != QP_NOT_EOF))
#define	QP_pasteof(S)	((S)->eof_state == QP_CONSUMED_EOF)
#define	QP_skipline()	QP_skipln(QP_curin)
/* unfortunately, we need a loop to handle partial record case */
/* set n_char to -1 so we don't need to update the buffer,
	character count is handled specially */
#define	QP_skipln(S)	if ((S)->n_char == -1)				\
			    (void) QI_input((S), QP_INPUT_EOL);		\
			while ((S)->part_line)				\
			    (void) QI_input((S), QP_INPUT_EOL);		\
			(S)->n_char = -1

#define	QP_newline()	QP_newln(QP_curout)
#define	QP_newln(S)	QI_output((S), -1)
#define	QP_putchar(C)	QP_putc(C, QP_curout)
/*  QP_fputc() version,  won't work such as (C) is *<char pointer>++ */
#define	QP_fastputc(C,S) ((C) == (S)->line_border ? QI_output((S), -1)	\
			: --(S)->n_char >= 0				\
				? (int)(*(S)->char_ptr++ = (C))		\
				: ((S)->n_char++, QI_output((S), (C))))
#define	QP_putc(C,S)	(--(S)->n_char >= 0 ?				\
			 ((*((S)->char_ptr)=(C), C == (S)->line_border) \
			  ? ((S)->n_char++, QI_output((S), -1))\
			  : (int) *(S)->char_ptr++)			\
			: ((S)->n_char++, QI_output((S), (C))))
/* n_char == -1 && line_border < 0 is a special case */
#define	QP_char_count(S) ((S)->eof_state != QP_NOT_EOF ? (S)->char_cnt	\
			: (S)->char_cnt+(S)->line_len-((S)->n_char==-1	\
			  && (S)->line_border < 0 ? 0 : (S)->n_char))
/* n_char == -1 for an input stream just consumed line_border code */
#define	QP_line_count(S) ((S)->record_cnt == 0 ? 1 : (S)->n_char == -1	\
				? (S)->record_cnt+1 : (S)->record_cnt)
/* n_char<0 for an input stream just consumed line_border code */
#define	QP_line_position(S) ((S)->eof_state != QP_NOT_EOF ||		\
			(S)->n_char < 0 ? 0		 		\
			: (S)->xline_pos+(S)->line_len-(S)->n_char)

_QPENGREF QP_stream	*QP_curin, *QP_curout;
_QPENGREF QP_stream	*QP_stdin, *QP_stdout, *QP_stderr;

#if WIN32 || OS2
/*
    On Win32 and OS2 the following macros fix pathnames to look like
    DOS paths or UNIX paths; on UNIX these do nothing
*/
#define QP_REALPATH(path)	QP_dos_path(path)
#define QP_UNIXPATH(path)	QP_unix_path(path)
#else
/* [PM] 3.5 the return value from these are used so cannot cast to void. */
#define QP_REALPATH(path)	(path)
#define QP_UNIXPATH(path)	(path)  /*** See QP#1920 ***/
#endif

/* QP_get_qpath() : */
#define QP_ADDONS		1
#define QP_RUNTIME_PATH         2
#define QP_QUINTUS_HOME         3
#define QP_HOST_DIR		4
#define QP_BANNER_MSG		5

/* input services */

#define	QP_NO_TIMEOUT	0xffffffff

/* Error numbers: */

#define	QP_START_ECODE	  1000
#define	QP_E_EXHAUSTED	  1001	/* read past end of file */
#define	QP_E_STATE	  1002	/* stream in wrong state */
#define	QP_E_CONFUSED	  1003	/* stream is inconsistent */
#define	QP_E_CANT_READ	  1004	/* stream->read returned error code */
#define	QP_E_CANT_WRITE	  1005	/* stream->write returned error code */
#define	QP_E_CANT_FLUSH	  1006	/* stream->flush returned error code */
#define	QP_E_CANT_SEEK	  1007	/* stream->seek returned error code */
#define	QP_E_CANT_CLOSE	  1008	/* stream->close returned error code */
#define	QP_E_NONBLOCK	  1009	/* I/O failed due to asynchronous mode */
#define	QP_E_INVAL	  1010	/* invaid argument */
#define	QP_E_PERMISSION	  1011	/* no permission, such as read from output */
#define	QP_E_OVERFLOW	  1012	/* output record overflowed */
#define	QP_E_BAD_STREAM	  1013	/* stream is not registered */
#define	QP_E_BUFFERED	  1014	/* can't do operation with non-empty buffer */
		/* error code for open function */
#define	QP_E_FILENAME	  1015	/* file name is not specified */
#define QP_E_DIRECTORY	  1016	/* file is a directory */
#define	QP_E_BAD_MODE	  1017	/* open mode not supported */
#define	QP_E_BAD_FORMAT	  1018	/* bad format */
#define	QP_E_SEEK_TYPE	  1019	/* seeking type is not supported */
#define	QP_E_FLUSH_TYPE	  1020	/* flush type is not supported */
#define	QP_E_OV_TYPE	  1021	/* overflow type is not supported */
#define	QP_E_REC_SIZE	  1022	/* bad record size */
#define	QP_E_SYS_OPTION	  1023	/* bad system option, used in QU_open() */
#define	QP_E_NOMEM	  1024	/* not enough memory */
#define	QP_E_MFILE	  1025	/* stream table if full */
#define QP_E_CMDSS	  1026	/* missing saved state argument */
#define QP_E_CMDCS	  1027	/* missing command string argument */
#define QP_E_CMDTF	  1028	/* missing trace flag argument */
#define QP_E_CMDTMO	  1029	/* more than one option in the command line */
#define QP_E_CMDOI	  1030	/* incompatable options in command line */
#define QP_E_CMDUO	  1031	/* unknown Prolog option */
#define QP_E_CMDNSPN	  1032	/* not enough space for path names */
#define QP_E_CMDNSPC	  1033	/* not enough space for the prolog command */
#define QP_E_CMDPF	  1034	/* putenv failed */
#define QP_E_CMDTMEA	  1035	/* too many emacs arguments */
#define QP_I_CMDELOAD	  1036	/* loading emacs with ... */
#define QP_E_CMDEE	  1037	/* Couldn't start emacs. */
#define QP_E_CMDNQSP	  1038	/* something wasn't qsetpath'd */
#define QP_E_NO_TOP_LEVEL 1039	/* no top level */
#define QP_I_INTERRUPT_PROMPT 1040 /* see QU_messages.c */
#define QP_I_INTERRUPT_HELP_1 1041
#define QP_I_INTERRUPT_HELP_2 1042
#define QP_I_INTERRUPT_HELP_3 1043
#define	QP_END_ECODE	  1044

#define	IS_QP_ECODE(ecode)	((ecode)>=QP_START_ECODE && (ecode)<=QP_END_ECODE)
#define	QP_ECODE_INDEX(ecode)	(ecode - QP_START_ECODE)

#define	QP_NO_ERROR		0
#define	QP_QP_ERROR		1
#define	QP_HOST_ERROR		2
#define	QP_UNKNOWN_ERROR	3

_QPENGREF int	QP_errno;
_LIBQPREF char  *QU_errlist[];

_QPENGREF int	QP_argc;
_QPENGREF char	**QP_argv;

#ifdef __cplusplus
extern "C" {
#endif

/* functions for atom <=> string conversion */

extern QP_atom	QP_atom_from_string QProto((char *));
extern char *	QP_string_from_atom QProto((QP_atom));
extern int	QP_atom_from_padded_string QProto((
			QP_atom	*atom, char *string, int *length
		));
extern int	QP_padded_string_from_atom QProto((
			QP_atom	*atom, char *string, int *length
		));

/* functions for Prolog memory allocation */

extern void *	QP_malloc QProto((int));
extern void	QP_free QProto((void *));

/* functions for Atom garbage collection */

extern int	QP_register_atom QProto((QP_atom));
extern int	QP_unregister_atom QProto((QP_atom));

/* functions for asynchronous event handling */

extern int	QP_action QProto((int event));

/* functions for calling Prolog from other languages */

extern QP_pred_ref QP_predicate QProto((
			char *	predicate_name,
			int	arity,
			char *	module_name
		));
extern QP_pred_ref QP_pred QProto((
			QP_atom	predicate_name,
			int	arity,
			QP_atom	module_name
		));

extern int	QP_query QProto((QP_pred_ref, ...));
extern QP_qid	QP_open_query QProto((QP_pred_ref, ...));
extern int	QP_next_solution QProto((QP_qid));
extern int	QP_cut_query QProto((QP_qid));
extern int	QP_close_query QProto((QP_qid));
extern int	QP_exception_term QProto((QP_term_ref));

/* functions for redefining main() or the Prolog top level */

extern int	QP_initialize QProto((int argc, char **argv));
extern int	QP_toplevel QProto((void));
extern int	QP_trimcore QProto((void));

/* functions for manipulating Prolog terms in C */

extern QP_term_ref QP_new_term_ref QProto((void));

extern int	QP_term_type QProto((QP_term_ref));
extern int	QP_is_atomic QProto((QP_term_ref));
extern int	QP_is_number QProto((QP_term_ref));
extern int	QP_is_list QProto((QP_term_ref));

extern int	QP_get_atom QProto((QP_term_ref, QP_atom *));
extern int	QP_get_list QProto((
			QP_term_ref, QP_term_ref head, QP_term_ref tail
		));
extern int	QP_get_nil QProto((QP_term_ref));
extern int	QP_get_head QProto((QP_term_ref, QP_term_ref head));
extern int	QP_get_tail QProto((QP_term_ref, QP_term_ref tail));
extern int	QP_get_functor QProto((
			QP_term_ref, QP_atom *name, int *arity
		));
extern int	QP_get_arg QProto((
			int argnum, QP_term_ref, QP_term_ref arg
		));
extern int	QP_get_float QProto((QP_term_ref, double *));
extern int	QP_get_integer QProto((QP_term_ref, long int *));
extern int	QP_get_db_reference QProto((QP_term_ref, QP_db_reference *));

extern int	QP_unify QProto((QP_term_ref, QP_term_ref));
extern int	QP_compare QProto((QP_term_ref, QP_term_ref));

extern void	QP_put_atom QProto((QP_term_ref, QP_atom));
extern void	QP_put_integer QProto((QP_term_ref, long int));
extern void	QP_put_variable	QProto((QP_term_ref));
extern void	QP_put_float QProto((QP_term_ref, double));
extern void	QP_put_functor QProto((
			QP_term_ref, QP_atom name, int arity
		));
extern void	QP_put_list QProto((QP_term_ref));
extern void	QP_put_nil QProto((QP_term_ref));
extern void	QP_put_term QProto((QP_term_ref, QP_term_ref));
extern void	QP_put_db_reference QProto((QP_term_ref, QP_db_reference));

extern void	QP_cons_functor QProto((
			QP_term_ref, QP_atom name, int arity, ...
		));
extern void	QP_cons_list QProto((
			QP_term_ref, QP_term_ref head, QP_term_ref tail
		));

/*
    Function used for I/O on Prolog streams and for embedding the low-level
    Prolog I/O layer.
*/

extern void	QU_stream_param QProto((
			char *		filename,
			int		mode,
			unsigned char	format,
			QP_stream *	stream_option
		));

extern int	QU_initio QProto((
			QP_stream **	user_input,
			QP_stream **	user_output,
			QP_stream **	user_error,
			int		act_astty,
			int *		error_number
		));

extern QP_stream *QU_open QProto((
			QP_stream *	stream_option,
			char *		system_option,
			int *		error_number
		));

extern QP_stream *QU_fdopen QProto((
			QP_stream *	stream_option,
			char *		system_option,
			int *		error_number,
			int		fd
		));

extern QP_stream *QP_fopen QProto((
			unsigned char *	filename,
			char *		mode
		));

extern QP_stream *QP_fdopen QProto((int fd, char *mode));

extern void	QP_prepare_stream QProto((QP_stream *, unsigned char *buf));
extern int	QP_register_stream QProto((QP_stream *));

extern int	QP_close QProto((QP_stream *));
extern int	QP_fclose QProto((QP_stream *));
extern int	QP_fgetc QProto((QP_stream *));
extern int	QP_sgetc QProto((QP_stream *));
extern int	QP_fputc QProto((int ch, QP_stream *));
extern int	QP_sputc QProto((int ch, QP_stream *));
extern int	QP_fpeekc QProto((QP_stream *));
extern int	QP_tab QProto((QP_stream *, int count, int ch));
extern int	QP_tabto QProto((QP_stream *, size_t linepos, int ch));
extern int	QP_fskipln QProto((QP_stream *));
extern int	QP_fnewln QProto((QP_stream *));
extern int	QP_printf QProto((char *format, ...));
extern int	QP_fprintf QProto((QP_stream *, char *format, ...));
extern int	QP_sprintf QProto((QP_stream *, char *format, ...));
extern char *	QP_fgets QProto((char *buf, int size, QP_stream *));
extern int	QP_puts QProto((unsigned char *string));
extern int	QP_fputs QProto((unsigned char *string, QP_stream *));
extern int	QP_sputs QProto((unsigned char *string, QP_stream *));
extern size_t	QP_fread QProto((char *buf, size_t size, size_t nitems, QP_stream *));
extern size_t	QP_fwrite QProto((char *buf, size_t size, size_t nitems, QP_stream *));
extern int	QP_flush QProto((QP_stream *));

extern QP_stream *QP_setinput QProto((QP_stream *));
extern QP_stream *QP_setoutput QProto((QP_stream *));

extern void	QP_clearerr QProto((QP_stream *));
extern int	QP_getpos QProto((QP_stream *, QP_position *));
extern int	QP_setpos QProto((QP_stream *, QP_position *));
extern int	QP_seek QProto((QP_stream *, long int offset, int from_where));
extern int	QP_rewind QProto((QP_stream *));
extern int	QP_add_tty QProto((QP_stream *, char *tty_id));

extern int	QP_make_stream QProto((
			char *		handle,
			int		(*getp)(),
			int		(*putp)(),
			int		(*flushp)(),
			int		(*eofp)(),
			int		(*clearp)(),
			int		(*closep)(),
			QP_stream **	stream
		));

/* functions for getting Quintus paths from C */

extern char *	QP_get_qpath QProto((int which_path));

/* functions for input services */

extern int	QP_add_input QProto((
			int	id,
			void	(*function)(),
			char	*call_data,
			void	(*flush_function)(),
			char	*flush_data
		));
extern int	QP_add_output QProto((
			int	id,
			void	(*function)(),
			char	*call_data,
			void	(*flush_function)(),
			char	*flush_data
		));
extern int	QP_add_exception QProto((
			int	id,
			void	(*function)(),
			char	*call_data,
			void	(*flush_function)(),
			char	*flush_data
		));
extern int	QP_add_timer QProto((
			int	msecs,
			void	(*function)(),
			char	*call_data
		));
extern int	QP_add_absolute_timer QProto((
			struct timeval *timeout,
			void	(*function)(),
			char	*call_data
		));

extern int	QP_remove_input QProto((int id));
extern int	QP_remove_output QProto((int id));
extern int	QP_remove_exception QProto((int id));
extern int	QP_remove_timer QProto((int id));

extern int	QP_select QProto((
			int	width,
			fd_set *read_fds,
			fd_set *write_fds,
			fd_set *except_fds,
			struct timeval *timeout
		));

extern int	QP_wait_input QProto((int fd, int relative_time));

/* functions for getting QP error information */

extern int	QP_error_message QProto((
			int	qerrno,
			int *	is_qp_errno,
			char ** error_string
		));

extern void	QP_perror QProto((char *error_string));

#if WIN32
extern	int	QP_pc_host QProto((void));
extern	char *	QP_dos_path QProto((const char *));
extern	void 	QP_unix_path QProto((char *));
#endif

#ifdef __cplusplus
}
#endif

#endif /* _QUINTUS_H */
