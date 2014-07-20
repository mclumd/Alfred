/*
File: xint.pl
By: kpurang
What: external interface- to other processes


*/

% handle_call(+X)
% X is a formula, decide how to call it.

/*
  change to do the following:
  call has 2 args,
  send both args to slave
  doing and done and error laso have 2 args.
  first arg is a formula, second dontcare.

  also check that the formula is alocal(\phi). in this case execute
  locally.

  verify that the rest of the alma can work with a 2 arg call, I doubt it
  things will have to be modified for that. see res.pl

*/

handle_call(alocal(X), _):-
	print('handle call one'),nl,
    (on_exception(_, call(X), error_call) -> 
      succeed_call(X) ; fail_call(X)).

handle_call(X, _):-
	print('handle call two'),nl,
	slave_tag(Y),print('slave tag ='),print(Y),nl, %%%
    slave_tag(false), !,
    (on_exception(_, call(X), error_call) -> 
      succeed_call(X) ; fail_call(X)).

handle_call(X, Asserts, DD):- 
	print('handle call three'),nl,
    slave_tag(Tag),
    get_new_node_name(StepName),
    assert(new_node(StepName, [doing(X, Asserts, DD)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    index_new_node(new_node(StepName, [doing(X, Asserts, DD)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    ((debug_level(1); debug_level(2); debug_level(3))-> 
	  (debug_stream(DS), print(DS, 'Asserted '), print(DS, StepName),
	   print(DS, ': '), print(DS, [doing(X, Asserts, DD)]), nl(DS)); true),
    retract(action_list(AKL)),
    assert(action_list([call(X, Asserts, DD)|AKL])).

handle_call(X, DD):- 
	print('handle call four'),nl,
    slave_tag(Tag),
    get_new_node_name(StepName),
    assert(new_node(StepName, [doing(X, DD)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    index_new_node(new_node(StepName, [doing(X, DD)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    ((debug_level(1); debug_level(2); debug_level(3))-> 
	  (debug_stream(DS), print(DS, 'Asserted '), print(DS, StepName),
	   print(DS, ': '), print(DS, [doing(X, DD)]), nl(DS)); true),
    retract(action_list(AKL)),
    assert(action_list([call(X, DD)|AKL])).

% this is used in main loop in ui.pl

answer_process(term(_, done(call(Z, _), X, SS))):- !,
    df(doing(Z, SS)),
    (verbose(true) -> print(df(doing(Z, SS))), nl; true),
    af(done(X, SS)).

answer_process(term(_, error(call(Z, ZZ), X, SS))):- !,
    (verbose(true) -> print(error(call(Z, ZZ))), nl; true),
    df(doing(Z, SS)),
    af(error(X, SS)).

/* Added - darsana on June 22, 2003 */
answer_process(term(_, failed(call(Z, ZZ), X, SS))):- !,
    (verbose(true) -> print(failed(call(Z, ZZ))), nl; true),
    df(doing(Z, SS)),
    af(failed(X, SS)).

answer_process(term(_, done(call(Z, A, _), X, SS))):- !,
    df(doing(Z, A, SS)),
    (verbose(true) -> print(df(doing(Z, A, SS))), nl; true),
    af(done(X, A, SS)).

answer_process(term(_, error(call(Z, A, ZZ), X, SS))):- !,
    (verbose(true) -> print(error(call(Z, A, ZZ))), nl; true),
    df(doing(Z, A, SS)),
    af(error(X, A, SS)).

answer_process(term(_, failed(call(Z, A, ZZ), X, SS))):- !,
    (verbose(true) -> print(failed(call(Z, A, ZZ))), nl; true),
    df(doing(Z, A, SS)),
    af(failed(X, A, SS)).

answer_process(term(_, af(Y))):- !,
    (verbose(true) -> print(af(Y)), nl; true),
    af(Y).

/*answer_process(term(_, ok())):- !,
    (verbose(true) -> print(af(ok(1))), nl; true),
    af(ok(1)).
*/

answer_process(term(_, df(Y))):- !,
    (verbose(true) -> print(df(Y)); true),
    dfu(Y).

% what for?
answer_process(term(_, failed(X, SS))):- !,
    df(doing(X, SS)),
    af(failed(X, SS)).

answer_process(term(_, quit)) :-
    print('Quitting..'),nl,
    really_disconnect,
    halt.

answer_process(_).

handle_action_list:-
    retract(action_list(AL)),
    handle_each_action(AL, [], ALZ),
    assert(action_list(ALZ)).

handle_each_action([], X, X).
handle_each_action([X|Y], Z, A):-
    have_doing(X), !,
    slave_tag(Tag),
    write(Tag, X),
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DS), print(DS, 'Sending '),
	   print(DS, X), nl(DS)); true),
    handle_each_action(Y, Z, A).
handle_each_action([X|Y], Z, A):- !,
    handle_each_action(Y, [X|Z], A).


% here A = call(X, K) and we need to check if doing(X, K) is in the db.
have_doing(A):-
    true.


%
% that stuff is for the case of no slave. to be verified.
%

error_call:-
    retract(failed_call(_)),
    assert(failed_call(true)).

succeed_call(X):-
    failed_call(false), !,
    af(X).
succeed_call(X):-
    failed_call(true), !,
    af(error(X)),
    retract(failed_call(true)),
    assert(failed_call(false)).
succeed_call2(_, Y):-
    failed_call(false), !,
    af(Y).
succeed_call2(X, Y):-
    failed_call(true), !,
    af(error(X)),
    retract(failed_call(true)),
    assert(failed_call(false)).
       
fail_call(X):-
    af(failed(X)).

