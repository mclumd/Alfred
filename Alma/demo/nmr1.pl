% simple tweety test
%
% load the file tweet_help.pl:
% alma run false keyboard true alfile tweet.pl load tweet_help.pl
%
% step enough times and not(fly(tweety)) will eventually reappear.
% use query 
%

penguin(tweety).
if(penguin(X), bird(X)).
named(fif(bird(X), conclusion(fly(X))), birdsfly).
named(fif(penguin(X), conclusion(not(fly(X)))), penguinsdontfly).
prefer(penguinsdontfly, birdsfly).

% if there is a contradiction, find the parents
% very simple contra fixing procedure.

if(and(contra(X, Y, Z), eval_bound(name_to_parents(X, PX), [X])),
   parentsof(X, PX)).
if(and(contra(Y, X, Z), eval_bound(name_to_parents(X, PX), [X])),
   parentsof(X, PX)).

% find which contradictand has a preferred parent, reinstate that one

fif(and(parentsof(C1, P1),
       and(parentsof(C2, P2),
	   and(eval_bound(contains(P1, PP1), [P1, PP1]),
	       and(eval_bound(contains(P2, PP2), [P2, PP2]),
		   prefer(PP1, PP2))))),
   conclusion(reinstate(C1))).

fif(and(parentsof(C1, P1),
       and(parentsof(C2, P2),
	   and(eval_bound(contains(P1, PP1), [P1, PP1]),
	       and(eval_bound(contains(P2, PP2), [P2, PP2]),
		   prefer(PP2, PP1))))),
   conclusion(reinstate(C2))).

