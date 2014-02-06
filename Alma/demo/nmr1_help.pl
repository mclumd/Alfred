:- ensure_loaded(library(basics)).

% prolog helper file to be used with tweet.pl

contains([], _):- fail, !.
contains([Y|Z], X):- !,
    member(X, Y); contains(Z, X).

