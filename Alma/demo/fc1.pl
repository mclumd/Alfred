% fc1.pl
%
% Simple forward chaining test
%
%

forall(X, if(q(X), r(X))).
forall(X, q(X)).

if(r(a), alma(format('~n~nThat is good~n~n', []))).

q(a).
q(b).




