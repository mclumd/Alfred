/*  File   : ccallqp.h
    Author : David S. Warren
    Updated: 29 Jun 1994
    SCCS:    @(#)94/06/29 ccallqp.h	73.1
    Header : for C code using IPC interface to Prolog servant.
*/

extern	int	QP_ipc_lookup();
extern	int	QP_ipc_create_servant();
extern	int	QP_ipc_prepare();
extern	int	QP_ipc_next();
extern	int	QP_ipc_close();
extern	int	QP_ipc_shutdown_servant();
extern	QP_atom	QP_ipc_atom_from_string();
extern	void	QP_ipc_string_from_atom();

#define	QP_ipc_OK	0
#define	QP_ipc_FAIL	-1
#define	QP_ipc_ERR	-2
    /*  These are the results returned by QP_ipc_next.
	All other functions return -1 for bad arguments.
    */

#if	0

int QP_ipc_create_servant(char *HostName, char *SavedState, char *OutputFile)
	HostName is "local" or a remote machine name.
		 In System V, it is ignored, and should be "local".
	SavedState is the Prolog file to be run.
	OutputFile is "user" or the name of a file where the output is to go
	The result is -1 for failure, non-negative for success.

int QP_ipc_lookup(char *ExternalRoutineName)
	Given the name of an external routine in the servant, looks it up
	and returns its command number.  Use this number in QP_ipc_prepare()
	and QP_ipc_next().  The result is -1 for failure, non-negative for
	success.

int QP_ipc_prepare(int CommandNumber, ...)
	Sends a goal to the Prolog process.  CommandNumber came from
	QP_ipc_lookup().  The remaining arguments are the arguments
	of the goal, both input AND output arguments.  The result is
	-1 for failure, non-negative for success.

int QP_ipc_next(int command, ...)
	Receives a reply from the Prolog process.  CommandNumber came
	from QP_ipc_lookup().  The remaining arguments are the
	arguments of the goal, both output AND input arguments.  The
	result is 0 if there is a reply, -1 if the reply is 'no' (a
	simple failure), or -2 if the call was bad.  The constants
	QP_ipc_OK, QP_ipc_FAIL, QP_ipc_ERR should be used.

int QP_ipc_close()
	Finishes a query which might still have some answers.  This
	should only be used when the last call of QP_ipc_next()
	returned 0.  Returns -1 for failure, non-negative for success.

int QP_ipc_shutdown_servant()
	Shuts down the Prolog process.  Returns -1 for failure,
	non-negative for success.
	
QP_atom QP_ipc_atom_from_string(char *AtomName)
	Given a string AtomName, returns the coded representation that
	the Prolog process uses for that atom.  This code is only valid
	for that specific Prolog process.  Pass the result to +atom
	parameters of external routines.

void QP_ipc_string_from_atom(QP_atom TheAtom, char *AtomName)
	Given a coded atom, returns the name of the atom that the
	Prolog process represents by that code.  This is only valid for
	the Prolog process that TheAtom came from.  Use this to decode
	-atom parameters of external routines.
	
PROTOCOL:
	if (QP_ipc_create_servant("local", Prog, "local") < 0) {
	    abort();
	}
	if (( foo_com = QP_ipc_lookup("foo") ) < 0
	 || ( baz_com = QP_ipc_lookup("baz") ) < 0
	    ...
         || ( ugh_com = QP_ipc_lookup("ugh") ) < 0
	) {
DIE:	    QP_ipc_shutdown_servant();
	    abort();
	}
	...
	if (QP_ipc_prepare(baz_com, arg1, ..., argn) < 0) goto DIE;
	while ((r = QP_ipc_next(baz_com, arg1, ..., argn)) == QP_ipc_OK) {
	    ...
	    if (no_more_results_wanted) {
		QP_ipc_close();
		break;
	    }
	}
	if (r == QP_ipc_ERR) goto DIE;
	...
	QP_ipc_shutdown_servant();
#endif

