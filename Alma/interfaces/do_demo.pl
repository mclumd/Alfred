/*

interfaces/do_demo.pl

This interprets a demo file

kpurang

april 2000

to set a bunch of args:
handle_args([list of arg, val]).
by default keybaord is true and run false.

to ask a query:  yesorno(Question, Default, iftrue, iffalse)
to print a line and a newline: println(term)

*/

%:- ensure_loaded(library(prompt)).


do_demo(F):- !,
    handle_args([keyboard, true, run, false]),
    open(F, read, S),
    repeat,
      read(S, Term),
      (\+ Term = end_of_file ->
	   (demo_process(Term)); true),
      Term = end_of_file, !,
      close(S).

% here we have specific things if we want to.

demo_process(handle_args(X)):- !,
    call(handle_args(X)),
    al_files_to_load(F),
    real_laf(F).
demo_process(command(T)):- !,
    print(T), print('.'), nl,
    call(T).
demo_process(Term):- !,
    call(Term).


/*
  this will print Q on the screen and wait for the user to enter y or n
  and if y, will do T else will do F
*/
/*yesorno(Q, D, T, F):- !,
    name(Q, NQ),
    name(WQ, [63, 32 |NQ]),
    (yesno(WQ, D) ->
	 call(T);
         call(F)).
*/

println(T):- !,
    print('% '),
    print(T),
    nl.
