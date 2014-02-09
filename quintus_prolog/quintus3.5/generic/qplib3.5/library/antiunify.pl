%   Package: antiunify.pl
%   Author : Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: generalisation

:- module(anti_unify, [
	anti_unify/3,
	anti_unify/5
   ]).


sccs_id('"@(#)88/11/02 antiunify.pl	27.3"').


/*  Anti-unification is the mathematical dual of unification:  given two
    terms T1 and T2 it returns the most specific term which generalises
    them, T.  T is the most specific term which unifies with both T1 and
    T2.  A common use for this is in learning; the idea of using it that
    way comes from Gordon Plotkin.

    The code here is based on a routine called 'generalize/5' written by
    Fernando Pereira.  The name was changed because there are other ways
    of generalising things, but there is only one dual of unification.
*/

%   anti_unify(+Term1, +Term2, -Term)
%   binds Term to a most specific generalisation of Term1 and Term2.
%   When you call it, Term should be a variable.

anti_unify(Term1, Term2, Term) :-
	anti_unify(Term1, Term2, _, _, Term).


%   anti_unify(+Term1, +Term2, -Subst1, -Subst2, -Term)
%   binds Term to a most specific generalisation of Term1 and Term2,
%   and Subst1 and Subst2 to substitutions such that
%	Subst1(Term) = Term1
%	Subst2(Term) = Term2
%   Substitutions are represented as lists of Var=Term pairs, where
%   Var is a Prolog variable, and Term is the term to substitute for Var.
%   When you call it, Subst1, Subst2, and Term should be variables.

anti_unify(Term1, Term2, Phi1, Phi2, Term) :-
	anti_unify(Term1, Term2, [], [], Phi1, Phi2, Term).

anti_unify(Term1, Term2, Phi1, Phi2, Theta1, Theta2, Term) :-
	(   nonvar(Term1), nonvar(Term2),
	    functor(Term1, F, N), functor(Term2, F, N) ->
	    functor(Term, F, N),
	    anti_unify(N, Term1, Term2, Phi1, Phi2, Theta1, Theta2, Term)
	;   Term1 == Term2 ->
	    Theta1 = Phi1,
	    Theta2 = Phi2,
	    Term = Term1
	;   already_covered(Phi1, Phi2, Term1, Term2, V) ->
	    Theta1 = Phi1,
	    Theta2 = Phi2,
	    Term = V
	;   /* Not same functor, not identical, not covered by an existing V */
	    Theta1 = [V = Term1|Phi1],
	    Theta2 = [V = Term2|Phi2],
	    Term = V
	).

anti_unify(0, _, _, SS, ST, SS, ST, _) :- !.
anti_unify(N, S, T, SS0, ST0, SS, ST, U) :-
	arg(N, S, Sn),
	arg(N, T, Tn),
	arg(N, U, Un),
	anti_unify(Sn, Tn, SS0, ST0, SS1, ST1, Un),
	M is N-1,
	anti_unify(M, S, T, SS1, ST1, SS, ST, U).


already_covered([V=S0|_], [V=T0|_], S, T, V) :-
	S0 == S,
	T0 == T,
	!.
already_covered([_|Phi1], [_|Phi2], S, T, V) :-
	already_covered(Phi1, Phi2, S, T, V).



end_of_file.				% Test cases follow.

t(1, f(a),	   f(b)).		% expected: f(A)
t(2, f(a),	   f(a)).		% expected: f(a)
t(3, f(g(1,h(_))), f(g(_,h(1)))).	% expected: f(g(A,h(B)))
t(4, f(g(1,h(1))), f(g(1,k(1)))).	% expected: f(g(1,A)).
t(5, f(X+1,X+1),   f(9+Y,9+Y)).		% expected: f(A+B,A+B)
t(6, f(1+2,2+1),   f(3+4,4+3)).		% expected: f(A+B,B+A)

t(N) :-
	t(N, T1, T2),
	anti_unify(T1, T2, T),
	numbervars(T, 0, _),
	write((N->T)), nl.

f(N) :-					% what happens if nonvar(Term)?
	t(N, T1, T2),
	anti_unify(T1, T2, T1),
	write((N->T1,T2)), nl.
