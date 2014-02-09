
/* @(#)demo.pl	24.1 02/23/88 */

user_help :- write('

Top Level Commands:

	go.		Begin running wafer demo.
	help.		Print this message.
	halt.		Exit from Prolog.

Commands from within the wafer system:

	describe ''word''.   Describe a word used in a question.
	describe ''id''.     Describe information known about a given wafer.
	why.		 Show reasoning behind the current question.
	summary.	 Print all of the information known about each wafer.
	done.		 Return to Prolog.

').

go :- run.
